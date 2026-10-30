import 'package:app/core/api/api_client.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  late FakeTokenStorage tokens;
  late FakeAuthApi api;
  late FakeGoogleAuth google;

  ProviderContainer container() => ProviderContainer.test(
    overrides: [
      tokenStorageProvider.overrideWithValue(tokens),
      authApiProvider.overrideWithValue(api),
      googleAuthProvider.overrideWithValue(google),
    ],
  );

  setUp(() {
    tokens = FakeTokenStorage();
    api = FakeAuthApi();
    google = FakeGoogleAuth();
  });

  group('startup', () {
    test('no stored token means signed out', () async {
      expect(await container().read(authControllerProvider.future), isNull);
    });

    test('a stored token restores the user', () async {
      tokens.token = 'old-jwt';

      expect(await container().read(authControllerProvider.future), anna);
    });

    test('a rejected token is cleared', () async {
      tokens.token = 'expired-jwt';
      api.meResult = ApiException('Unauthorized', statusCode: 401);

      expect(await container().read(authControllerProvider.future), isNull);
      expect(tokens.token, isNull);
    });
  });

  group('Google', () {
    test('sends the ID token to the backend and stores our token', () async {
      final c = container();
      await c.read(authControllerProvider.future);

      final signedIn = await c
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(signedIn, isTrue);
      expect(api.externalCalls.single, (
        provider: 'google',
        idToken: 'google-id-token',
        name: 'Anna G',
      ));
      expect(tokens.token, 'backend-jwt');
      expect(c.read(authControllerProvider).value, anna);
    });

    test('closing the account picker changes nothing', () async {
      google.credential = null;
      final c = container();
      await c.read(authControllerProvider.future);

      final signedIn = await c
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(signedIn, isFalse);
      expect(api.externalCalls, isEmpty);
      expect(c.read(authControllerProvider).value, isNull);
    });

    test('a backend rejection throws and stays signed out', () async {
      api.signInError = ApiException('Invalid sign-in token.', statusCode: 401);
      final c = container();
      await c.read(authControllerProvider.future);

      await expectLater(
        c.read(authControllerProvider.notifier).signInWithGoogle(),
        throwsA(isA<ApiException>()),
      );
      expect(tokens.token, isNull);
      expect(c.read(authControllerProvider).value, isNull);
    });
  });

  test('sign out clears the token and the Google account', () async {
    tokens.token = 'jwt';
    final c = container();
    await c.read(authControllerProvider.future);

    await c.read(authControllerProvider.notifier).signOut();

    expect(tokens.token, isNull);
    expect(google.signedOut, isTrue);
    expect(c.read(authControllerProvider).value, isNull);
  });
}
