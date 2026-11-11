import 'dart:async';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  late FakeTokenStorage tokens;
  late FakeAuthClient api;
  late FakeGoogleAuth google;

  ProviderContainer container() => ProviderContainer.test(
    overrides: [
      tokenStorageProvider.overrideWithValue(tokens),
      authClientProvider.overrideWithValue(api),
      signInClientProvider.overrideWithValue(api),
      googleAuthProvider.overrideWithValue(google),
    ],
  );

  setUp(() {
    tokens = FakeTokenStorage();
    api = FakeAuthClient();
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
      final call = api.externalCalls.single;
      expect(
        (call.provider, call.idToken, call.displayName, call.platform),
        ('google', 'google-id-token', 'Anna G', 'android'),
      );
      expect(tokens.token, 'backend-jwt');
      expect(tokens.refreshToken, 'backend-refresh');
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

  group('sign out', () {
    test(
      'ends the backend session, clears the tokens and the Google account',
      () async {
        tokens
          ..token = 'jwt'
          ..refreshToken = 'refresh';
        final c = container();
        await c.read(authControllerProvider.future);

        await c.read(authControllerProvider.notifier).signOut();

        expect(api.logoutCalls, 1);
        expect(tokens.token, isNull);
        expect(tokens.refreshToken, isNull);
        expect(google.signedOut, isTrue);
        expect(c.read(authControllerProvider).value, isNull);
      },
    );

    test('still signs out locally when the backend is unreachable', () async {
      tokens.token = 'jwt';
      api.logoutError = ApiException("Can't reach the server.");
      final c = container();
      await c.read(authControllerProvider.future);

      await c.read(authControllerProvider.notifier).signOut();

      expect(tokens.token, isNull);
      expect(c.read(authControllerProvider).value, isNull);
    });
  });

  group('signing out during the startup check', () {
    Future<void> signOutWhileCheckingThenAnswer(Object meResult) async {
      tokens.token = 'jwt';
      api.meGate = Completer();
      final c = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          tokenStorageProvider.overrideWithValue(tokens),
          authClientProvider.overrideWithValue(api),
          signInClientProvider.overrideWithValue(api),
          googleAuthProvider.overrideWithValue(google),
        ],
      );
      c.listen(authControllerProvider, (_, _) {});
      await pumpEventQueue();

      await c.read(authControllerProvider.notifier).signOut();
      api.meResult = meResult;
      api.meGate!.complete();
      await pumpEventQueue();

      final auth = c.read(authControllerProvider);
      expect(auth.value, isNull);
      expect(auth.hasError, isFalse);
      expect(auth.isLoading, isFalse);
    }

    test('is not undone by a late failure', () async {
      await signOutWhileCheckingThenAnswer(ApiException('offline'));
    });

    test('is not undone by a late success', () async {
      await signOutWhileCheckingThenAnswer(anna);
    });
  });

  test('a Google failure still signs out of the app', () async {
    tokens.token = 'jwt';
    google.signOutError = Exception('Google is unavailable');
    final c = container();
    await c.read(authControllerProvider.future);

    await expectLater(
      c.read(authControllerProvider.notifier).signOut(),
      throwsException,
    );

    expect(tokens.token, isNull);
    expect(c.read(authControllerProvider).value, isNull);
  });
}
