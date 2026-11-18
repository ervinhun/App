// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_item_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationItemResponse _$NotificationItemResponseFromJson(
  Map<String, dynamic> json,
) => NotificationItemResponse(
  id: json['id'] as String?,
  expiryDate: json['expiryDate'] == null
      ? null
      : DateTime.parse(json['expiryDate'] as String),
  skipWarning: json['skipWarning'] as bool?,
);

Map<String, dynamic> _$NotificationItemResponseToJson(
  NotificationItemResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'expiryDate': instance.expiryDate?.toIso8601String(),
  'skipWarning': instance.skipWarning,
};
