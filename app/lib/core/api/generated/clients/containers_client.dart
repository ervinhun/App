// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/container_response.dart';
import '../models/save_container_request.dart';

part 'containers_client.g.dart';

@RestApi()
abstract class ContainersClient {
  factory ContainersClient(Dio dio, {String? baseUrl}) = _ContainersClient;

  @POST('/api/fridges/{fridgeId}/containers')
  Future<ContainerResponse> createContainer({
    @Path('fridgeId') required String fridgeId,
    @Body() required SaveContainerRequest body,
  });

  @GET('/api/fridges/{fridgeId}/containers')
  Future<List<ContainerResponse>> getContainers({
    @Path('fridgeId') required String fridgeId,
  });

  @GET('/api/fridges/{fridgeId}/containers/{containerId}')
  Future<ContainerResponse> getContainer({
    @Path('fridgeId') required String fridgeId,
    @Path('containerId') required String containerId,
  });

  @PUT('/api/fridges/{fridgeId}/containers/{containerId}')
  Future<ContainerResponse> updateContainer({
    @Path('fridgeId') required String fridgeId,
    @Path('containerId') required String containerId,
    @Body() required SaveContainerRequest body,
  });

  @DELETE('/api/fridges/{fridgeId}/containers/{containerId}')
  Future<void> deleteContainer({
    @Path('fridgeId') required String fridgeId,
    @Path('containerId') required String containerId,
  });
}
