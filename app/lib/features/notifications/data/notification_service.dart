import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:app/features/notifications/domain/expiry_digest.dart';
import 'package:app/features/notifications/domain/fridge_reminders.dart';

/// Schedules the on-device expiry notifications, so they work offline.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  final _taps = StreamController<String?>.broadcast();

  /// The payload of each reminder tapped while the app is running.
  Stream<String?> get taps => _taps.stream;

  /// The payload of every reminder, for [taps].
  static const expiringPayload = 'expiring';

  /// The logo mark as a white silhouette: Android tints the small icon.
  static const _icon = 'ic_stat_logo';
  static const _title = 'FridgeFriend';

  /// Most reminders scheduled at once; iOS allows 64.
  static const _maxPending = 30;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'expiry',
      'Expiring food',
      channelDescription: 'Reminders about food that is about to expire',
      importance: Importance.high,
      priority: Priority.high,
      icon: _icon,
    ),
    iOS: DarwinNotificationDetails(),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('Could not read the time zone, using UTC: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
        // Permission is asked for in [requestPermission], not at startup.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) => _taps.add(r.payload),
    );
    _ready = true;
  }

  /// Whether the user has allowed notifications.
  Future<bool> isAllowed() async =>
      defaultTargetPlatform == TargetPlatform.android
      ? await _android?.areNotificationsEnabled() ?? false
      : (await _ios?.checkPermissions())?.isEnabled ?? false;

  /// Shows the system permission prompt. Once refused it won't show again:
  /// see [openSettings].
  Future<bool> requestPermission() async =>
      defaultTargetPlatform == TargetPlatform.android
      ? await _android?.requestNotificationsPermission() ?? false
      : await _ios?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;

  /// Whether a reminder was tapped to start the app.
  Future<bool> launchedByReminder() async {
    final launch = await _plugin.getNotificationAppLaunchDetails();
    return launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse?.payload == expiringPayload;
  }

  Future<void> openSettings() => _plugin.openAppNotificationSettings();

  /// Replaces the scheduled reminders with the next [_maxPending] due (see
  /// [expiryDigests]), and returns them.
  Future<List<ExpiryDigest>> schedule(
    List<FridgeReminders> fridges, {
    Set<String> notified = const {},
  }) async {
    await _plugin.cancelAllPendingNotifications();
    final now = DateTime.now();
    final digests = [
      for (final fridge in fridges)
        ...expiryDigests(fridge, now, notified: notified),
    ]..sort((a, b) => a.at.compareTo(b.at));
    final scheduled = digests.take(_maxPending).toList();
    for (final (i, digest) in scheduled.indexed) {
      await _plugin.zonedSchedule(
        id: i,
        title: _title,
        body: digest.body,
        scheduledDate: tz.TZDateTime.from(digest.at, tz.local),
        payload: expiringPayload,
        notificationDetails: _details,
        // Inexact needs no exact-alarm permission, and a reminder can drift.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    return scheduled;
  }

  Future<void> showNow(String body) => _plugin.show(
    id: 1000,
    title: _title,
    body: body,
    notificationDetails: _details,
    payload: expiringPayload,
  );
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);
