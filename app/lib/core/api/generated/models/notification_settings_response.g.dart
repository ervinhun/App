// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationSettingsResponse _$NotificationSettingsResponseFromJson(
  Map<String, dynamic> json,
) => NotificationSettingsResponse(
  fridgeId: json['fridgeId'] as String?,
  warningDaysBefore: json['warningDaysBefore'],
  dangerDaysBefore: json['dangerDaysBefore'],
  notificationTime: json['notificationTime'] as String?,
  recipientsScope: json['recipientsScope'] as String?,
  recipientUserIds: (json['recipientUserIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$NotificationSettingsResponseToJson(
  NotificationSettingsResponse instance,
) => <String, dynamic>{
  'fridgeId': instance.fridgeId,
  'warningDaysBefore': instance.warningDaysBefore,
  'dangerDaysBefore': instance.dangerDaysBefore,
  'notificationTime': instance.notificationTime,
  'recipientsScope': instance.recipientsScope,
  'recipientUserIds': instance.recipientUserIds,
};
