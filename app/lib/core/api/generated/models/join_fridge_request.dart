// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'join_fridge_request.g.dart';

@JsonSerializable()
class JoinFridgeRequest {
  const JoinFridgeRequest({required this.inviteCode});

  factory JoinFridgeRequest.fromJson(Map<String, Object?> json) =>
      _$JoinFridgeRequestFromJson(json);

  final String inviteCode;

  Map<String, Object?> toJson() => _$JoinFridgeRequestToJson(this);
}
