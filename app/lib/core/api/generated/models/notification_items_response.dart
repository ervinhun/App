// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'notification_item_response.dart';

part 'notification_items_response.g.dart';

@JsonSerializable()
class NotificationItemsResponse {
  const NotificationItemsResponse({
    this.fridgeId,
    this.warningDaysBefore,
    this.dangerDaysBefore,
    this.notificationTime,
    this.items,
  });

  factory NotificationItemsResponse.fromJson(Map<String, Object?> json) =>
      _$NotificationItemsResponseFromJson(json);

  final String? fridgeId;
  final dynamic warningDaysBefore;
  final dynamic dangerDaysBefore;
  final String? notificationTime;
  final List<NotificationItemResponse>? items;

  Map<String, Object?> toJson() => _$NotificationItemsResponseToJson(this);
}
