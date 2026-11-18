// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateItemRequest _$CreateItemRequestFromJson(Map<String, dynamic> json) =>
    CreateItemRequest(
      containerId: json['containerId'] as String?,
      productCatalogId: json['productCatalogId'] as String?,
      name: json['name'] as String?,
      categoryId: json['categoryId'] as String?,
      amount: json['amount'] as String?,
      unit: json['unit'] as String?,
      imageUrl: json['imageUrl'] as String?,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$CreateItemRequestToJson(CreateItemRequest instance) =>
    <String, dynamic>{
      'containerId': instance.containerId,
      'productCatalogId': instance.productCatalogId,
      'name': instance.name,
      'categoryId': instance.categoryId,
      'amount': instance.amount,
      'unit': instance.unit,
      'imageUrl': instance.imageUrl,
      'expiryDate': instance.expiryDate?.toIso8601String(),
      'comment': instance.comment,
    };
