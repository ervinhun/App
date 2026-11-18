import 'package:flutter/foundation.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/features/notifications/data/notification_api.dart';
import 'package:app/features/notifications/data/notification_service.dart';
import 'package:app/features/notifications/data/reminders_storage.dart';
import 'package:app/features/notifications/domain/expiry_digest.dart';
import 'package:app/features/notifications/domain/fridge_reminders.dart';

/// Reports delivered reminders, checks the backend for changes and schedules
/// what is due next. Offline, it uses what is saved on the device.
class NotificationSync {
  NotificationSync({
    required this.service,
    required this.api,
    required this.storage,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final NotificationService service;
  final NotificationApi api;
  final RemindersStorage storage;
  final DateTime Function() _now;

  /// Returns the reminders in force. [fallback] is used only until the device
  /// has any from the backend; [checkBackend] false skips the network.
  Future<List<FridgeReminders>> refresh({
    List<FridgeReminders> fallback = const [],
    bool checkBackend = true,
  }) async {
    await service.init();
    final notified = await storage.readNotified();
    final failed = await _reportDelivered(
      await storage.readPending(),
      notified,
    );
    var reminders = await storage.readReminders();
    if (checkBackend) {
      try {
        reminders = await api.fetchReminders();
        await storage.saveReminders(reminders);
      } catch (e) {
        debugPrint('Using the saved reminders, backend unreachable: $e');
      }
    }
    reminders ??= fallback;
    final scheduled = await service.schedule(reminders, notified: notified);
    final ids = {
      for (final r in reminders)
        for (final i in r.items) i.id,
    };
    notified.removeWhere((key) => !ids.contains(key.split(':').first));
    await storage.saveNotified(notified);
    await storage.savePending([
      ...failed,
      for (final d in scheduled) PendingDispatch.of(d),
    ]);
    return reminders;
  }

  /// Reports the reminders whose time has passed, and returns those it
  /// couldn't. A local notification can't confirm it was shown, so one due
  /// while notifications were allowed counts as delivered and joins [notified].
  Future<List<PendingDispatch>> _reportDelivered(
    List<PendingDispatch> pending,
    Set<String> notified,
  ) async {
    final now = _now();
    final allowed = await service.isAllowed();
    final failed = <PendingDispatch>[];
    for (final dispatch in pending.where((d) => !d.at.isAfter(now))) {
      if (!allowed) continue;
      notified.addAll([
        for (final id in dispatch.warningIds) notifiedKey(id, danger: false),
        for (final id in dispatch.dangerIds) notifiedKey(id, danger: true),
      ]);
      // The fallback fridge is only on this device, so there's no one to tell.
      if (dispatch.fridgeId.isEmpty) continue;
      try {
        await api.reportDispatch(dispatch);
      } catch (e) {
        debugPrint('Could not report a delivered reminder: $e');
        // A 404 means the item or fridge is gone, so retrying would never work.
        if (e is! ApiException || e.statusCode != 404) failed.add(dispatch);
      }
    }
    return failed;
  }
}
