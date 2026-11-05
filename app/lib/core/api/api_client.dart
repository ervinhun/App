import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/core/api/api_config.dart';
import 'package:app/core/api/auth_interceptor.dart';

/// Dio for the FridgeFriend backend. See [AuthInterceptor] for how it handles
/// the access token.
final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(
      dio,
      tokens,
      onSessionEnded: () => ref.read(authControllerProvider.notifier).signOut(),
    ),
  );
  return dio;
});

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

  @override
  String toString() => message;
}
