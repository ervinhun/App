import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/generated/export.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/auth/fakes.dart';

const _fridges = '/api/fridges';
const _slow = '/api/slow';

const _annaJson = {
  'id': '00000000-0000-0000-0000-000000000001',
  'email': 'anna@example.com',
  'displayName': 'Anna',
  'locale': 'en',
};

/// Behaves like the backend: accepts one access token at a time, and each
/// refresh token only once.
class _FakeBackend implements HttpClientAdapter {
  var access = 'jwt-0';
  var refresh = 'refresh-0';
  var _issued = 0;

  int refreshCalls = 0;
  int logoutCalls = 0;

  /// The refresh endpoint fails this way instead of answering.
  int? refreshStatus;
  bool refreshOffline = false;

  /// Issues new tokens as usual, but never accepts them.
  bool rejectNewTokens = false;

  /// Answers refreshes with a body that has no tokens.
  bool malformedRefresh = false;

  /// What non-auth endpoints answer with a valid token.
  int status = 200;
  int loginStatus = 200;

  /// The Authorization header of the last login.
  String? loginAuthorization;

  void Function()? duringRequest;
  void Function()? duringRefresh;

  /// Holds requests to [_slow] until completed.
  final slowGate = Completer<void>();

  void expireAccessToken() => access = 'nothing-matches-this';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(Duration.zero);
    final authorization = options.headers['Authorization'];
    // Routes are case-insensitive on the backend, and the generated client
    // capitalizes them.
    final path = options.path.toLowerCase();

    if (path == '/api/auth/refresh') return _refresh(options);
    if (path == '/api/auth/login') {
      loginAuthorization = authorization as String?;
      return loginStatus == 200
          ? _json(200, _session('login-jwt', 'login-refresh'))
          : _json(loginStatus, const {});
    }

    duringRequest?.call();
    if (options.path == _slow) await slowGate.future;

