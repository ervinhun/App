// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'product_response.g.dart';

@JsonSerializable()
class ProductResponse {
  const ProductResponse({
    this.id,
    this.barcode,
    this.name,
    this.productTypeId,
    this.imageUrl,
    this.source,
  });

  factory ProductResponse.fromJson(Map<String, Object?> json) =>
      _$ProductResponseFromJson(json);

  final String? id;
  final String? barcode;
  final String? name;
  final String? productTypeId;
  final String? imageUrl;
  final String? source;

  Map<String, Object?> toJson() => _$ProductResponseToJson(this);
}
