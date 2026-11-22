// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductResponse _$ProductResponseFromJson(Map<String, dynamic> json) =>
    ProductResponse(
      id: json['id'] as String?,
      barcode: json['barcode'] as String?,
      name: json['name'] as String?,
      productTypeId: json['productTypeId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      source: json['source'] as String?,
    );

Map<String, dynamic> _$ProductResponseToJson(ProductResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'barcode': instance.barcode,
      'name': instance.name,
      'productTypeId': instance.productTypeId,
      'imageUrl': instance.imageUrl,
      'source': instance.source,
    };
