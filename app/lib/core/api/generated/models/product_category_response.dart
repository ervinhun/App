// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'product_category_response.g.dart';

@JsonSerializable()
class ProductCategoryResponse {
  const ProductCategoryResponse({this.id, this.name});

  factory ProductCategoryResponse.fromJson(Map<String, Object?> json) =>
      _$ProductCategoryResponseFromJson(json);

  final String? id;
  final String? name;

  Map<String, Object?> toJson() => _$ProductCategoryResponseToJson(this);
}
