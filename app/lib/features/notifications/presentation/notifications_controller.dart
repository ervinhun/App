import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/food/data/food_items_controller.dart';
import 'package:app/features/notifications/data/background_refresh.dart';
import 'package:app/features/notifications/data/notification_api.dart';
import 'package:app/features/notifications/data/notification_service.dart';
import 'package:app/features/notifications/data/notification_sync.dart';
import 'package:app/features/notifications/data/reminders_storage.dart';
import 'package:app/features/notifications/domain/expiry_digest.dart';
import 'package:app/features/notifications/domain/fridge_reminders.dart';
import 'package:app/features/notifications/domain/notification_settings.dart';

/// Keeps the scheduled notifications up to date with the food and the backend.
class NotificationsController {
  NotificationsController(this._ref) {
    // The in-app list only matters until the backend has reminders for us.
    _ref.listen(foodItemsProvider, (_, _) => _update(checkBackend: false));
  }

  final Ref _ref;
  var _reminders = <FridgeReminders>[];
  Future<void> _running = Future.value();

  NotificationService get _service => _ref.read(notificationServiceProvider);

  /// One fridge made from the app's own food list, with default settings.
  List<FridgeReminders> get _fallback => [
    FridgeReminders(
      fridgeId: '',
      settings: const NotificationSettings(),
      items: [
        // Empty while the food is read; the listener updates once it's there.
        for (final item in _ref.read(foodItemsProvider).value ?? const [])
          ReminderItem(
            id: item.id,
            expiresOn: item.expiresOn,
            skipWarning: item.skipsWarning(
              const NotificationSettings().warningDaysBefore,
            ),
          ),
      ],
    ),
  ];

  /// Schedules from what is saved on the device, then checks the backend.
  Future<void> start() async {
    try {
      await _service.init();
      await _ref.read(backgroundRefreshProvider).init();
    } catch (e) {
      debugPrint('Could not set up notifications: $e');
    }
    await _update(checkBackend: true);
  }

  /// Runs one refresh at a time, so overlapping ones don't overwrite each other.
  Future<void> _update({required bool checkBackend}) =>
      _running = _running.then((_) async {
        try {
          _reminders = await NotificationSync(
            service: _service,
            api: _ref.read(notificationApiProvider),
            storage: _ref.read(remindersStorageProvider),
          ).refresh(fallback: _fallback, checkBackend: checkBackend);
          await _ref.read(backgroundRefreshProvider).schedule(_reminders);
        } catch (e) {
          debugPrint('Could not schedule the notifications: $e');
        }
      });

  /// Whether notifications are allowed, showing the system prompt if the user
  /// hasn't been asked yet.
  Future<bool> ensureAllowed() async {
    await _service.init();
    return await _service.isAllowed() || await _service.requestPermission();
  }

  Future<void> openSystemSettings() => _service.openSettings();

  /// Shows the next reminder now, from the latest data: the soonest day with
  /// something to report, whatever its time. Returns what it said.
  Future<String> sendTest() async {
    await _update(checkBackend: true);
    final digests = [
      for (final f in _reminders)
        ...expiryDigests(f, DateTime.now(), ignoreTime: true),
    ]..sort((a, b) => a.at.compareTo(b.at));
    final body = digests.isEmpty
        ? 'Nothing is about to expire.'
        : digests.first.body;
    await _service.showNow(body);
    return body;
  }
}

final notificationsControllerProvider = Provider<NotificationsController>(
  NotificationsController.new,
);
