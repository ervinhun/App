import 'package:dio/dio.dart';

import 'package:app/core/auth/token_storage.dart';

/// Set in a request's `extra` to send it without the access token, for endpoints
/// that don't take one. A 401 from those says nothing about the session.
const skipAuth = 'auth.skip';

/// Sends the stored access token as a Bearer token. When the backend rejects it,
/// swaps it using the refresh token and retries the request once.
///
/// The session only ends when the backend rejects the refresh token or the new
/// access token. If the refresh fails any other way, such as no connection, the
/// tokens are kept and the caller gets that error.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._tokens, {required this.onSessionEnded});

  static const _retried = 'auth.retried';

  final Dio _dio;
  final TokenStorage _tokens;
  final Future<void> Function() onSessionEnded;

  /// Shared by parallel requests: refresh tokens are single use, so a second
  /// refresh with the same one would be rejected and end the session.
  Future<bool>? _refreshing;

  /// The latest refresh, for requests whose 401 arrives after it finished.
  ({String from, String to})? _lastSwap;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuth] != true) {
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
    final sent = err.requestOptions.headers['Authorization'];
    if (err.response?.statusCode != 401 || sent == null) {
      handler.next(err);
      return;
    }

    try {
      if (await _canRetry(err.requestOptions, sent)) {
        err.requestOptions.extra[_retried] = true;
        handler.resolve(await _dio.fetch<dynamic>(err.requestOptions));
      } else {
        handler.next(err);
      }
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      // Storage or sign-out failed: still finish the request, and report it.
      handler.next(err);
      rethrow;
    }
  }

  /// Whether there is a newer access token worth retrying [options] with.
  Future<bool> _canRetry(RequestOptions options, Object sent) async {
    final current = await _tokens.read();
    final sentCurrent = current != null && sent == 'Bearer $current';

    if (options.extra[_retried] == true) {
      // Even a new token was rejected, so the session or account is gone.
      if (sentCurrent) await onSessionEnded();
      return false;
    }

    final swap = _lastSwap;
    if (swap != null && sent == 'Bearer ${swap.from}' && current == swap.to) {
      return true;
    }

    // A late response for an older session must not end or refresh a newer one.
    if (!sentCurrent) return false;

    return _refreshing ??= _refresh(current)
        .whenComplete(() => _refreshing = null);
  }

  /// Returns true if [accessToken] was replaced. Throws [DioException] if the
  /// refresh failed without the backend rejecting the refresh token.
  Future<bool> _refresh(String accessToken) async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null) {
      await onSessionEnded();
      return false;
    }

    final Map<String, dynamic> session;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {skipAuth: true}),
      );
      session = response.data!;
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) rethrow;
      if (await _tokens.readRefreshToken() == refreshToken) {
        await onSessionEnded();
      }
      return false;
    }

    // The user signed out or started another session during the refresh, so
    // saving these tokens would undo that.
    if (await _tokens.readRefreshToken() != refreshToken) return false;

    final newAccessToken = session['accessToken'] as String;
    await _tokens.write(
      accessToken: newAccessToken,
      refreshToken: session['refreshToken'] as String,
    );
    _lastSwap = (from: accessToken, to: newAccessToken);
    return true;
  }
}
