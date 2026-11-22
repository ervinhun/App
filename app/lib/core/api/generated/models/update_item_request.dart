// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_item_request.g.dart';

@JsonSerializable()
class UpdateItemRequest {
  const UpdateItemRequest({
    required this.containerId,
    required this.name,
    required this.expiryDate,
    this.categoryId,
    this.amount,
    this.unit,
    this.imageUrl,
    this.comment,
  });

  factory UpdateItemRequest.fromJson(Map<String, Object?> json) =>
      _$UpdateItemRequestFromJson(json);

  final String? containerId;
  final String name;
  final String? categoryId;
  final String? amount;
  final String? unit;
  final String? imageUrl;
  final DateTime? expiryDate;
  final String? comment;

  Map<String, Object?> toJson() => _$UpdateItemRequestToJson(this);
}
