import 'package:app/core/api/api_client.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

const _offlineMessage = "Can't reach the server.";

void main() {
  late FakeTokenStorage tokens;
  late FakeAuthApi api;

  setUp(() {
    tokens = FakeTokenStorage('jwt')..refreshToken = 'refresh';
    api = FakeAuthApi()..meResult = ApiException(_offlineMessage);
  });

  /// Not pumpAndSettle: the progress bar animates for as long as a retry runs.
  Future<void> pumpABit(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> pumpApp(WidgetTester tester, {bool autoRetry = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: autoRetry ? null : (_, _) => null,
        overrides: [
          tokenStorageProvider.overrideWithValue(tokens),
          authApiProvider.overrideWithValue(api),
          googleAuthProvider.overrideWithValue(FakeGoogleAuth()),
        ],
        child: const FridgeFriendApp(),
      ),
    );
    await pumpABit(tester);
  }

  void expectStartupError() {
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  }

  testWidgets('starting offline offers a retry, not the login form', (
    tester,
  ) async {
    await pumpApp(tester);

    expectStartupError();
    expect(find.text(_offlineMessage), findsOneWidget);
    expect(tokens.token, 'jwt');
    expect(tokens.refreshToken, 'refresh');
  });

  testWidgets('shows while retrying, and recovers by itself', (tester) async {
    await pumpApp(tester, autoRetry: true);
    expectStartupError();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    api.meResult = anna;
    await tester.pump(const Duration(seconds: 7));
    await pumpABit(tester);

    expect(find.text('Signed in as Anna'), findsOneWidget);
  });

  group('Try again', () {
    testWidgets('goes home once the check succeeds', (tester) async {
      await pumpApp(tester);

      api.meResult = anna;
      await tester.tap(find.text('Try again'));
      await pumpABit(tester);

      expect(find.text('Signed in as Anna'), findsOneWidget);
    });

    testWidgets('comes back here if it fails again', (tester) async {
      await pumpApp(tester);
      final calls = api.meCalls;

      await tester.tap(find.text('Try again'));
      await pumpABit(tester);

      expect(api.meCalls, calls + 1);
      expectStartupError();
      expect(tokens.token, 'jwt');
    });

    testWidgets('goes to login if the session has ended', (tester) async {
      await pumpApp(tester);

      api.meResult = ApiException('Unauthorized', statusCode: 401);
      await tester.tap(find.text('Try again'));
      await pumpABit(tester);

      expect(find.byType(TextFormField), findsWidgets);
      expect(tokens.token, isNull);
    });
  });

  testWidgets('Sign out clears the tokens and goes to login', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Sign out'));
    await pumpABit(tester);

    expect(find.byType(TextFormField), findsWidgets);
    expect(tokens.token, isNull);
    expect(tokens.refreshToken, isNull);
  });

  testWidgets('other failures show a generic message', (tester) async {
    api.meResult = StateError('secret internals');

    await pumpApp(tester);

    expectStartupError();
    expect(find.textContaining('secret internals'), findsNothing);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });
}
