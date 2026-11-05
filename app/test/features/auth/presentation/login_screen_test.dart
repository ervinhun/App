import 'package:app/core/api/api_client.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  late FakeAuthApi api;
  late FakeGoogleAuth google;

  setUp(() {
    api = FakeAuthApi();
    google = FakeGoogleAuth();
  });

  Future<void> tapGoogle(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
          authApiProvider.overrideWithValue(api),
          googleAuthProvider.overrideWithValue(google),
        ],
        child: const FridgeFriendApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the message of a backend error', (tester) async {
    api.signInError = ApiException('Invalid sign-in token.', statusCode: 401);

    await tapGoogle(tester);

    expect(find.text('Invalid sign-in token.'), findsOneWidget);
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
