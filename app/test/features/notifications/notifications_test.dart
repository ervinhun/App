import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/api/generated/export.dart';
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

  test('NotificationSettings.fromResponse falls back like fromJson', () {
    final s = NotificationSettings.fromResponse(
      const NotificationItemsResponse(
        warningDaysBefore: 5,
        notificationTime: '25:99',
      ),
    );
    expect(s.warningDaysBefore, 5);
    expect(s.dangerDaysBefore, 2);
    expect((s.hour, s.minute), (16, 0));
  });

  group('NotificationApi.fetchReminders', () {
    test('reads each fridge from its notification-items', () async {
      final dio = Dio()
        ..httpClientAdapter = _Backend({
          '/api/fridges': [
            {'id': 'f1', 'name': 'Home'},
            {'id': 'f2', 'name': 'Cabin'},
          ],
          '/api/fridges/f1/notification-items': {
            'fridgeId': 'f1',
            'warningDaysBefore': 5,
            'dangerDaysBefore': 1,
            'notificationTime': '08:30:00',
            'items': [
              {'id': 'milk', 'expiryDate': '2026-12-01', 'skipWarning': false},
              {'id': 'bread', 'expiryDate': '2026-12-02', 'skipWarning': true},
            ],
          },
          '/api/fridges/f2/notification-items': {
            'fridgeId': 'f2',
            'warningDaysBefore': 7,
            'dangerDaysBefore': 2,
            'notificationTime': '16:00:00',
            'items': [],
          },
        });

      final r = await NotificationApi(dio).fetchReminders();

      expect(r.map((f) => f.fridgeId), ['f1', 'f2']);
      expect(r[0].settings.warningDaysBefore, 5);
      expect((r[0].settings.hour, r[0].settings.minute), (8, 30));
      expect(r[0].items.map((i) => i.id), ['milk', 'bread']);
      expect(r[0].items.map((i) => i.skipWarning), [false, true]);
      expect(r[0].items.first.expiresOn.day, 1);
      expect(r[1].items, isEmpty);
    });
  });

  group('ReminderItem', () {
    test('keeps skipWarning through the saved JSON, and defaults it off', () {
      final item = ReminderItem(
        id: 'a',
        expiresOn: DateTime(2026, 12, 1),
        skipWarning: true,
      );
      expect(ReminderItem.fromJson(item.toJson()).skipWarning, isTrue);
      expect(
        ReminderItem.fromJson({'id': 'a', 'expiresOn': '2026-12-01'})
            .skipWarning,
        isFalse,
      );
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

    test(
      'a report the backend answers 404 to is dropped, not retried',
      () async {
        storage.pending = [
          PendingDispatch(
            fridgeId: 'f1',
            at: DateTime(2026, 11, 16, 16),
            warningIds: const ['gone'],
            dangerIds: const [],
          ),
        ];
        api.reportStatus = 404;

        await sync(() => DateTime(2026, 11, 16, 17)).refresh();

        expect(storage.pending, isEmpty);
      },
    );

    test('a report the backend answers 500 to is kept to try again', () async {
      storage.pending = [
        PendingDispatch(
          fridgeId: 'f1',
          at: DateTime(2026, 11, 16, 16),
          warningIds: const ['milk'],
          dangerIds: const [],
        ),
      ];
      api.reportStatus = 500;

      await sync(() => DateTime(2026, 11, 16, 17)).refresh();

      expect(storage.pending, hasLength(1));
    });

    test(
      'the on-device fallback fridge is counted as notified but never reported',
      () async {
        storage.pending = [
          PendingDispatch(
            fridgeId: '',
            at: DateTime(2026, 11, 16, 16),
            warningIds: const ['milk'],
            dangerIds: const [],
          ),
        ];

        await sync(() => DateTime(2026, 11, 16, 17))
            .refresh(fallback: [_fridge()]);

        expect(api.reported, isEmpty);
        expect(storage.pending, isEmpty);
      },
    );

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
