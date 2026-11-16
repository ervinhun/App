import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/notifications/data/background_refresh.dart';
import 'package:app/features/notifications/data/notification_api.dart';
import 'package:app/features/notifications/data/notification_service.dart';
import 'package:app/features/notifications/data/notification_sync.dart';
import 'package:app/features/notifications/data/reminders_storage.dart';
import 'package:app/features/notifications/domain/fridge_reminders.dart';
import 'package:app/features/notifications/domain/notification_settings.dart';
import 'package:app/features/notifications/presentation/notifications_controller.dart';

import 'fakes.dart';

FridgeReminders _fridge({int expiresInDays = 7}) {
  final today = DateTime.now();
  return FridgeReminders(
    fridgeId: 'f1',
    settings: const NotificationSettings(),
    items: [
      ReminderItem(
        id: 'milk',
        expiresOn: DateTime(today.year, today.month, today.day + expiresInDays),
      ),
    ],
  );
}

/// Answers the backend's endpoints from a map of path to JSON.
class _Backend implements HttpClientAdapter {
  _Backend(this.responses);

  final Map<String, Object> responses;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(responses[options.path]),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  group('NotificationSettings.fromJson', () {
    test('reads days and time', () {
      final s = NotificationSettings.fromJson({
        'warningDaysBefore': 5,
        'dangerDaysBefore': 1,
        'notificationTime': '08:30:00',
      });
      expect(s.warningDaysBefore, 5);
      expect(s.dangerDaysBefore, 1);
      expect((s.hour, s.minute), (8, 30));
    });

    test('defaults to a week, 2 days and 4pm when fields are missing', () {
      final s = NotificationSettings.fromJson({});
      expect(s.warningDaysBefore, 7);
      expect(s.dangerDaysBefore, 2);
      expect((s.hour, s.minute), (16, 0));
    });

    test('an invalid time falls back to 4pm', () {
      final s = NotificationSettings.fromJson({'notificationTime': '25:99'});
      expect((s.hour, s.minute), (16, 0));
    });
  });

  group('NotificationApi.fetchReminders recipients', () {
    Future<List<FridgeReminders>> fetch({
      required String scope,
      bool isOwner = false,
      List<String> recipients = const [],
    }) {
      final dio = Dio()
        ..httpClientAdapter = _Backend({
          '/api/Auth/Me': {
            'id': 'me',
            'email': 'me@example.com',
            'displayName': 'Me',
            'locale': 'en',
          },
          '/api/fridges': [
            {'id': 'f1', 'name': 'Home', 'isOwner': isOwner},
          ],
          '/api/fridges/f1/notification-settings': {
            'recipientsScope': scope,
            'recipientUserIds': recipients,
            'warningDaysBefore': 5,
            'dangerDaysBefore': 1,
          },
          '/api/fridges/f1/items': [
            {'id': 'mine', 'addedByUserId': 'me', 'expiryDate': '2026-12-01'},
            {'id': 'theirs', 'addedByUserId': 'x', 'expiryDate': '2026-12-02'},
          ],
        });
      return NotificationApi(dio).fetchReminders();
    }

    test('all members: every item, with the fridge settings', () async {
      final r = await fetch(scope: 'all_members');
      expect(r.single.items.map((i) => i.id), ['mine', 'theirs']);
      expect(r.single.settings.warningDaysBefore, 5);
    });

    test('adder and owners: a member gets only what they added', () async {
      final r = await fetch(scope: 'adder_and_owners');
      expect(r.single.items.map((i) => i.id), ['mine']);
    });

    test('adder and owners: the owner gets everything', () async {
      final r = await fetch(scope: 'adder_and_owners', isOwner: true);
      expect(r.single.items, hasLength(2));
    });

    test('custom: only if the user was picked', () async {
      expect(await fetch(scope: 'custom', recipients: ['x']), isEmpty);
      expect(await fetch(scope: 'custom', recipients: ['me']), hasLength(1));
    });
  });

