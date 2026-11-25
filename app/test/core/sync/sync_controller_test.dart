import 'dart:async';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/generated/export.dart';
import 'package:app/core/sync/connectivity.dart';
import 'package:app/core/sync/sync_controller.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/food/data/food_items_controller.dart';
import 'package:app/features/food/data/guest_food_question.dart';
import 'package:app/features/food/data/items_remote.dart';
import 'package:app/features/food/data/sample_food.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/auth/fakes.dart';
import '../../features/food/food_store_test.dart' show food;
import '../db/test_database.dart';

/// The backend's copy of the fridge, shared with other members.
class FakeItemsRemote implements ItemsRemote {
  final items = <String, FoodItem>{};
  final calls = <String>[];
  bool offline = false;

  /// The status the backend answers changes to this item with, if not 200.
  final refuse = <String, int>{};

  void _answer(String call, String id) {
    if (offline) throw ApiException("Can't reach the server.");
    calls.add('$call $id');
    if (refuse[id] case final status?) {
      throw ApiException('Refused', statusCode: status);
    }
  }

  /// The status opening the fridge fails with, if any.
  int? refuseOpen;

  /// When set, a save waits for this before it's answered.
  Completer<void>? saveGate;

  /// When set, fetching waits for this before it's answered.
  Completer<void>? fetchGate;

  @override
  Future<void> open() async {
    if (offline) throw ApiException("Can't reach the server.");
    if (refuseOpen case final status?) {
      throw ApiException('Refused', statusCode: status);
    }
  }

  @override
  Future<FoodItem> save(FoodItem item, {required DateTime changedAt}) async {
    await saveGate?.future;
    _answer('save', item.id);
    return items[item.id] = item;
  }

  @override
  Future<void> delete(String id, {required DateTime changedAt}) async {
    _answer('delete', id);
    items.remove(id);
  }

  @override
  Future<List<FoodItem>> fetchAll() async {
    if (offline) throw ApiException("Can't reach the server.");
    final fetched = [...items.values];
    await fetchGate?.future;
    return fetched;
  }
}

class _FakeAuth extends AuthController {
  _FakeAuth(this._user);

  final UserDto? _user;

  @override
  Future<UserDto?> build() async => _user;

  void signIn(UserDto user) => state = AsyncData(user);

  void signOutHere() => state = const AsyncData(null);
}

