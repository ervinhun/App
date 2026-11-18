// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemResponse _$ItemResponseFromJson(Map<String, dynamic> json) => ItemResponse(
  id: json['id'] as String?,
  containerId: json['containerId'] as String?,
  productCatalogId: json['productCatalogId'] as String?,
  name: json['name'] as String?,
  categoryId: json['categoryId'] as String?,
  amount: json['amount'] as String?,
  unit: json['unit'] as String?,
  imageUrl: json['imageUrl'] as String?,
  addedByUserId: json['addedByUserId'] as String?,
  addedAt: json['addedAt'] == null
      ? null
      : DateTime.parse(json['addedAt'] as String),
  expiryDate: json['expiryDate'] == null
      ? null
      : DateTime.parse(json['expiryDate'] as String),
  comment: json['comment'] as String?,
  status: json['status'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ItemResponseToJson(ItemResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'containerId': instance.containerId,
      'productCatalogId': instance.productCatalogId,
      'name': instance.name,
      'categoryId': instance.categoryId,
      'amount': instance.amount,
      'unit': instance.unit,
      'imageUrl': instance.imageUrl,
      'addedByUserId': instance.addedByUserId,
      'addedAt': instance.addedAt?.toIso8601String(),
      'expiryDate': instance.expiryDate?.toIso8601String(),
      'comment': instance.comment,
      'status': instance.status,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
