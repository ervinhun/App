import 'package:app/core/auth/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/auth/fakes.dart';

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
}
