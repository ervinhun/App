// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'notification_item_response.g.dart';

@JsonSerializable()
class NotificationItemResponse {
  const NotificationItemResponse({this.id, this.expiryDate, this.skipWarning});

  factory NotificationItemResponse.fromJson(Map<String, Object?> json) =>
      _$NotificationItemResponseFromJson(json);

  final String? id;
  final DateTime? expiryDate;
  final bool? skipWarning;

  Map<String, Object?> toJson() => _$NotificationItemResponseToJson(this);
}
