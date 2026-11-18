// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_notification_settings_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveNotificationSettingsRequest _$SaveNotificationSettingsRequestFromJson(
  Map<String, dynamic> json,
) => SaveNotificationSettingsRequest(
  recipientsScope: json['recipientsScope'] as String,
  warningDaysBefore: json['warningDaysBefore'],
  dangerDaysBefore: json['dangerDaysBefore'],
  notificationTime: json['notificationTime'] as String?,
  recipientUserIds: (json['recipientUserIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$SaveNotificationSettingsRequestToJson(
  SaveNotificationSettingsRequest instance,
) => <String, dynamic>{
  'warningDaysBefore': instance.warningDaysBefore,
  'dangerDaysBefore': instance.dangerDaysBefore,
  'notificationTime': instance.notificationTime,
  'recipientsScope': instance.recipientsScope,
  'recipientUserIds': instance.recipientUserIds,
};
