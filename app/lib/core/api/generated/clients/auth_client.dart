// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auth_response.dart';
import '../models/external_login_request.dart';
import '../models/login_request.dart';
import '../models/refresh_request.dart';
import '../models/register_request.dart';
import '../models/user_dto.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  @POST('/api/Auth/Register')
  Future<AuthResponse> register({@Body() required RegisterRequest body});

  @POST('/api/Auth/Login')
  Future<AuthResponse> login({@Body() required LoginRequest body});

  @POST('/api/Auth/External')
  Future<AuthResponse> externalLogin({
    @Body() required ExternalLoginRequest body,
  });

  @GET('/api/Auth/Me')
  Future<UserDto> me();

  @POST('/api/Auth/Refresh')
  Future<AuthResponse> refresh({@Body() required RefreshRequest body});

  @POST('/api/Auth/Logout')
  Future<void> logout();
}
