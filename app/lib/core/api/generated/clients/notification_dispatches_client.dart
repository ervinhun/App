// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/report_dispatches_request.dart';

part 'notification_dispatches_client.g.dart';

@RestApi()
abstract class NotificationDispatchesClient {
  factory NotificationDispatchesClient(Dio dio, {String? baseUrl}) =
      _NotificationDispatchesClient;

  @POST('/api/fridges/{fridgeId}/notification-dispatches')
  Future<void> reportDispatches({
    @Path('fridgeId') required String fridgeId,
    @Body() required ReportDispatchesRequest body,
  });
}
