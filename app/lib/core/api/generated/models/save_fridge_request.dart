// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'save_fridge_request.g.dart';

@JsonSerializable()
class SaveFridgeRequest {
  const SaveFridgeRequest({required this.name});

  factory SaveFridgeRequest.fromJson(Map<String, Object?> json) =>
      _$SaveFridgeRequestFromJson(json);

  final String name;

  Map<String, Object?> toJson() => _$SaveFridgeRequestToJson(this);
}
