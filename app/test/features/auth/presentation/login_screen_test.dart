import 'package:app/core/api/api_client.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  late FakeAuthClient api;
  late FakeGoogleAuth google;

  setUp(() {
    api = FakeAuthClient();
    google = FakeGoogleAuth();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
          authClientProvider.overrideWithValue(api),
          signInClientProvider.overrideWithValue(api),
          googleAuthProvider.overrideWithValue(google),
        ],
        child: const FridgeFriendApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapGoogle(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> register(
    WidgetTester tester, {
    required String password,
    required String confirmation,
  }) async {
    await pumpApp(tester);
    await tap(tester, 'New here? Create an account');
    await tester.enterText(field('Name'), 'Anna');
    await tester.enterText(field('Email'), 'anna@example.com');
    await tester.enterText(field('Password'), password);
    await tester.enterText(field('Confirm password'), confirmation);
    await tap(tester, 'Create account');
  }

  testWidgets('shows the message of a backend error', (tester) async {
    api.signInError = ApiException('Invalid sign-in token.', statusCode: 401);

    await tapGoogle(tester);

    expect(find.text('Invalid sign-in token.'), findsOneWidget);
  });

  group('registering', () {
    testWidgets('asks to confirm the password', (tester) async {
      await pumpApp(tester);
      expect(field('Confirm password'), findsNothing);

      await tap(tester, 'New here? Create an account');

      expect(field('Confirm password'), findsOneWidget);
    });

    testWidgets('creates the account when both passwords match', (
      tester,
    ) async {
      await register(
        tester,
        password: 'correct-horse',
        confirmation: 'correct-horse',
      );

      expect(find.text('Signed in as Anna'), findsOneWidget);
    });

    testWidgets('stops when the passwords differ', (tester) async {
      await register(
        tester,
        password: 'correct-horse',
        confirmation: 'correct-house',
      );

      expect(find.text("Passwords don't match"), findsOneWidget);
      expect(find.text('Signed in as Anna'), findsNothing);
    });
  });

  testWidgets('hides the details of any other error', (tester) async {
    google.signInError = StateError('Google did not return an ID token.');

    await tapGoogle(tester);

    expect(find.textContaining('ID token'), findsNothing);
    expect(find.textContaining('Bad state'), findsNothing);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });
}
