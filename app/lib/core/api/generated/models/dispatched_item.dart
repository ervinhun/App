// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'dispatched_item.g.dart';

@JsonSerializable()
class DispatchedItem {
  const DispatchedItem({required this.stage, this.itemId});

  factory DispatchedItem.fromJson(Map<String, Object?> json) =>
      _$DispatchedItemFromJson(json);

  final String? itemId;
  final String stage;

  Map<String, Object?> toJson() => _$DispatchedItemToJson(this);
}
