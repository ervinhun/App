// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'create_item_request.g.dart';

@JsonSerializable()
class CreateItemRequest {
  const CreateItemRequest({
    required this.containerId,
    this.productCatalogId,
    this.name,
    this.categoryId,
    this.amount,
    this.unit,
    this.imageUrl,
    this.expiryDate,
    this.comment,
  });

  factory CreateItemRequest.fromJson(Map<String, Object?> json) =>
      _$CreateItemRequestFromJson(json);

  final String? containerId;
  final String? productCatalogId;
  final String? name;
  final String? categoryId;
  final String? amount;
  final String? unit;
  final String? imageUrl;
  final DateTime? expiryDate;
  final String? comment;

  Map<String, Object?> toJson() => _$CreateItemRequestToJson(this);
}
