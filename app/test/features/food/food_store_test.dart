import 'package:app/core/db/app_database.dart';
import 'package:app/features/food/data/food_store.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

FoodItem food(String id, {String name = 'Milk', DateTime? openedOn}) =>
    FoodItem(
      id: id,
      name: name,
      amount: '1 l',
      category: FoodCategory.dairy,
      productCategory: 'Dairy & Eggs',
      productType: 'Milk (plain or flavored)',
      storage: StorageLocation.fridge,
      bestBefore: DateTime(2026, 11, 20),
      openedOn: openedOn,
    );

void main() {
  late AppDatabase db;
  late FoodStore store;
  final t1 = DateTime(2026, 11, 15, 10);
  final t2 = DateTime(2026, 11, 15, 11);

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    store = FoodStore(db);
  });

  tearDown(() => db.close());

  /// Saves [item] as if the backend already had it.
  Future<void> onServer(FoodItem item) async {
    await store.save(item, t1);
    await store.completeChange((await store.nextChange())!);
  }

  test('a change is saved and queued', () async {
    await store.save(food('a'), t1);

    expect(await store.item('a'), isNotNull);
    final change = (await store.nextChange())!;
    expect(
      (change.itemId, change.kind, change.changedAt),
      ('a', ChangeKind.save, t1),
    );
  });

  test(
    'changes to one item merge into its latest, in its first place',
    () async {
      await store.save(food('a'), t1);
      await store.save(food('b'), t1);
      await store.save(food('a', name: 'Oat milk'), t2);

      expect(await store.pendingCount(), 2);
      final first = (await store.nextChange())!;
      expect((first.itemId, first.changedAt), ('a', t2));
      expect((await store.item('a'))!.name, 'Oat milk');
    },
  );

  test(
    'removing an item the backend never had leaves nothing to send',
    () async {
      await store.seedOnce([food('a')]);
      await store.delete('a', t1);

      expect(await store.item('a'), isNull);
      expect(await store.pendingCount(), 0);
    },
  );

  test('removing an item whose save is queued sends the removal', () async {
    await store.save(food('a'), t1);
    await store.delete('a', t2);

    expect(await store.item('a'), isNull);
    final change = (await store.nextChange())!;
    expect((change.itemId, change.kind), ('a', ChangeKind.delete));
    expect(await store.pendingCount(), 1);
  });

  test(
    'removing an item while its save is on its way still removes it',
    () async {
      await store.save(food('a'), t1);
      final sent = (await store.nextChange())!;
      await store.delete('a', t2);

      // The backend accepts the save sent before the removal.
      await store.completeChange(sent, serverItem: food('a'));

      // The backend has it now, but the pull doesn't bring it back: its
      // removal is still to be sent.
      await store.applyServerItems([food('a')]);
      expect(await store.item('a'), isNull);
      final change = (await store.nextChange())!;
      expect((change.itemId, change.kind), ('a', ChangeKind.delete));
    },
  );

  test('removing an item the backend has queues the removal', () async {
    await onServer(food('a'));
    await store.delete('a', t2);

    final change = (await store.nextChange())!;
    expect((change.itemId, change.kind), ('a', ChangeKind.delete));
  });

  group('when the backend accepts a save', () {
    test("takes the backend's version", () async {
      await store.save(food('a'), t1);
      final sent = (await store.nextChange())!;

      await store.completeChange(sent, serverItem: food('a', name: 'Newer'));

      expect((await store.item('a'))!.name, 'Newer');
      expect(await store.pendingCount(), 0);
    });

    test('keeps a change the user made while it was sent', () async {
      await store.save(food('a'), t1);
      final sent = (await store.nextChange())!;
      await store.save(food('a', name: 'Changed again'), t2);

      await store.completeChange(sent, serverItem: food('a', name: 'Newer'));

      expect((await store.item('a'))!.name, 'Changed again');
      expect((await store.nextChange())!.changedAt, t2);
      // The backend has it now, so removing it must be sent.
      await store.delete('a', t2);
      expect((await store.nextChange())!.kind, ChangeKind.delete);
    });
  });

  test('a refused change is no longer sent, and the pull decides', () async {
    await store.save(food('a'), t1);

    await store.dropChange((await store.nextChange())!);
    expect(await store.pendingCount(), 0);

    // Someone removed it on the backend: removal wins.
    await store.applyServerItems([]);
    expect(await store.item('a'), isNull);
  });

  test(
    "the backend's list replaces everything not waiting to be sent",
    () async {
      await onServer(food('kept-by-server'));
      await onServer(food('removed-by-someone'));
      await store.save(food('mine', name: 'Mine, not sent yet'), t2);

      await store.applyServerItems([
        food('kept-by-server', name: 'Renamed by someone'),
        food('added-by-someone'),
        food('mine', name: 'Older on the server'),
      ]);

      final items = {for (final i in await store.items()) i.id: i.name};
      expect(items, {
        'kept-by-server': 'Renamed by someone',
        'added-by-someone': 'Milk',
        'mine': 'Mine, not sent yet',
      });
    },
  );

  group('claimFor', () {
    Future<Map<String, String>> onPhone() async => {
      for (final i in await store.items()) i.id: i.name,
    };

    group('food a guest added before any account signed in', () {
      setUp(() async {
        await store.seedOnce([food('sample', name: 'Sample')]);
        await store.save(food('a'), t1);
      });

      test('is offered, without the sample food', () async {
        expect(await store.guestFoodFor('anna'), 1);
      });

      test('goes to the account if it adds it', () async {
        await store.claimFor('anna');
        expect(await store.pendingCount(), 1);
      });

      test('is kept on the phone if not, and offered at the next sign-in, '
          'whoever it is', () async {
        expect(await store.claimFor('anna', addGuestFood: false), isTrue);

        // The sample food goes with the next sync, as it does for anyone.
        expect((await onPhone()).keys, ['sample']);
        expect(await store.pendingCount(), 0);

        await store.markSignedOut();
        expect(await store.guestFoodFor('ben'), 1);
        await store.claimFor('ben');
        expect((await onPhone()).keys, ['a']);
        expect(await store.pendingCount(), 1);
      });
    });

    group('after an account signs out', () {
      setUp(() async {
        await store.claimFor('anna');
        await onServer(food('a', name: "Anna's milk"));
        // Still to upload when Anna signs out.
        await store.save(food('b', name: "Anna's eggs"), t1);
        await store.markSignedOut();
        // Then, as a guest: one of Anna's changed, and one added.
        await store.save(food('a', name: "Anna's milk, opened"), t2);
        await store.save(food('c', name: 'Added as a guest'), t2);
      });

      test('what the guest added is offered, whoever signs in', () async {
        expect(await store.guestFoodFor('anna'), 1);
        expect(await store.guestFoodFor('ben'), 1);
      });

      test('the same account gets it if it adds it', () async {
        expect(await store.claimFor('anna'), isFalse);

        expect((await onPhone()).keys, {'a', 'b', 'c'});
        expect(await store.pendingCount(), 3);
        // Signed in now: nothing more to ask.
        expect(await store.guestFoodFor('anna'), 0);
      });

      test('the same account can leave it on the phone', () async {
        expect(await store.claimFor('anna', addGuestFood: false), isTrue);
        expect((await onPhone()).keys, {'a', 'b'});
        expect(await store.guestFoodFor('anna'), 0);

        await store.markSignedOut();
        expect(await store.guestFoodFor('anna'), 1);
        await store.claimFor('anna');
        expect((await onPhone()).keys, {'a', 'b', 'c'});
      });

      test('another account gets only what the guest added', () async {
        expect(await store.claimFor('ben'), isTrue);

        expect(await onPhone(), {'c': 'Added as a guest'});
        expect(await store.pendingCount(), 1);
      });

      test('left on the phone by another account, it goes to neither until '
          'one adds it', () async {
        await store.claimFor('ben', addGuestFood: false);
        expect(await store.items(), isEmpty);
        await store.markSignedOut();

        expect(await store.guestFoodFor('anna'), 1);
        await store.claimFor('anna', addGuestFood: false);
        expect((await onPhone()).keys, {'a', 'b'});
      });

      test('the account gets its food back, as it was', () async {
        await store.claimFor('ben');
        await store.save(food('x', name: "Ben's milk"), t2);
        await store.markSignedOut();

        expect(await store.guestFoodFor('anna'), 0);
        expect(await store.claimFor('anna'), isTrue);

        expect(await onPhone(), {
          'a': "Anna's milk, opened",
          'b': "Anna's eggs",
        });
        // In the order they were made.
        expect((await store.nextChange())!.itemId, 'b');
        expect(await store.pendingCount(), 2);
        // Still known to be on the backend, so removing it is sent.
        await store.delete('a', t2);
        expect(await store.pendingCount(), 2);

        // And Ben's, which is now set aside.
        await store.markSignedOut();
        await store.claimFor('ben');
        expect((await onPhone()).keys, {'c', 'x'});
      });
    });

    test('the app starting again, still signed in, asks nothing', () async {
      await store.claimFor('anna');
      await store.save(food('a'), t1);

      expect(await store.guestFoodFor('anna'), 0);
      expect(await store.claimFor('anna'), isFalse);
      expect(await store.pendingCount(), 1);
    });

    test('signing in as another account without a sign-out on this phone '
        'sets all the food aside', () async {
      await store.claimFor('anna');
      await store.save(food('a'), t1);

      expect(await store.guestFoodFor('ben'), 0);
      expect(await store.claimFor('ben'), isTrue);
      expect(await store.items(), isEmpty);
    });
  });

  test('seeds only once, even after everything is removed', () async {
    await store.seedOnce([food('a')]);
    await store.delete('a', t1);
    await store.seedOnce([food('a')]);

    expect(await store.items(), isEmpty);
    expect(await store.pendingCount(), 0);
  });
}
