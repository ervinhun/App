// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/fridge_member_response.dart';
import '../models/fridge_response.dart';
import '../models/join_fridge_request.dart';
import '../models/save_fridge_request.dart';
import '../models/update_member_rights_request.dart';

part 'fridges_client.g.dart';

@RestApi()
abstract class FridgesClient {
  factory FridgesClient(Dio dio, {String? baseUrl}) = _FridgesClient;

  @POST('/api/fridges')
  Future<FridgeResponse> create({@Body() required SaveFridgeRequest body});

  @GET('/api/fridges')
  Future<List<FridgeResponse>> getMine();

  @POST('/api/fridges/Join')
  Future<FridgeResponse> join({@Body() required JoinFridgeRequest body});

  /// null.
  ///
  /// The name has been replaced because it contains a keyword. Original name: `get`.
  @GET('/api/fridges/{id}')
  Future<FridgeResponse> getApiFridgesId({@Path('id') required String id});

  @PUT('/api/fridges/{id}')
  Future<FridgeResponse> update({
    @Path('id') required String id,
    @Body() required SaveFridgeRequest body,
  });

  @DELETE('/api/fridges/{id}')
  Future<void> delete({@Path('id') required String id});

  @POST('/api/fridges/{id}/RegenerateInviteCode')
  Future<FridgeResponse> regenerateInviteCode({@Path('id') required String id});

  @GET('/api/fridges/{id}/members')
  Future<List<FridgeMemberResponse>> getMembers({
    @Path('id') required String id,
  });

  @PUT('/api/fridges/{id}/members/{userId}')
  Future<FridgeMemberResponse> updateMemberRights({
    @Path('id') required String id,
    @Path('userId') required String userId,
    @Body() required UpdateMemberRightsRequest body,
  });

  @DELETE('/api/fridges/{id}/members/{userId}')
  Future<void> removeMember({
    @Path('id') required String id,
    @Path('userId') required String userId,
  });
}
