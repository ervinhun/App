import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'package:app/core/api/api_config.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/notifications/data/notification_api.dart';
import 'package:app/features/notifications/data/notification_service.dart';
import 'package:app/features/notifications/data/notification_sync.dart';
import 'package:app/features/notifications/data/reminders_storage.dart';
import 'package:app/features/notifications/domain/fridge_reminders.dart';
import 'package:app/features/notifications/domain/notification_settings.dart';

/// Matches `BGTaskSchedulerPermittedIdentifiers` in Info.plist and AppDelegate.swift.
const expiryRefreshTask = 'com.fridgefriend.app.expiryRefresh';

/// How long before the reminder the refresh runs.
const _lead = Duration(minutes: 5);

/// Runs in a background isolate, with the app closed.
@pragma('vm:entry-point')
void notificationCallbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      final token = await TokenStorage().read();
      // No token refresh here: the app may be using the single-use refresh token.
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
          connectTimeout: const Duration(seconds: 10),
        ),
      );
      await NotificationSync(
        service: NotificationService(),
        api: NotificationApi(dio),
        storage: RemindersStorage(),
      ).refresh();
    } catch (e) {
      debugPrint('Background refresh failed: $e');
    }
    // Never retry: the reminders already scheduled are still good.
    return true;
  });
}

/// Wakes the app shortly before the daily reminder to refresh it. Android runs
/// it close to the minute; iOS picks its own time, so it is best effort there.
class BackgroundRefresh {
  Future<void> init() =>
      Workmanager().initialize(notificationCallbackDispatcher);

  /// The time until [_lead] before the next reminder at [settings]' time.
  static Duration delayUntilNext(NotificationSettings settings, DateTime now) {
    final today = DateTime(
      now.year,
      now.month,
      now.day,
      settings.hour,
      settings.minute,
    );
    final due = today.subtract(_lead);
    final next = due.isAfter(now)
        ? due
        : DateTime(
            now.year,
            now.month,
            now.day + 1,
            settings.hour,
            settings.minute,
          ).subtract(_lead);
    return next.difference(now);
  }

  /// Repeats daily, from before the earliest of the fridges' reminder times.
  Future<void> schedule(List<FridgeReminders> fridges) {
    final now = DateTime.now();
    final settings = fridges.isEmpty
        ? [const NotificationSettings()]
        : [for (final f in fridges) f.settings];
    final delay = settings
        .map((s) => delayUntilNext(s, now))
        .reduce((a, b) => a < b ? a : b);
    return Workmanager().registerPeriodicTask(
      expiryRefreshTask,
      expiryRefreshTask,
      frequency: const Duration(days: 1),
      initialDelay: delay,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}

final backgroundRefreshProvider = Provider<BackgroundRefresh>(
  (ref) => BackgroundRefresh(),
);
