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
    test("keeps a guest's food for the account they sign in to", () async {
      await store.save(food('a'), t1);

      expect(await store.claimFor('anna'), isFalse);
      expect(await store.pendingCount(), 1);
    });

    test("clears another account's food", () async {
      await store.claimFor('anna');
      await store.save(food('a'), t1);

      expect(await store.claimFor('ben'), isTrue);
      expect(await store.items(), isEmpty);
      expect(await store.pendingCount(), 0);
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
