import 'package:app/core/auth/token_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

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