void main() {
  late FakeItemsRemote remote;
  late StreamController<bool> network;
  late ProviderContainer c;

  ProviderContainer start({UserDto? user = anna}) {
    c = ProviderContainer.test(
      overrides: [
        inMemoryDatabase(),
        initialFoodProvider.overrideWithValue(const []),
        itemsRemoteProvider.overrideWithValue(remote),
        authControllerProvider.overrideWith(() => _FakeAuth(user)),
        networkAvailableProvider.overrideWith((ref) => network.stream),
      ],
    );
    c.listen(syncControllerProvider, (_, _) {});
    c.listen(foodItemsProvider, (_, _) {});
    return c;
  }

  FoodItemsController foodNotifier() => c.read(foodItemsProvider.notifier);
  SyncStatus status() => c.read(syncControllerProvider);
  Set<String> names() => {
    for (final i in c.read(foodItemsProvider).requireValue) i.name,
  };

  /// Lets the saves and the sync they start finish.
  Future<void> settle() async {
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    remote = FakeItemsRemote();
    network = StreamController<bool>.broadcast();
  });

  tearDown(() => network.close());

  test('a change is sent to the backend', () async {
    start();
    await settle();

    foodNotifier().add(food('a'));
    await settle();

    expect(remote.calls, ['save a']);
    expect(status().pending, 0);
  });

  test(
    'offline, changes wait; when back online they are sent in order',
    () async {
      remote.offline = true;
      start();
      await settle();

      foodNotifier()
        ..add(food('a'))
        ..add(food('b'));
      await settle();
      final opened = foodNotifier().markOpened('a', DateTime(2026, 11, 15));
      await settle();

      expect(remote.calls, isEmpty);
      expect(status().pending, 2);
      expect(status().reachable, isFalse);
      // Still shown, opened, while offline.
      expect(c.read(foodItemsProvider).requireValue.first.isOpened, isTrue);
      expect(opened.isOpened, isFalse);

      remote.offline = false;
      network
        ..add(false)
        ..add(true);
      await settle();

      expect(remote.calls, ['save a', 'save b']);
      expect(remote.items['a']!.isOpened, isTrue);
      expect(status().pending, 0);
      expect(status().reachable, isTrue);
    },
  );

  test("someone else's newer change wins and shows here", () async {
    start();
    await settle();
    foodNotifier().add(food('a'));
    await settle();

    // Another member renames it; this device's next sync pulls that in.
    remote.items['a'] = food('a', name: 'Renamed by Ben');
    foodNotifier().add(food('b'));
    await settle();

    expect(names(), {'Renamed by Ben', 'Milk'});
  });

  test('removal wins over an offline change, and the user is told', () async {
    start();
    await settle();
    foodNotifier().add(food('a', name: 'Yoghurt'));
    await settle();

    remote.offline = true;
    foodNotifier().markOpened('a', DateTime(2026, 11, 15));
    await settle();
    // Meanwhile another member removes it.
    remote.items.remove('a');
    remote.refuse['a'] = 410;

    remote.offline = false;
    await c.read(syncControllerProvider.notifier).syncNow();
    await settle();

    expect(names(), isEmpty);
    expect(remote.items, isEmpty);
    expect(status().rejected, 1);
  });

  test(
    "without the right to change it, the backend's copy comes back",
    () async {
      remote.items['a'] = food('a', name: 'Cheese');
      start();
      await settle();
      expect(names(), {'Cheese'});

      // The owner took away this member's rights.
      remote.refuse['a'] = 403;
      foodNotifier().remove('a');
      await settle();

      expect(names(), {'Cheese'});
      expect(status().rejected, 1);
      expect(status().pending, 0);
    },
  );

  test('a busy backend keeps the change for later', () async {
    start();
    await settle();
    remote.refuse['a'] = 503;

    foodNotifier().add(food('a'));
    await settle();

    expect(status().pending, 1);
    expect(status().rejected, 0);
    expect(status().reachable, isTrue);

    remote.refuse.remove('a');
    await c.read(syncControllerProvider.notifier).syncNow();
    expect(status().pending, 0);
  });

  for (final code in [400, 403, 404, 503]) {
    test('a $code when opening the fridge loses nothing', () async {
      remote.refuseOpen = code;
      start();
      await settle();

      foodNotifier().add(food('a'));
      await settle();

      expect(names(), {'Milk'});
      expect(status().pending, 1);
      expect(status().rejected, 0);

      remote.refuseOpen = null;
      await c.read(syncControllerProvider.notifier).syncNow();
      expect(remote.calls, ['save a']);
      expect(status().pending, 0);
    });
  }

  test('food whose fridge is gone waits for the next one', () async {
    start();
    await settle();
    remote.refuse['a'] = 404;

    foodNotifier().add(food('a'));
    await settle();

    expect(names(), {'Milk'});
    expect(status().pending, 1);
  });

  test('a change during its own upload is sent too', () async {
    start();
    await settle();
    remote.saveGate = Completer();
    foodNotifier().add(food('a'));
    await settle();
    foodNotifier().markOpened('a', DateTime(2026, 11, 15));
    await settle();

    remote.saveGate!.complete();
    await settle();

    expect(remote.items['a']!.isOpened, isTrue);
    expect(c.read(foodItemsProvider).requireValue.single.isOpened, isTrue);
    expect(status().pending, 0);
  });

  group('signing in as someone else during a sync', () {
    const ben = UserDto(
      id: '00000000-0000-0000-0000-000000000002',
      email: 'ben@example.com',
      displayName: 'Ben',
      locale: 'en',
    );
    void signInBen() =>
        (c.read(authControllerProvider.notifier) as _FakeAuth).signIn(ben);

    test("doesn't show them food that was being fetched", () async {
      remote.items['x'] = food('x', name: "Anna's");
      remote.fetchGate = Completer();
      start();
      await settle();

      signInBen();
      await settle();
      remote.items.clear();
      remote.fetchGate!.complete();
      await settle();

      expect(names(), isEmpty);
    });

    test("doesn't show them food that was being sent", () async {
      start();
      await settle();
      remote.saveGate = Completer();
      foodNotifier().add(food('a', name: "Anna's"));
      await settle();

      signInBen();
      await settle();
      remote.saveGate!.complete();
      remote.items.clear();
      await settle();
      remote.items.clear();
      await c.read(syncControllerProvider.notifier).syncNow();
      await settle();

      expect(names(), isEmpty);
    });
  });

  test('restoring a removed item brings it back under a new id', () async {
    start();
    await settle();
    foodNotifier().add(food('a'));
    await settle();

    final (removed, index) = foodNotifier().remove('a');
    await settle();
    foodNotifier().restore(removed, index);
    await settle();

    expect(remote.calls.take(2), ['save a', 'delete a']);
    expect(remote.items.keys, isNot(contains('a')));
    expect(remote.items.values.single.name, 'Milk');
    expect(names(), {'Milk'});
  });

  test("a guest's food waits, and is uploaded when they sign in", () async {
    start(user: null);
    await settle();

    foodNotifier().add(food('a'));
    await settle();
    expect(remote.calls, isEmpty);
    expect(status().pending, 1);

    (c.read(authControllerProvider.notifier) as _FakeAuth).signIn(anna);
    await settle();
    expect(c.read(guestFoodQuestionProvider), 1);
    c.read(guestFoodQuestionProvider.notifier).answer(add: true);
    await settle();

    expect(remote.calls, ['save a']);
    expect(names(), {'Milk'});
  });

  test("signing in as someone else clears the last account's food", () async {
    remote.offline = true;
    start();
    await settle();
    foodNotifier().add(food('a'));
    await settle();

    (c.read(authControllerProvider.notifier) as _FakeAuth).signIn(
      const UserDto(
        id: '00000000-0000-0000-0000-000000000002',
        email: 'ben@example.com',
        displayName: 'Ben',
        locale: 'en',
      ),
    );
    await settle();

    expect(names(), isEmpty);
    expect(status().pending, 0);
  });

  group("a guest's food, at sign-in", () {
    _FakeAuth auth() => c.read(authControllerProvider.notifier) as _FakeAuth;
    GuestFoodQuestionController question() =>
        c.read(guestFoodQuestionProvider.notifier);

    setUp(() async {
      remote.items['x'] = food('x', name: 'On the account');
      start(user: null);
      await settle();
      foodNotifier().add(food('a', name: 'Added as a guest'));
      await settle();
      auth().signIn(anna);
      await settle();
    });

    test('is asked about first, and nothing is sent meanwhile', () async {
      expect(c.read(guestFoodQuestionProvider), 1);
      expect(remote.calls, isEmpty);

      question().answer(add: true);
      await settle();

      expect(c.read(guestFoodQuestionProvider), isNull);
      expect(remote.calls, ['save a']);
      expect(names(), {'Added as a guest', 'On the account'});
    });

    test("isn't added if the user keeps it on the phone", () async {
      question().answer(add: false);
      await settle();

      expect(remote.calls, isEmpty);
      expect(names(), {'On the account'});
      expect(status().pending, 0);
    });

    test('stays a guest\'s if they sign out before answering', () async {
      auth().signOutHere();
      await settle();

      expect(c.read(guestFoodQuestionProvider), isNull);
      expect(remote.calls, isEmpty);
      expect(names(), {'Added as a guest'});
      expect(status().pending, 1);
    });
  });
}
