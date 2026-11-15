import 'package:app/core/api/api_client.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/core/storage/hint_storage.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/features/auth/data/guest_mode.dart';
import 'package:app/features/food/data/product_catalog_api.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'core/db/test_database.dart';
import 'core/storage/fake_hint_storage.dart';
import 'features/auth/fakes.dart';

void main() {
  late FakeTokenStorage tokens;
  late FakeAuthClient api;
  late FakeGuestStorage guests;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inMemoryDatabase(),
          tokenStorageProvider.overrideWithValue(tokens),
          authClientProvider.overrideWithValue(api),
          signInClientProvider.overrideWithValue(api),
          googleAuthProvider.overrideWithValue(FakeGoogleAuth()),
          hintStorageProvider.overrideWithValue(FakeHintStorage()),
          guestStorageProvider.overrideWithValue(guests),
          productTypesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const FridgeFriendApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    tokens = FakeTokenStorage();
    api = FakeAuthClient();
    guests = FakeGuestStorage();
  });

  // The variant sets and resets debugDefaultTargetPlatformOverride; resetting it in
  // tearDown is too late, the binding checks it is unset before tearDown runs.
  final android = TargetPlatformVariant.only(TargetPlatform.android);

  testWidgets('signed out: shows the login screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('Continue with email'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  }, variant: android);

  testWidgets('stored token: goes straight to the home screen', (tester) async {
    tokens.token = 'jwt';
    await pumpApp(tester);

    expect(find.text('First dibs'), findsOneWidget);
    expect(find.textContaining('HELLO, ANNA!'), findsOneWidget);
  }, variant: android);

  testWidgets('offline with a stored session: goes straight to home', (
    tester,
  ) async {
    tokens
      ..token = 'jwt'
      ..user = anna;
    api.meResult = ApiException("Can't reach the server.");
    await pumpApp(tester);

    expect(find.text('First dibs'), findsOneWidget);
    expect(find.textContaining('HELLO, ANNA!'), findsOneWidget);
  }, variant: android);

  testWidgets('Continue as guest opens the app; You offers signing in', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.text('First dibs'), findsOneWidget);
    expect(guests.guest, isTrue);

    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    expect(find.textContaining('as a guest'), findsOneWidget);

    await tester.tap(find.text('Sign in or create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(guests.guest, isFalse);
  }, variant: android);

  testWidgets('a guest stays a guest after a restart', (tester) async {
    guests.guest = true;
    await pumpApp(tester);

    expect(find.text('First dibs'), findsOneWidget);
  }, variant: android);

  testWidgets('Continue with Google signs in, sign out returns to login', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('First dibs'), findsOneWidget);

    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    expect(find.text('Signed in as Anna'), findsOneWidget);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
  }, variant: android);

  testWidgets('a backend error is shown on the login screen', (tester) async {
    api.signInError = ApiException(
      'Invalid email or password.',
      statusCode: 401,
    );
    await pumpApp(tester);
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'anna@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);
  }, variant: android);

  testWidgets('Google button is hidden on iOS for now', (tester) async {
    await pumpApp(tester);

    expect(find.text('Continue with Google'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
