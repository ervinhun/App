// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/notification_items_response.dart';

part 'notification_items_client.g.dart';

@RestApi()
abstract class NotificationItemsClient {
  factory NotificationItemsClient(Dio dio, {String? baseUrl}) =
      _NotificationItemsClient;

  @GET('/api/fridges/{fridgeId}/notification-items')
  Future<NotificationItemsResponse> getNotificationItems({
    @Path('fridgeId') required String fridgeId,
  });
}
