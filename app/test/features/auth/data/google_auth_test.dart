import 'dart:async';

import 'package:app/features/auth/data/google_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Every sign-in ends with the user closing the picker, since that is all
/// [GoogleAuth] needs after initializing.
class _FakeGoogleSignIn implements GoogleSignIn {
  int initializeCalls = 0;
  int signOutCalls = 0;

  /// Each call to `initialize()` removes and runs the first of these, if any.
  final initializeResults = <Future<void> Function()>[];

  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) {
    initializeCalls++;
    return initializeResults.isEmpty
        ? Future.value()
        : initializeResults.removeAt(0)();
  }

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const [],
  }) async => throw const GoogleSignInException(
    code: GoogleSignInExceptionCode.canceled,
  );

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeGoogleSignIn google;
  late GoogleAuth auth;

  setUp(() {
    google = _FakeGoogleSignIn();
    auth = GoogleAuth(google: google, serverClientId: 'server-client-id');
  });

  final failure = Exception('transient');

  test('initializes once across sign-ins', () async {
    await auth.signIn();
    await auth.signIn();

    expect(google.initializeCalls, 1);
  });

  test('tries again after a failed initialize', () async {
    google.initializeResults.add(() async => throw failure);

    await expectLater(auth.signIn(), throwsA(failure));

    expect(await auth.signIn(), isNull);
    expect(google.initializeCalls, 2);
  });

  test('tries again after initialize throws synchronously', () async {
    google.initializeResults.add(() => throw failure);

    await expectLater(auth.signIn(), throwsA(failure));

    expect(await auth.signIn(), isNull);
    expect(google.initializeCalls, 2);
  });

  test('parallel sign-ins share one initialize', () async {
    final gate = Completer<void>();
    google.initializeResults.add(() => gate.future);

    final signIns = [auth.signIn(), auth.signIn()];
    gate.complete();
    await Future.wait(signIns);

    expect(google.initializeCalls, 1);
  });

  test('a shared failure does not forget a newer attempt', () async {
    final gate = Completer<void>();
    google.initializeResults.add(() => gate.future);

    final first = auth.signIn();
    final second = auth.signIn();
    gate.completeError(failure);
    await expectLater(first, throwsA(failure));
    final third = auth.signIn();
    await expectLater(second, throwsA(failure));
    await third;
    await auth.signIn();

    expect(google.initializeCalls, 2);
  });

  group('sign out', () {
    test('does nothing if Google was never initialized', () async {
      await auth.signOut();

      expect(google.initializeCalls, 0);
      expect(google.signOutCalls, 0);
    });

    test('does nothing after a failed initialize', () async {
      google.initializeResults.add(() async => throw failure);
      await expectLater(auth.signIn(), throwsA(failure));

      await auth.signOut();

      expect(google.signOutCalls, 0);
    });

    test('signs out after a sign-in', () async {
      await auth.signIn();

      await auth.signOut();

      expect(google.signOutCalls, 1);
      expect(google.initializeCalls, 1);
    });
  });
}