    if (authorization != 'Bearer $access') return _json(401, const {});
    if (path == '/api/auth/logout') {
      logoutCalls++;
      return ResponseBody.fromString('', 204);
    }
    return path == '/api/auth/me'
        ? _json(200, _annaJson)
        : _json(status, const {});
  }

  ResponseBody _refresh(RequestOptions options) {
    refreshCalls++;
    duringRefresh?.call();
    if (refreshOffline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    if (refreshStatus != null) return _json(refreshStatus!, const {});
    if (malformedRefresh) return _json(200, const {});
    if ((options.data as Map)['refreshToken'] != refresh) {
      return _json(401, const {});
    }

    _issued++;
    final newAccess = 'jwt-$_issued';
    refresh = 'refresh-$_issued';
    if (!rejectNewTokens) access = newAccess;
    return _json(200, _session(newAccess, refresh));
  }

  Map<String, dynamic> _session(String accessToken, String refreshToken) => {
    'accessToken': accessToken,
    'expiresAt': '2030-01-01T00:00:00Z',
    'refreshToken': refreshToken,
    'refreshTokenExpiresAt': '2030-01-01T00:00:00Z',
    'user': _annaJson,
  };

  ResponseBody _json(int status, Map<String, dynamic> body) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeTokenStorage tokens;
  late FakeGoogleAuth google;
  late _FakeBackend backend;

  setUp(() {
    backend = _FakeBackend();
    google = FakeGoogleAuth();
    tokens = FakeTokenStorage(backend.access)..refreshToken = backend.refresh;
  });

  ProviderContainer container({Duration? Function(int, Object)? retry}) {
    final c = ProviderContainer.test(
      retry: retry,
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        googleAuthProvider.overrideWithValue(google),
        signInClientProvider.overrideWithValue(
          AuthClient(Dio()..httpClientAdapter = backend),
        ),
      ],
    );
    c.read(dioProvider).httpClientAdapter = backend;
    return c;
  }

  /// A container whose app has finished its startup token check. Listens like
  /// the router does, since providers only rebuild while listened to.
  Future<ProviderContainer> started() async {
    final c = container();
    c.listen(authControllerProvider, (_, _) {});
    await c.read(authControllerProvider.future);
    return c;
  }

  String? signedInId(ProviderContainer c) =>
      c.read(authControllerProvider).value?.id;

  Matcher hasStatus(int? status) => isA<DioException>().having(
    (e) => e.response?.statusCode,
    'statusCode',
    status,
  );

  void expectSignedOut(ProviderContainer c) {
    expect(tokens.token, isNull);
    expect(tokens.refreshToken, isNull);
    expect(signedInId(c), isNull);
  }

  group('refreshing an expired access token', () {
    test('retries the request with the new tokens', () async {
      final c = await started();
      backend.expireAccessToken();

      final response = await c.read(dioProvider).get<void>(_fridges);

      expect(response.statusCode, 200);
      expect(backend.refreshCalls, 1);
      expect(tokens.token, backend.access);
      expect(tokens.refreshToken, backend.refresh);
      expect(signedInId(c), anna.id);
    });

    test('parallel requests share one refresh', () async {
      final c = await started();
      backend.expireAccessToken();

      final dio = c.read(dioProvider);
      await Future.wait([
        dio.get<void>(_fridges),
        dio.get<void>(_fridges),
        dio.get<void>(_fridges),
      ]);

      expect(backend.refreshCalls, 1);
      expect(signedInId(c), anna.id);
    });

    test('a 401 arriving after the refresh just retries', () async {
      final c = await started();
      backend.expireAccessToken();

      final dio = c.read(dioProvider);
      final slow = dio.get<void>(_slow);
      await dio.get<void>(_fridges);
      backend.slowGate.complete();

      expect((await slow).statusCode, 200);
      expect(backend.refreshCalls, 1);
    });

    test('at startup restores the user', () async {
      tokens.token = 'expired-jwt';

      final c = await started();

      expect(signedInId(c), anna.id);
      expect(tokens.token, backend.access);
    });
  });

  group('the session ends when', () {
    Future<void> expectRequestSignsOut(ProviderContainer c) async {
      await expectLater(
        c.read(dioProvider).get<void>(_fridges),
        throwsA(hasStatus(401)),
      );
      expectSignedOut(c);
      expect(google.signedOut, isTrue);
      // The backend already ended the session, and a logout sent from inside
      // the refresh would wait for that refresh forever.
      expect(backend.logoutCalls, 0);
    }

    test('the refresh token is rejected', () async {
      final c = await started();
      backend.expireAccessToken();
      backend.refresh = 'not-the-stored-one';

      await expectRequestSignsOut(c);
    });

    test('there is no refresh token, as on older installs', () async {
      final c = await started();
      backend.expireAccessToken();
      tokens.refreshToken = null;

      await expectRequestSignsOut(c);
      expect(backend.refreshCalls, 0);
    });

    test('the new token is rejected too, without looping', () async {
      final c = await started();
      backend.expireAccessToken();
      backend.rejectNewTokens = true;

      await expectRequestSignsOut(c);
      expect(backend.refreshCalls, 1);
    });

    test('the refresh token is rejected at startup', () async {
      tokens.token = 'expired-jwt';
      backend.refresh = 'not-the-stored-one';

      expectSignedOut(await started());
    });
  });

  group('the caller gets the real error when', () {
    Matcher causedBy<T>() =>
        isA<DioException>().having((e) => e.error, 'error', isA<T>());

    test('secure storage fails during a refresh', () async {
      tokens = _BrokenRefreshTokenStorage(backend.access);
      final c = await started();
      backend.expireAccessToken();

      await expectLater(
        c.read(dioProvider).get<void>(_fridges),
        throwsA(causedBy<StateError>()),
      );
      expect(backend.refreshCalls, 0);
    });

    test('the refresh response has no tokens', () async {
      final c = await started();
      backend.expireAccessToken();
      backend.malformedRefresh = true;
      final staleAccess = tokens.token;

      await expectLater(
        c.read(dioProvider).get<void>(_fridges),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.badResponse)
              .having((e) => e.response?.statusCode, 'statusCode', 200),
        ),
      );
      expect(tokens.token, staleAccess);
      expect(signedInId(c), anna.id);
    });

    test('the refresh response has no tokens at startup', () async {
      tokens.token = 'expired-jwt';
      backend.malformedRefresh = true;

      await expectLater(
        container(retry: (_, _) => null).read(authControllerProvider.future),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            isNot(contains("Can't reach the server")),
          ),
        ),
      );
      expect(tokens.refreshToken, isNotNull);
    });
  });

  group('the session survives', () {
    test('having no connection during a refresh, and recovers', () async {
      final c = await started();
      backend.expireAccessToken();
      backend.refreshOffline = true;
      final staleAccess = tokens.token;
      final staleRefresh = tokens.refreshToken;

      await expectLater(
        c.read(dioProvider).get<void>(_fridges),
        throwsA(hasStatus(null)),
      );
      expect(tokens.token, staleAccess);
      expect(tokens.refreshToken, staleRefresh);
      expect(signedInId(c), anna.id);

      backend.refreshOffline = false;
      expect((await c.read(dioProvider).get<void>(_fridges)).statusCode, 200);
    });

    test('a server error during a refresh', () async {
      final c = await started();
      backend.expireAccessToken();
      backend.refreshStatus = 503;

      await expectLater(
        c.read(dioProvider).get<void>(_fridges),
        throwsA(hasStatus(503)),
      );
      expect(tokens.refreshToken, isNotNull);
      expect(signedInId(c), anna.id);
    });

    test('having no connection during a refresh at startup', () async {
      tokens.token = 'expired-jwt';
      backend.refreshOffline = true;

      await expectLater(
        container(retry: (_, _) => null).read(authControllerProvider.future),
        throwsA(isA<ApiException>()),
      );
      expect(tokens.token, 'expired-jwt');
      expect(tokens.refreshToken, isNotNull);
    });

    test('startup retrying until the connection is back', () async {
      tokens.token = 'expired-jwt';
      backend.duringRefresh = () =>
          backend.refreshOffline = backend.refreshCalls == 1;

      final c = await started();

      expect(backend.refreshCalls, 2);
      expect(signedInId(c), anna.id);
    });

    test('other errors', () async {
      final c = await started();
      backend.status = 500;

      await expectLater(
        c.read(dioProvider).get<void>(_fridges),
        throwsA(hasStatus(500)),
      );
      expect(backend.refreshCalls, 0);
      expect(signedInId(c), anna.id);
    });
  });

  test('signing out during a refresh is not undone', () async {
    final c = await started();
    backend.expireAccessToken();
    Future<void>? signingOut;
    backend.duringRefresh = () =>
        signingOut ??= c.read(authControllerProvider.notifier).signOut();

    await c.read(dioProvider).get<void>(_fridges);
    await signingOut;

    // The logout waited for the refresh, so it ended the refreshed session.
    expect(backend.logoutCalls, 1);
    expectSignedOut(c);
  });

  test('a late 401 for an older session keeps the newer one', () async {
    final c = await started();
    backend.expireAccessToken();
    backend.duringRequest = () {
      tokens.token = 'new-jwt';
      tokens.refreshToken = 'new-refresh';
    };

    await expectLater(
      c.read(dioProvider).get<void>(_fridges),
      throwsA(hasStatus(401)),
    );

    expect(backend.refreshCalls, 0);
    expect(tokens.token, 'new-jwt');
    expect(signedInId(c), anna.id);
  });

  group('signing in', () {
    test('stores both tokens', () async {
      tokens = FakeTokenStorage();
      final c = await started();

      await c
          .read(authControllerProvider.notifier)
          .signInWithPassword('anna@example.com', 'password');

      expect(tokens.token, 'login-jwt');
      expect(tokens.refreshToken, 'login-refresh');
      expect(signedInId(c), anna.id);
    });

    test('with a wrong password leaves stored tokens alone', () async {
      final c = await started();
      final access = tokens.token;
      backend.loginStatus = 401;

      await expectLater(
        c
            .read(authControllerProvider.notifier)
            .signInWithPassword('anna@example.com', 'wrong'),
        throwsA(isA<ApiException>()),
      );

      expect(backend.loginAuthorization, isNull);
      expect(backend.refreshCalls, 0);
      expect(tokens.token, access);
      expect(google.signedOut, isFalse);
    });
  });
}

/// Has an access token, but reading the refresh token always fails.
class _BrokenRefreshTokenStorage extends FakeTokenStorage {
  _BrokenRefreshTokenStorage(super.token);

  @override
  Future<String?> readRefreshToken() async =>
      throw StateError('Keychain unavailable');
}
