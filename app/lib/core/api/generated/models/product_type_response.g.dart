// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_type_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductTypeResponse _$ProductTypeResponseFromJson(Map<String, dynamic> json) =>
    ProductTypeResponse(
      id: json['id'] as String?,
      categoryId: json['categoryId'] as String?,
      name: json['name'] as String?,
      defaultExpiryDays: json['defaultExpiryDays'],
      pantryExpiryDays: json['pantryExpiryDays'],
      fridgeExpiryDays: json['fridgeExpiryDays'],
      freezerExpiryDays: json['freezerExpiryDays'],
    );

Map<String, dynamic> _$ProductTypeResponseToJson(
  ProductTypeResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'categoryId': instance.categoryId,
  'name': instance.name,
  'defaultExpiryDays': instance.defaultExpiryDays,
  'pantryExpiryDays': instance.pantryExpiryDays,
  'fridgeExpiryDays': instance.fridgeExpiryDays,
  'freezerExpiryDays': instance.freezerExpiryDays,
};
