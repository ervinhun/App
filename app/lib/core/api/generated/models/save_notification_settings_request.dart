// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'save_notification_settings_request.g.dart';

@JsonSerializable()
class SaveNotificationSettingsRequest {
  const SaveNotificationSettingsRequest({
    required this.recipientsScope,
    this.warningDaysBefore,
    this.dangerDaysBefore,
    this.notificationTime,
    this.recipientUserIds,
  });

  factory SaveNotificationSettingsRequest.fromJson(Map<String, Object?> json) =>
      _$SaveNotificationSettingsRequestFromJson(json);

  final dynamic warningDaysBefore;
  final dynamic dangerDaysBefore;
  final String? notificationTime;
  final String recipientsScope;
  final List<String>? recipientUserIds;

  Map<String, Object?> toJson() =>
      _$SaveNotificationSettingsRequestToJson(this);
}
