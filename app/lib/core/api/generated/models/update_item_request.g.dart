// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateItemRequest _$UpdateItemRequestFromJson(Map<String, dynamic> json) =>
    UpdateItemRequest(
      containerId: json['containerId'] as String?,
      name: json['name'] as String,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
      categoryId: json['categoryId'] as String?,
      amount: json['amount'] as String?,
      unit: json['unit'] as String?,
      imageUrl: json['imageUrl'] as String?,
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$UpdateItemRequestToJson(UpdateItemRequest instance) =>
    <String, dynamic>{
      'containerId': instance.containerId,
      'name': instance.name,
      'categoryId': instance.categoryId,
      'amount': instance.amount,
      'unit': instance.unit,
      'imageUrl': instance.imageUrl,
      'expiryDate': instance.expiryDate?.toIso8601String(),
      'comment': instance.comment,
    };
