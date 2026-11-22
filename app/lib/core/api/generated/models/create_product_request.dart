// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'create_product_request.g.dart';

@JsonSerializable()
class CreateProductRequest {
  const CreateProductRequest({
    required this.barcode,
    required this.name,
    this.productTypeId,
    this.imageUrl,
  });

  factory CreateProductRequest.fromJson(Map<String, Object?> json) =>
      _$CreateProductRequestFromJson(json);

  final String barcode;
  final String name;
  final String? productTypeId;
  final String? imageUrl;

  Map<String, Object?> toJson() => _$CreateProductRequestToJson(this);
}
