// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_product_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateProductRequest _$CreateProductRequestFromJson(
  Map<String, dynamic> json,
) => CreateProductRequest(
  barcode: json['barcode'] as String,
  name: json['name'] as String,
  productTypeId: json['productTypeId'] as String?,
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$CreateProductRequestToJson(
  CreateProductRequest instance,
) => <String, dynamic>{
  'barcode': instance.barcode,
  'name': instance.name,
  'productTypeId': instance.productTypeId,
  'imageUrl': instance.imageUrl,
};
