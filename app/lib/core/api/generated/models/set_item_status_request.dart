// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'set_item_status_request.g.dart';

@JsonSerializable()
class SetItemStatusRequest {
  const SetItemStatusRequest({required this.status});

  factory SetItemStatusRequest.fromJson(Map<String, Object?> json) =>
      _$SetItemStatusRequestFromJson(json);

  final String status;

  Map<String, Object?> toJson() => _$SetItemStatusRequestToJson(this);
}
