// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'container_response.g.dart';

@JsonSerializable()
class ContainerResponse {
  const ContainerResponse({
    this.id,
    this.fridgeId,
    this.name,
    this.type,
    this.createdAt,
  });

  factory ContainerResponse.fromJson(Map<String, Object?> json) =>
      _$ContainerResponseFromJson(json);

  final String? id;
  final String? fridgeId;
  final String? name;
  final String? type;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$ContainerResponseToJson(this);
}
