import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import 'generated/export.dart';

/// Sends the stored access token as a Bearer token. When the backend answers 401,
/// swaps the refresh token for a new pair (`POST /api/auth/refresh`) and retries
/// the request once. If the refresh token is rejected too, the stored tokens are
/// cleared and the 401 is passed on, so callers see the user as signed out.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._tokens);

  static const _refreshPath = '/api/auth/refresh';
  static const _skipAuth = 'authInterceptor.skip';
  static const _retried = 'authInterceptor.retried';

  final Dio _dio;
  final TokenStorage _tokens;

  /// The refresh in flight, shared by every request that got a 401 meanwhile:
  /// a refresh token works only once.
  Future<String?>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[_skipAuth] != true) {
      final token = await _tokens.read();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final sentToken = request.headers['Authorization'];
    if (err.response?.statusCode != 401 ||
        sentToken == null ||
        request.extra[_skipAuth] == true ||
        request.extra[_retried] == true) {
      return handler.next(err);
    }

    // Another request may have refreshed while this one was in flight.
    final stored = await _tokens.read();
    final accessToken = stored != null && 'Bearer $stored' != sentToken
        ? stored
        : await (_refreshing ??= _refresh().whenComplete(
            () => _refreshing = null,
          ));
    if (accessToken == null) return handler.next(err);

    request.extra[_retried] = true;
    try {
      handler.resolve(await _dio.fetch(request));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Returns the new access token, or null if the user has to sign in again.
  Future<String?> _refresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null) {
      await _tokens.clear();
      return null;
    }
    try {
      // Not through AuthClient: this request must skip the interceptor's own handling.
      final response = await _dio.post<Map<String, dynamic>>(
        _refreshPath,
        data: RefreshRequest(refreshToken: refreshToken).toJson(),
        options: Options(extra: {_skipAuth: true}),
      );
      final session = AuthResponse.fromJson(response.data!);
      await _tokens.write(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return session.accessToken;
    } on DioException catch (e) {
      // Only a rejected refresh token ends the sign-in; when offline, keep it for later.
      if (e.response?.statusCode == 401) await _tokens.clear();
      return null;
    }
  }
}
