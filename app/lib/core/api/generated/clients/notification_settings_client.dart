// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/notification_settings_response.dart';
import '../models/save_notification_settings_request.dart';

part 'notification_settings_client.g.dart';

@RestApi()
abstract class NotificationSettingsClient {
  factory NotificationSettingsClient(Dio dio, {String? baseUrl}) =
      _NotificationSettingsClient;

  /// null.
  ///
  /// The name has been replaced because it contains a keyword. Original name: `get`.
  @GET('/api/fridges/{fridgeId}/notification-settings')
  Future<NotificationSettingsResponse>
  getApiFridgesFridgeIdNotificationSettings({
    @Path('fridgeId') required String fridgeId,
  });

  @PUT('/api/fridges/{fridgeId}/notification-settings')
  Future<NotificationSettingsResponse> update({
    @Path('fridgeId') required String fridgeId,
    @Body() required SaveNotificationSettingsRequest body,
  });
}
