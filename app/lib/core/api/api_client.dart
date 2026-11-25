import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_config.dart';
import 'package:app/core/api/auth_interceptor.dart';
import 'package:app/core/api/generated/export.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';

Dio _backendDio() => Dio(
  BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ),
);

/// Dio for the FridgeFriend backend. See [AuthInterceptor] for how it handles
/// the access token.
final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  final dio = _backendDio();
  dio.interceptors.add(
    AuthInterceptor(
      dio,
      tokens,
      onSessionEnded: () =>
          ref.read(authControllerProvider.notifier).endSession(),
    ),
  );
  return dio;
});

/// The backend's `/api/auth` endpoints, generated from its OpenAPI document.
final authClientProvider = Provider<AuthClient>(
  (ref) => AuthClient(ref.watch(dioProvider)),
);

/// [AuthClient] for signing in, which sends no access token: a 401 there means
/// wrong credentials, not an expired session. The generated client can't mark
/// a request with [skipAuth], so it gets a Dio without [AuthInterceptor].
final signInClientProvider = Provider<AuthClient>(
  (ref) => AuthClient(_backendDio()),
);

/// Awaits a generated client call, turning a failed request into an [ApiException].
Future<T> apiCall<T>(Future<T> request) async {
  try {
    return await request;
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}

/// A failed backend call, with a message that is safe to show to the user.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  /// Reads the backend's ProblemDetails body (`detail`, `title`, or the first
  /// validation error) when there is one.
  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return ApiException('${first.first}', statusCode: status);
        }
      }
      final message = data['detail'] ?? data['title'];
      if (message is String && message.isNotEmpty) {
        return ApiException(message, statusCode: status);
      }
    }
    if (status == null) {
      return ApiException(
        "Can't reach the server. Check your connection and try again.",
      );
    }
    return ApiException('Something went wrong ($status).', statusCode: status);
  }

  /// What to tell the user about [error]. Only an [ApiException] has a message
  /// that is safe to show.
  static String messageFor(Object? error) => error is ApiException
      ? error.message
      : 'Something went wrong. Please try again.';

  @override
  String toString() => message;
}
