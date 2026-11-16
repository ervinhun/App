import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/notifications/data/background_refresh.dart';
import 'package:app/features/notifications/domain/expiry_digest.dart';
import 'package:app/features/notifications/domain/fridge_reminders.dart';
import 'package:app/features/notifications/domain/notification_settings.dart';

void main() {
  const settings = NotificationSettings(); // 7 days, 2 days, 16:00
  final now = DateTime(2026, 11, 16, 10);
  DateTime inDays(int n) => DateTime(2026, 11, 16 + n);

  FridgeReminders fridge(
    List<int> daysAhead, [
    NotificationSettings s = settings,
  ]) => FridgeReminders(
    fridgeId: 'f1',
    settings: s,
    items: [
      for (final (i, d) in daysAhead.indexed)
        ReminderItem(id: 'i$i', expiresOn: inDays(d)),
    ],
  );

  test('items already inside a window are reported at the first reminder', () {
    // Two items 1 day out and one 2 days out are all in danger today, and the
    // strawberries (3 days) are in warning.
    final digests = expiryDigests(fridge([1, 1, 2, 3]), now);
    expect(digests.first.at, DateTime(2026, 11, 16, 16));
    expect(digests.first.dangerIds, ['i0', 'i1', 'i2']);
    expect(digests.first.warningIds, ['i3']);
    expect(
      digests.first.body,
      'You have 1 item which expires within 7 days, '
      'and 3 items which expire within 2 days.',
    );
  });

  test('an item is reported again only when it enters the next stage', () {
    final digests = expiryDigests(fridge([7]), now);
    expect(digests.first.warningIds, ['i0']);
    // Five days on it is two days out: danger.
    expect(digests[1].at, DateTime(2026, 11, 21, 16));
    expect(digests[1].dangerIds, ['i0']);
    expect(digests, hasLength(2));
  });

  test('a stage already notified is not repeated', () {
    final notified = {notifiedKey('i0', danger: true)};
    final digests = expiryDigests(fridge([1, 1]), now, notified: notified);
    expect(digests.single.dangerIds, ['i1']);
  });

  test('wording for tomorrow and today', () {
    const s = NotificationSettings(warningDaysBefore: 3, dangerDaysBefore: 1);
    expect(
      expiryDigests(fridge([3], s), now).first.body,
      'You have 1 item which expires within 3 days.',
    );
    expect(
      expiryDigests(fridge([1], s), now).first.body,
      'You have 1 item which expires by tomorrow.',
    );
  });

  test("skips today's reminder once its time has passed", () {
    final late = DateTime(2026, 11, 16, 17);
    expect(
      expiryDigests(fridge([7]), late).first.at,
      DateTime(2026, 11, 17, 16),
    );
    // A test notification doesn't care about the time of day.
    expect(
      expiryDigests(fridge([7]), late, ignoreTime: true).first.at,
      DateTime(2026, 11, 16, 16),
    );
  });

  group('BackgroundRefresh.delayUntilNext', () {
    test('is 5 minutes before the reminder', () {
      expect(
        BackgroundRefresh.delayUntilNext(
          settings,
          DateTime(2026, 11, 16, 15, 0),
        ),
        const Duration(minutes: 55),
      );
    });

    test('rolls over to tomorrow once it has passed', () {
      expect(
        BackgroundRefresh.delayUntilNext(
          settings,
          DateTime(2026, 11, 16, 15, 56),
        ),
        const Duration(hours: 23, minutes: 59),
      );
    });
  });
}
