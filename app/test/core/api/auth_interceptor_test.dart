import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/api/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/auth/fakes.dart';

/// Answers requests from [handle] instead of the network, and records them.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handle);

  final (int, Object?) Function(RequestOptions request) handle;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = handle(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeTokenStorage tokens;

  Dio dio(FakeAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://api'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(dio, tokens));
    return dio;
  }

  String? bearer(RequestOptions r) => r.headers['Authorization'] as String?;

  setUp(() => tokens = FakeTokenStorage('old-access', 'old-refresh'));

  test('sends the stored access token', () async {
    final adapter = FakeAdapter((_) => (200, {}));

    await dio(adapter).get<void>('/api/auth/me');

    expect(bearer(adapter.requests.single), 'Bearer old-access');
  });

  test('on 401, refreshes once and retries with the new token', () async {
    final adapter = FakeAdapter(
      (r) => switch (r.path) {
        '/api/auth/refresh' => (
          200,
          {'accessToken': 'new-access', 'refreshToken': 'new-refresh'},
        ),
        _ when bearer(r) == 'Bearer new-access' => (200, {'ok': true}),
        _ => (401, null),
      },
    );

    final response = await dio(adapter).get<Map<String, dynamic>>('/api/x');

    expect(response.data, {'ok': true});
    final refresh = adapter.requests[1];
    expect(refresh.data, {'refreshToken': 'old-refresh'});
    expect(bearer(refresh), isNull);
    expect((tokens.token, tokens.refreshToken), ('new-access', 'new-refresh'));
  });

  test('concurrent 401s share a single refresh', () async {
    final adapter = FakeAdapter(
      (r) => switch (r.path) {
        '/api/auth/refresh' => (
          200,
          {'accessToken': 'new-access', 'refreshToken': 'new-refresh'},
        ),
        _ when bearer(r) == 'Bearer new-access' => (200, {}),
        _ => (401, null),
      },
    );
    final client = dio(adapter);

    await Future.wait([client.get<void>('/api/a'), client.get<void>('/api/b')]);

    expect(
      adapter.requests.where((r) => r.path == '/api/auth/refresh'),
      hasLength(1),
    );
  });

  test(
    'a rejected refresh token clears the tokens and passes on the 401',
    () async {
      final adapter = FakeAdapter((_) => (401, null));

      await expectLater(
        dio(adapter).get<void>('/api/x'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect((tokens.token, tokens.refreshToken), (null, null));
    },
  );

  test('an unreachable server keeps the tokens', () async {
    final adapter = FakeAdapter(
      (r) => r.path == '/api/auth/refresh'
          ? throw DioException.connectionError(
              requestOptions: r,
              reason: 'offline',
            )
          : (401, null),
    );

    await expectLater(
      dio(adapter).get<void>('/api/x'),
      throwsA(isA<DioException>()),
    );
    expect((tokens.token, tokens.refreshToken), ('old-access', 'old-refresh'));
  });

  test('a 401 without a token is not retried', () async {
    tokens.token = null;
    final adapter = FakeAdapter((_) => (401, null));

    await expectLater(
      dio(adapter).post<void>('/api/auth/login'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
  });
}
