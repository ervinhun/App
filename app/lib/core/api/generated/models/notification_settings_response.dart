// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'notification_settings_response.g.dart';

@JsonSerializable()
class NotificationSettingsResponse {
  const NotificationSettingsResponse({
    this.fridgeId,
    this.warningDaysBefore,
    this.dangerDaysBefore,
    this.notificationTime,
    this.recipientsScope,
    this.recipientUserIds,
  });

  factory NotificationSettingsResponse.fromJson(Map<String, Object?> json) =>
      _$NotificationSettingsResponseFromJson(json);

  final String? fridgeId;
  final dynamic warningDaysBefore;
  final dynamic dangerDaysBefore;
  final String? notificationTime;
  final String? recipientsScope;
  final List<String>? recipientUserIds;

  Map<String, Object?> toJson() => _$NotificationSettingsResponseToJson(this);
}
