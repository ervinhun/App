import 'dart:async';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/generated/export.dart';
import 'package:app/core/sync/connectivity.dart';
import 'package:app/features/auth/data/guest_mode.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/fridges/data/fridge_details.dart';
import 'package:app/features/fridges/data/fridges_api.dart';
import 'package:app/features/fridges/data/fridges_cache.dart';
import 'package:app/features/fridges/data/fridges_controller.dart';
import 'package:app/features/fridges/domain/fridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import 'fakes.dart';

class _FakeAuth extends AuthController {
  _FakeAuth(this._user);

  final UserDto? _user;

  @override
  Future<UserDto?> build() async => _user;
}

void main() {
  late FakeFridgesApi api;
  late FakeFridgesCache cache;
  late StreamController<bool> network;
  late ProviderContainer c;

  Future<void> settle() async {
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> start({UserDto? user = anna, bool guest = false}) async {
    c = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(user)),
        guestStorageProvider.overrideWithValue(FakeGuestStorage(guest)),
        fridgesApiProvider.overrideWithValue(api),
        fridgesCacheProvider.overrideWithValue(cache),
        networkAvailableProvider.overrideWith((ref) => network.stream),
      ],
    );
    c.listen(fridgesProvider, (_, _) {});
    network.add(!api.offline);
    await settle();
  }

  FridgesController fridges() => c.read(fridgesProvider.notifier);
  Fridge? current() => c.read(fridgesProvider).value?.current;

  Future<void> goOnline() async {
    api.offline = false;
    network.add(true);
    await settle();
  }

  setUp(() {
    api = FakeFridgesApi();
    cache = FakeFridgesCache();
    network = StreamController<bool>.broadcast();
  });

  tearDown(() => network.close());

  test("loads the backend's fridges and saves them for offline", () async {
    await start();

    expect(current()?.name, 'Home fridge');
    expect(cache.lists[anna.id]?.single.id, 'home');
  });

  test('offline, shows the fridges saved on the phone', () async {
    cache.lists[anna.id] = [fridge(name: 'Saved fridge')];
    api.offline = true;
    await start();

    expect(current()?.name, 'Saved fridge');
    expect(c.read(isOnlineProvider), isFalse);
  });

  test(
    'a user with no saved fridges and no connection gets an error',
    () async {
      api.offline = true;
      await start();

      expect(c.read(fridgesProvider).hasError, isTrue);
    },
  );

  test('picking a fridge is remembered', () async {
    api.fridges = [fridge(), fridge(id: 'work', name: 'Work')];
    await start();

    await fridges().select('work');

    expect(current()?.name, 'Work');
    expect(cache.current, 'work');
  });

  group('offline', () {
    test('in a fridge only the user uses, a rename is kept on the phone and '
        'uploaded when back online', () async {
      api.fridges = [fridge(members: 1)];
      await start();
      api.offline = true;
      network.add(false);
      await settle();

      final outcome = await fridges().rename(current()!, 'Cabin');

      expect(outcome, SaveOutcome.queued);
      expect(current()?.name, 'Cabin');
      expect(cache.pendingChanges['home']?.name, 'Cabin');
      expect(api.calls, isNot(contains('rename home Cabin')));

      await goOnline();

      expect(api.calls, contains('rename home Cabin'));
      expect(api.fridges.single.name, 'Cabin');
      expect(cache.pendingChanges, isEmpty);
      expect(current()?.name, 'Cabin');
    });

    test(
      'in a shared fridge, changes are refused and nothing is queued',
      () async {
        await start();
        api.offline = true;
        network.add(false);
        await settle();

        await expectLater(
          fridges().rename(current()!, 'Cabin'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              FridgesController.sharedOfflineMessage,
            ),
          ),
        );
        expect(current()?.name, 'Home fridge');
        expect(cache.pendingChanges, isEmpty);
      },
    );

    test(
      'when the backend turns out unreachable, a solo fridge still saves',
      () async {
        api.fridges = [fridge(members: 1)];
        await start();
        // The network looks fine, but the request fails.
        api.offline = true;

        final outcome = await fridges().rename(current()!, 'Cabin');

        expect(outcome, SaveOutcome.queued);
        expect(cache.pendingChanges['home']?.name, 'Cabin');
      },
    );

    test('alert settings in a solo fridge are queued, then uploaded', () async {
      api.fridges = [fridge(members: 1)];
      await start();
      c.listen(alertSettingsProvider('home'), (_, _) {});
      await settle();
      api.offline = true;
      network.add(false);
      await settle();

      const changed = AlertSettings(warningDaysBefore: 5, dangerDaysBefore: 1);
      final outcome = await c
          .read(alertSettingsProvider('home').notifier)
          .change(current()!, changed);

      expect(outcome, SaveOutcome.queued);
      expect(c.read(alertSettingsProvider('home')).value, changed);

      await goOnline();

      expect(api.alerts['home'], changed);
      expect(cache.pendingChanges, isEmpty);
      expect(c.read(alertSettingsProvider('home')).value, changed);
    });

    test('a change the backend refuses for good is dropped', () async {
      cache.lists[anna.id] = [fridge(members: 1)];
      cache.pendingChanges = {'gone': const PendingFridgeChange(name: 'X')};
      await start();

      // The backend answers renaming a deleted fridge with 404.
      expect(cache.pendingChanges, isEmpty);
    });
  });

  test('leaving a fridge takes it off the list', () async {
    api.fridges = [fridge(owner: false), fridge(id: 'work', name: 'Work')];
    await start();

    await fridges().leave(current()!);

    expect(api.calls, contains('remove ${anna.id}'));
    expect(c.read(fridgesProvider).value!.fridges.map((f) => f.id), ['work']);
  });

  test('the owner can change a member, and remove them', () async {
    await start();
    c.listen(fridgeMembersProvider('home'), (_, _) {});
    await settle();
    final members = c.read(fridgeMembersProvider('home').notifier);

    await members.updateRights(
      ben,
      canPut: false,
      canUse: true,
      accessExpiresAt: null,
    );
    expect(api.calls, contains('rights ben put=false use=true'));
    expect(
      c.read(fridgeMembersProvider('home')).value!.last.rightsLabel,
      'Remove only',
    );

    await members.remove(ben);
    expect(c.read(fridgeMembersProvider('home')).value!.map((m) => m.userId), [
      anna.id,
    ]);
  });

  group('a guest', () {
    test('has one fridge on the phone, and never calls the backend', () async {
      await start(user: null, guest: true);

      expect(current()?.isLocal, isTrue);
      final outcome = await fridges().rename(current()!, 'Flat');

      expect(outcome, SaveOutcome.queued);
      expect(current()?.name, 'Flat');
      expect(cache.lists[Fridge.localId]?.single.name, 'Flat');
      expect(cache.pendingChanges, isEmpty);
      expect(api.calls, isEmpty);
    });
  });

  test('kept for a guest, only the fridge\'s name and alerts are left, and '
      'what to upload', () async {
    cache.lists[anna.id] = [fridge()];
    cache.memberLists['home'] = [annaMember(), ben];
    cache.alertSettings['home'] = const AlertSettings(warningDaysBefore: 3);
    cache.pendingChanges = {
      'home': PendingFridgeChange(
        alerts: AlertSettings(
          warningDaysBefore: 5,
          scope: RecipientsScope.custom,
          recipientUserIds: {'ben'},
        ),
      ),
    };

    await keepFridgeForGuest(cache, fridge(name: 'Flat'));

    expect(cache.lists.keys, [Fridge.localId]);
    expect(cache.lists[Fridge.localId]?.single.name, 'Flat');
    expect(cache.lists[Fridge.localId]?.single.isLocal, isTrue);
    expect(cache.memberLists, isEmpty);
    expect(cache.pendingChanges.keys, ['home']);
    final alerts = cache.alertSettings[Fridge.localId];
    expect(alerts?.warningDaysBefore, 5);
    expect(alerts?.scope, RecipientsScope.allMembers);
    expect(alerts?.recipientUserIds, isEmpty);
  });

  test('rights read as the design words them', () {
    FridgeMember member({required bool put, required bool use}) => FridgeMember(
      userId: 'x',
      displayName: 'Sam Rivera',
      isOwner: false,
      canPut: put,
      canUse: use,
    );

    expect(member(put: true, use: true).rightsLabel, 'Add & remove');
    expect(member(put: true, use: false).rightsLabel, 'Add only');
    expect(member(put: false, use: true).rightsLabel, 'Remove only');
    expect(member(put: false, use: false).rightsLabel, 'View only');
    expect(member(put: true, use: true).initials, 'SR');
  });

  test('alert settings round-trip the backend request', () {
    const settings = AlertSettings(
      warningDaysBefore: 5,
      dangerDaysBefore: 0,
      notificationHour: 8,
      notificationMinute: 30,
      scope: RecipientsScope.custom,
      recipientUserIds: {'ben'},
    );

    final json = settings.toJson();

    expect(json['notificationTime'], '08:30:00');
    expect(json['recipientsScope'], 'custom');
    expect(AlertSettings.fromJson(json), settings);
    // Only a custom scope keeps recipients.
    expect(
      settings
          .copyWith(scope: RecipientsScope.allMembers)
          .toJson()['recipientUserIds'],
      isEmpty,
    );
  });
}
