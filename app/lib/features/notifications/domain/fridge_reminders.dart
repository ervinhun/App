import 'package:app/features/notifications/domain/notification_settings.dart';

/// One item that can trigger a reminder.
class ReminderItem {
  const ReminderItem({
    required this.id,
    required this.expiresOn,
    this.skipWarning = false,
  });

  final String id;
  final DateTime expiresOn;

  /// Its whole shelf life is no longer than the warning period, so the warning
  /// would come the moment it is added: only the danger notice applies.
  final bool skipWarning;

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
    id: json['id'] as String,
    expiresOn: DateTime.parse(json['expiresOn'] as String),
    skipWarning: json['skipWarning'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'expiresOn': expiresOn.toIso8601String().substring(0, 10),
    'skipWarning': skipWarning,
  };
}

/// A fridge's notification settings and the items this user is to be
/// reminded about, after its recipient rules.
class FridgeReminders {
  const FridgeReminders({
    required this.fridgeId,
    required this.settings,
    required this.items,
  });

  final String fridgeId;
  final NotificationSettings settings;
  final List<ReminderItem> items;

  factory FridgeReminders.fromJson(Map<String, dynamic> json) =>
      FridgeReminders(
        fridgeId: json['fridgeId'] as String,
        settings: NotificationSettings.fromJson(
          json['settings'] as Map<String, dynamic>,
        ),
        items: [
          for (final i in json['items'] as List)
            ReminderItem.fromJson(i as Map<String, dynamic>),
        ],
      );

  Map<String, dynamic> toJson() => {
    'fridgeId': fridgeId,
    'settings': settings.toJson(),
    'items': [for (final i in items) i.toJson()],
  };
}
