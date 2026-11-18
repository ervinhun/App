// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'item_response.g.dart';

@JsonSerializable()
class ItemResponse {
  const ItemResponse({
    this.id,
    this.containerId,
    this.productCatalogId,
    this.name,
    this.categoryId,
    this.amount,
    this.unit,
    this.imageUrl,
    this.addedByUserId,
    this.addedAt,
    this.expiryDate,
    this.comment,
    this.status,
    this.createdAt,
  });

  factory ItemResponse.fromJson(Map<String, Object?> json) =>
      _$ItemResponseFromJson(json);

  final String? id;
  final String? containerId;
  final String? productCatalogId;
  final String? name;
  final String? categoryId;
  final String? amount;
  final String? unit;
  final String? imageUrl;
  final String? addedByUserId;
  final DateTime? addedAt;
  final DateTime? expiryDate;
  final String? comment;
  final String? status;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$ItemResponseToJson(this);
}
