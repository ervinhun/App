import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/auth_user.dart';

/// The backend's `/api/auth` endpoints. Throws [ApiException] on failure.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthSession> login(String email, String password) =>
      _session('/api/auth/login', {'email': email, 'password': password});

  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  }) => _session('/api/auth/register', {
    'email': email,
    'password': password,
    'displayName': displayName,
  });

  /// Exchanges a Google or Apple ID token for our own access token.
  /// [displayName] only matters when this sign-in creates the account.
  Future<AuthSession> external({
    required String provider,
    required String idToken,
    String? displayName,
  }) => _session('/api/auth/external', {
    'provider': provider,
    'idToken': idToken,
    'displayName': ?displayName,
  });

  /// Ends this session on the backend: its access and refresh tokens stop working.
  Future<void> logout() async {
    try {
      await _dio.post<void>('/api/auth/logout');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AuthUser> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/auth/me');
      return AuthUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AuthSession> _session(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        // Stored on the backend's session, e.g. to list signed-in devices.
        data: {...body, 'platform': defaultTargetPlatform.name.toLowerCase()},
      );
      return AuthSession.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioProvider)),
);
