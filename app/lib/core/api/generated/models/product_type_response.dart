// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'product_type_response.g.dart';

@JsonSerializable()
class ProductTypeResponse {
  const ProductTypeResponse({
    this.id,
    this.categoryId,
    this.name,
    this.defaultExpiryDays,
    this.pantryExpiryDays,
    this.fridgeExpiryDays,
    this.freezerExpiryDays,
  });

  factory ProductTypeResponse.fromJson(Map<String, Object?> json) =>
      _$ProductTypeResponseFromJson(json);

  final String? id;
  final String? categoryId;
  final String? name;
  final dynamic defaultExpiryDays;
  final dynamic pantryExpiryDays;
  final dynamic fridgeExpiryDays;
  final dynamic freezerExpiryDays;

  Map<String, Object?> toJson() => _$ProductTypeResponseToJson(this);
}
