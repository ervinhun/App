// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'fridge_member_response.g.dart';

@JsonSerializable()
class FridgeMemberResponse {
  const FridgeMemberResponse({
    this.userId,
    this.displayName,
    this.isOwner,
    this.canPut,
    this.canUse,
    this.accessExpiresAt,
    this.joinedAt,
  });

  factory FridgeMemberResponse.fromJson(Map<String, Object?> json) =>
      _$FridgeMemberResponseFromJson(json);

  final String? userId;
  final String? displayName;
  final bool? isOwner;
  final bool? canPut;
  final bool? canUse;
  final DateTime? accessExpiresAt;
  final DateTime? joinedAt;

  Map<String, Object?> toJson() => _$FridgeMemberResponseToJson(this);
}
