/// When to warn about food that is about to expire: how many days ahead, and
/// at what time of day.
class NotificationSettings {
  const NotificationSettings({
    this.warningDaysBefore = defaultWarningDays,
    this.dangerDaysBefore = defaultDangerDays,
    this.hour = defaultHour,
    this.minute = defaultMinute,
  });

  /// The defaults: a warning a week ahead, a danger notice two days ahead, at 4pm.
  static const defaultWarningDays = 7;
  static const defaultDangerDays = 2;
  static const defaultHour = 16;
  static const defaultMinute = 0;

  final int warningDaysBefore;
  final int dangerDaysBefore;
  final int hour;
  final int minute;

  /// Reads the backend's notification settings. Anything missing or invalid,
  /// such as the time, falls back to its default.
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final time = _parseTime(json['notificationTime']);
    return NotificationSettings(
      warningDaysBefore: _days(json['warningDaysBefore']) ?? defaultWarningDays,
      dangerDaysBefore: _days(json['dangerDaysBefore']) ?? defaultDangerDays,
      hour: time?.$1 ?? defaultHour,
      minute: time?.$2 ?? defaultMinute,
    );
  }

  Map<String, dynamic> toJson() => {
    'warningDaysBefore': warningDaysBefore,
    'dangerDaysBefore': dangerDaysBefore,
    'notificationTime':
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
  };

  static int? _days(Object? value) => value is int && value >= 0 ? value : null;

  /// "16:00" or "16:00:00".
  static (int, int)? _parseTime(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return null;
    final hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    return hour < 24 && minute < 60 ? (hour, minute) : null;
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings &&
      other.warningDaysBefore == warningDaysBefore &&
      other.dangerDaysBefore == dangerDaysBefore &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode =>
      Object.hash(warningDaysBefore, dangerDaysBefore, hour, minute);
}
