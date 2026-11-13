// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'fridge_response.g.dart';

@JsonSerializable()
class FridgeResponse {
  const FridgeResponse({
    this.id,
    this.name,
    this.inviteCode,
    this.maxMembers,
    this.maxContainers,
    this.memberCount,
    this.isOwner,
    this.canPut,
    this.canUse,
    this.createdAt,
  });

  factory FridgeResponse.fromJson(Map<String, Object?> json) =>
      _$FridgeResponseFromJson(json);

  final String? id;
  final String? name;
  final String? inviteCode;
  final dynamic maxMembers;
  final dynamic maxContainers;
  final dynamic memberCount;
  final bool? isOwner;
  final bool? canPut;
  final bool? canUse;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$FridgeResponseToJson(this);
}
