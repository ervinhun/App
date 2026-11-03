// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_member_rights_request.g.dart';

@JsonSerializable()
class UpdateMemberRightsRequest {
  const UpdateMemberRightsRequest({
    this.canPut,
    this.canUse,
    this.accessExpiresAt,
  });

  factory UpdateMemberRightsRequest.fromJson(Map<String, Object?> json) =>
      _$UpdateMemberRightsRequestFromJson(json);

  final bool? canPut;
  final bool? canUse;
  final DateTime? accessExpiresAt;

  Map<String, Object?> toJson() => _$UpdateMemberRightsRequestToJson(this);
}
