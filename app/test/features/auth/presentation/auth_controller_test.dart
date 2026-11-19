import 'dart:async';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/features/auth/data/guest_mode.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/food/data/food_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/test_database.dart';
import '../../food/food_store_test.dart' show food;
import '../fakes.dart';

void main() {
  late FakeTokenStorage tokens;
  late FakeAuthClient api;
  late FakeGoogleAuth google;
  late FakeGuestStorage guests;

  ProviderContainer container() => ProviderContainer.test(
    overrides: [
      inMemoryDatabase(),
      tokenStorageProvider.overrideWithValue(tokens),
      authClientProvider.overrideWithValue(api),
      signInClientProvider.overrideWithValue(api),
      googleAuthProvider.overrideWithValue(google),
      guestStorageProvider.overrideWithValue(guests),
    ],
  );

  setUp(() {
    tokens = FakeTokenStorage();
    api = FakeAuthClient();
    google = FakeGoogleAuth();
    guests = FakeGuestStorage();
  });

  test('when the backend ends the session, the food is forgotten', () async {
    tokens.token = 'jwt';
    final c = container();
    await c.read(authControllerProvider.future);
    final store = c.read(foodStoreProvider);
    await store.claimFor(anna.id);
    await store.save(food('a'), DateTime(2026, 11, 15));

    await c.read(authControllerProvider.notifier).endSession();

    expect(await store.items(), isEmpty);
    expect(await store.pendingCount(), 0);
  });

  group('startup', () {
    test('no stored token means signed out', () async {
      expect(await container().read(authControllerProvider.future), isNull);
    });

    test('a stored token restores the user', () async {
      tokens.token = 'old-jwt';

      expect(await container().read(authControllerProvider.future), anna);
    });

    test('offline, the stored user is signed in', () async {
      tokens
        ..token = 'old-jwt'
        ..user = anna;
      api.meResult = ApiException("Can't reach the server.");

      expect(await container().read(authControllerProvider.future), anna);
      expect(tokens.token, 'old-jwt');
    });

    test('online, the user is stored for starting offline', () async {
      tokens.token = 'old-jwt';

      await container().read(authControllerProvider.future);

      expect(tokens.user, anna);
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
      expect(tokens.user, anna);
      expect(c.read(authControllerProvider).value, anna);
    });

    test('a guest who signs in is a guest no more', () async {
      guests.guest = true;
      final c = container();
      await c.read(authControllerProvider.future);
      expect(await c.read(guestModeProvider.future), isTrue);

      await c.read(authControllerProvider.notifier).signInWithGoogle();

      expect(c.read(guestModeProvider).value, isFalse);
      expect(guests.guest, isFalse);
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
          inMemoryDatabase(),
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
