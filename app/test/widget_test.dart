import 'package:app/core/api/api_client.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/auth/fakes.dart';

void main() {
  late FakeTokenStorage tokens;
  late FakeAuthApi api;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokens),
          authApiProvider.overrideWithValue(api),
          googleAuthProvider.overrideWithValue(FakeGoogleAuth()),
        ],
        child: const FridgeFriendApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    tokens = FakeTokenStorage();
    api = FakeAuthApi();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  testWidgets('signed out: shows the login screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('stored token: goes straight to the home screen', (tester) async {
    tokens.token = 'jwt';
    await pumpApp(tester);

    expect(find.text('Signed in as Anna'), findsOneWidget);
  });

  testWidgets('Continue with Google signs in, sign out returns to login', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Signed in as Anna'), findsOneWidget);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('a backend error is shown on the login screen', (tester) async {
    api.signInError = ApiException(
      'Invalid email or password.',
      statusCode: 401,
    );
    await pumpApp(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'anna@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);
  });

  testWidgets('Google button is hidden on iOS for now', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpApp(tester);

    expect(find.text('Continue with Google'), findsNothing);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });
}
