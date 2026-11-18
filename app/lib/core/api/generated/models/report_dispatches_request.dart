// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dispatched_item.dart';

part 'report_dispatches_request.g.dart';

@JsonSerializable()
class ReportDispatchesRequest {
  const ReportDispatchesRequest({required this.sentAt, required this.items});

  factory ReportDispatchesRequest.fromJson(Map<String, Object?> json) =>
      _$ReportDispatchesRequestFromJson(json);

  final DateTime? sentAt;
  final List<DispatchedItem> items;

  Map<String, Object?> toJson() => _$ReportDispatchesRequestToJson(this);
}
