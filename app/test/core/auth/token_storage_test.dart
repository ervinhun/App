import 'dart:convert';

import 'package:app/core/auth/token_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/auth/fakes.dart';

/// As the backend issues them: base64url without padding.
final annasToken = [
  for (final part in [
    {'alg': 'HS256', 'typ': 'JWT'},
    {'sub': anna.id, 'email': anna.email, 'name': 'Zoë', 'locale': anna.locale},
  ])
    base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', ''),
  'signature',
].join('.');

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('keeps both tokens until they are cleared', () async {
    final tokens = TokenStorage();

    await tokens.write(accessToken: 'jwt', refreshToken: 'refresh');
    expect(await tokens.read(), 'jwt');
    expect(await tokens.readRefreshToken(), 'refresh');

    await tokens.clear();
    expect(await tokens.read(), isNull);
    expect(await tokens.readRefreshToken(), isNull);
  });

  test('keeps the user, to start offline', () async {
    final tokens = TokenStorage();

    await tokens.writeUser(anna);

    expect((await tokens.readUser())?.id, anna.id);
  });

  for (final (what, saved) in [
    ('not JSON', '{"id": "anna'),
    ('not an object', '["anna"]'),
    ('missing fields', '{"displayName": 42}'),
  ]) {
    test('a saved user that is $what reads as none', () async {
      FlutterSecureStorage.setMockInitialValues({'user': saved});

      expect(await TokenStorage().readUser(), isNull);
    });
  }

  group('without a saved user', () {
    test('reads the one the access token was issued for', () async {
      FlutterSecureStorage.setMockInitialValues({'access_token': annasToken});

      final user = await TokenStorage().readUser();

      expect(
        (user?.id, user?.email, user?.displayName, user?.locale),
        (anna.id, anna.email, 'Zoë', anna.locale),
      );
    });

    test('a corrupt one falls back to the access token too', () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': annasToken,
        'user': '{"id": "anna',
      });

      expect((await TokenStorage().readUser())?.id, anna.id);
    });

    for (final (what, token) in [
      ('not a JWT', 'jwt'),
      ('not base64', 'a.!!!.c'),
      ('not JSON', 'a.${base64Url.encode(utf8.encode('nope'))}.c'),
      ('missing claims', 'a.${base64Url.encode(utf8.encode('{"sub":"1"}'))}.c'),
    ]) {
      test('a token that is $what reads as none', () async {
        FlutterSecureStorage.setMockInitialValues({'access_token': token});

        expect(await TokenStorage().readUser(), isNull);
      });
    }
  });

  test('migrating keeps the stored tokens', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'jwt',
      'refresh_token': 'refresh',
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final tokens = TokenStorage();

    await tokens.migrateAccessibility();

    expect(await tokens.read(), 'jwt');
    expect(await tokens.readRefreshToken(), 'refresh');
  });

  test('migrating with no tokens stores nothing', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final tokens = TokenStorage();

    await tokens.migrateAccessibility();

    expect(await tokens.read(), isNull);
  });
}