  group('NotificationSync', () {
    late FakeNotificationService service;
    late FakeRemindersStorage storage;
    late FakeNotificationApi api;

    NotificationSync sync([DateTime Function()? clock]) => NotificationSync(
      service: service,
      api: api,
      storage: storage,
      clock: clock,
    );

    setUp(() {
      service = FakeNotificationService();
      storage = FakeRemindersStorage();
      api = FakeNotificationApi();
    });

    test('offline: schedules from what is saved', () async {
      storage.reminders = [_fridge()];
      api.fails = true;

      await sync().refresh();

      expect(service.scheduledFor?.single.fridgeId, 'f1');
    });

    test('backend changes are saved and scheduled', () async {
      storage.reminders = [_fridge()];
      api.remote = [_fridge(expiresInDays: 3)];

      await sync().refresh();

      expect(storage.reminders!.single.items.single.id, 'milk');
      expect(service.scheduledFor, same(storage.reminders));
    });

    test('the fallback is used only until anything has been saved', () async {
      api.fails = true;
      await sync().refresh(fallback: [_fridge()]);
      expect(service.scheduledFor, hasLength(1));
      expect(storage.reminders, isNull);
    });

    test(
      'a fetched empty list is kept, not replaced by the fallback',
      () async {
        await sync().refresh(fallback: [_fridge()]);
        expect(service.scheduledFor, isEmpty);
        expect(storage.reminders, isEmpty);
      },
    );

    test('a delivered reminder is reported, a future one is dropped', () async {
      final now = DateTime(2026, 11, 16, 17);
      storage.pending = [
        PendingDispatch(
          fridgeId: 'f1',
          at: DateTime(2026, 11, 16, 16),
          warningIds: const ['milk'],
          dangerIds: const [],
        ),
        PendingDispatch(
          fridgeId: 'f1',
          at: DateTime(2026, 11, 17, 16),
          warningIds: const ['eggs'],
          dangerIds: const [],
        ),
      ];

      await sync(() => now).refresh();

      expect(api.reported.single.warningIds, ['milk']);
      expect(storage.pending, isEmpty);
    });

    test('a failed report is kept to try again', () async {
      storage.pending = [
        PendingDispatch(
          fridgeId: 'f1',
          at: DateTime(2026, 11, 16, 16),
          warningIds: const ['milk'],
          dangerIds: const [],
        ),
      ];
      api.reportFails = true;

      await sync(() => DateTime(2026, 11, 16, 17)).refresh();

      expect(storage.pending, hasLength(1));
    });

    test('nothing is reported when notifications are off', () async {
      service.allowed = false;
      storage.pending = [
        PendingDispatch(
          fridgeId: 'f1',
          at: DateTime(2026, 11, 16, 16),
          warningIds: const ['milk'],
          dangerIds: const [],
        ),
      ];

      await sync(() => DateTime(2026, 11, 16, 17)).refresh();

      expect(api.reported, isEmpty);
      expect(storage.pending, isEmpty);
    });
  });

  group('NotificationsController', () {
    late FakeNotificationService service;
    late FakeNotificationApi api;

    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(service),
          backgroundRefreshProvider.overrideWithValue(FakeBackgroundRefresh()),
          remindersStorageProvider.overrideWithValue(FakeRemindersStorage()),
          notificationApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() {
      service = FakeNotificationService();
      api = FakeNotificationApi();
    });

    test('asks for permission only when not already allowed', () async {
      final controller = container().read(notificationsControllerProvider);

      expect(await controller.ensureAllowed(), isTrue);
      expect(service.requests, 0);

      service.allowed = false;
      expect(await controller.ensureAllowed(), isFalse);
      expect(service.requests, 1);
    });

    test('the test notification says what a real one would', () async {
      api.remote = [_fridge()];
      final controller = container().read(notificationsControllerProvider);

      final body = await controller.sendTest();

      expect(body, 'You have 1 item which expires within 7 days.');
      expect(service.shown, body);
    });
  });
}
