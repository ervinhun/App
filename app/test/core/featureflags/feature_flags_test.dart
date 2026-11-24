import 'dart:typed_data';

import 'package:app/core/featureflags/feature_flags.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Hub implements HttpClientAdapter {
  RequestOptions? last;
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    last = o;
    return ResponseBody.fromString(
      '[{"id":"e","features":[{"key":"createContainer","value":true},{"key":"off","value":false}]}]',
      200,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Hub hub;
  late FeatureFlags flags;
  setUp(() {
    hub = _Hub();
    flags = FeatureFlags(Dio()..httpClientAdapter = hub, url: 'http://hub', apiKey: 'k');
  });

  test('reads the flag and sends the context header', () async {
    expect(await flags.isEnabled('createContainer', userKey: 'u 1', country: 'hungary'), isTrue);
    expect(hub.last!.uri.toString(), 'http://hub/features/k');
    expect(hub.last!.headers['x-featurehub'], 'userkey=u%201,country=hungary');
    expect(await flags.isEnabled('off'), isFalse);
    expect(await flags.isEnabled('missing'), isFalse);
  });

  test('is off when FeatureHub is not configured', () async {
    expect(await FeatureFlags(Dio()).isEnabled('createContainer'), isFalse);
  });
}
