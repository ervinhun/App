// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispatched_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DispatchedItem _$DispatchedItemFromJson(Map<String, dynamic> json) =>
    DispatchedItem(
      stage: json['stage'] as String,
      itemId: json['itemId'] as String?,
    );

Map<String, dynamic> _$DispatchedItemToJson(DispatchedItem instance) =>
    <String, dynamic>{'itemId': instance.itemId, 'stage': instance.stage};
