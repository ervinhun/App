// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_item_request.dart';
import '../models/item_response.dart';
import '../models/set_item_status_request.dart';
import '../models/update_item_request.dart';

part 'items_client.g.dart';

@RestApi()
abstract class ItemsClient {
  factory ItemsClient(Dio dio, {String? baseUrl}) = _ItemsClient;

  @POST('/api/fridges/{fridgeId}/items')
  Future<ItemResponse> createItem({
    @Path('fridgeId') required String fridgeId,
    @Body() required CreateItemRequest body,
  });

  @GET('/api/fridges/{fridgeId}/items')
  Future<List<ItemResponse>> getItems({
    @Path('fridgeId') required String fridgeId,
    @Query('containerId') String? containerId,
    @Query('status') String? status,
  });

  @GET('/api/fridges/{fridgeId}/items/{itemId}')
  Future<ItemResponse> getItem({
    @Path('fridgeId') required String fridgeId,
    @Path('itemId') required String itemId,
  });

  @PUT('/api/fridges/{fridgeId}/items/{itemId}')
  Future<ItemResponse> updateItem({
    @Path('fridgeId') required String fridgeId,
    @Path('itemId') required String itemId,
    @Body() required UpdateItemRequest body,
  });

  @DELETE('/api/fridges/{fridgeId}/items/{itemId}')
  Future<void> deleteItem({
    @Path('fridgeId') required String fridgeId,
    @Path('itemId') required String itemId,
  });

  @PUT('/api/fridges/{fridgeId}/items/{itemId}/status')
  Future<ItemResponse> setItemStatus({
    @Path('fridgeId') required String fridgeId,
    @Path('itemId') required String itemId,
    @Body() required SetItemStatusRequest body,
  });
}
