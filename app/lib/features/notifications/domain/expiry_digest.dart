import 'package:app/features/notifications/domain/fridge_reminders.dart';
import 'package:app/features/notifications/domain/notification_settings.dart';

/// One fridge's reminder for one day: the items in their warning and danger stage.
class ExpiryDigest {
  const ExpiryDigest({
    required this.at,
    required this.fridgeId,
    required this.warningIds,
    required this.dangerIds,
    required this.settings,
  });

  final DateTime at;
  final String fridgeId;
  final List<String> warningIds;
  final List<String> dangerIds;
  final NotificationSettings settings;

  /// "You have 3 items which expire within 7 days, and 2 items which expire within 2 days."
  String get body {
    final parts = [
      if (warningIds.isNotEmpty)
        _part(warningIds.length, settings.warningDaysBefore),
      if (dangerIds.isNotEmpty)
        _part(dangerIds.length, settings.dangerDaysBefore),
    ];
    return 'You have ${parts.join(', and ')}.';
  }

  static String _part(int count, int days) {
    final items = count == 1
        ? '1 item which expires'
        : '$count items which expire';
    final when = switch (days) {
      0 => 'today',
      1 => 'by tomorrow',
      _ => 'within $days days',
    };
    return '$items $when';
  }
}

/// The key under which an item's stage is remembered as already notified.
String notifiedKey(String itemId, {required bool danger}) =>
    '$itemId:${danger ? 'danger' : 'warning'}';

/// A fridge's reminders for the next [horizonDays] days, one per day with
/// something to report, at the settings' time.
///
/// An item is reported the day it enters its warning or danger stage, or at
/// the first reminder if it is already in one and not in [notified]. With
/// [ignoreTime] a time already past today still counts (for a test notification).
List<ExpiryDigest> expiryDigests(
  FridgeReminders fridge,
  DateTime now, {
  Set<String> notified = const {},
  int horizonDays = 30,
  bool ignoreTime = false,
}) {
  final settings = fridge.settings;
  DateTime date(DateTime d) => DateTime.utc(d.year, d.month, d.day);
  final digests = <ExpiryDigest>[];
  var first = true;
  for (var k = 0; k <= horizonDays; k++) {
    final at = DateTime(
      now.year,
      now.month,
      now.day + k,
      settings.hour,
      settings.minute,
    );
    if (!ignoreTime && !at.isAfter(now)) continue;
    final warning = <String>[];
    final danger = <String>[];
    for (final item in fridge.items) {
      final left = date(item.expiresOn).difference(date(at)).inDays;
      if (left < 0 || left > settings.warningDaysBefore) continue;
      final inDanger = left <= settings.dangerDaysBefore;
      final entersToday =
          left ==
          (inDanger ? settings.dangerDaysBefore : settings.warningDaysBefore);
      final unreported =
          first && !notified.contains(notifiedKey(item.id, danger: inDanger));
      if (entersToday || unreported) {
        (inDanger ? danger : warning).add(item.id);
      }
    }
    first = false;
    if (warning.isEmpty && danger.isEmpty) continue;
    digests.add(
      ExpiryDigest(
        at: at,
        fridgeId: fridge.fridgeId,
        warningIds: warning,
        dangerIds: danger,
        settings: settings,
      ),
    );
  }
  return digests;
}
