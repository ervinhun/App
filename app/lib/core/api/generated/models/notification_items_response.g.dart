// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_items_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationItemsResponse _$NotificationItemsResponseFromJson(
  Map<String, dynamic> json,
) => NotificationItemsResponse(
  fridgeId: json['fridgeId'] as String?,
  warningDaysBefore: json['warningDaysBefore'],
  dangerDaysBefore: json['dangerDaysBefore'],
  notificationTime: json['notificationTime'] as String?,
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => NotificationItemResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$NotificationItemsResponseToJson(
  NotificationItemsResponse instance,
) => <String, dynamic>{
  'fridgeId': instance.fridgeId,
  'warningDaysBefore': instance.warningDaysBefore,
  'dangerDaysBefore': instance.dangerDaysBefore,
  'notificationTime': instance.notificationTime,
  'items': instance.items,
};
