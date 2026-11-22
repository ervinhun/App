import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// The result of the on-device Apple sign-in.
class AppleCredential {
  const AppleCredential({required this.idToken, this.displayName});

  final String idToken;
  final String? displayName;
}

/// Wraps Sign in with Apple: shows Apple's sheet and returns the ID token to
/// send to the backend.
class AppleAuth {
  /// Build with `--dart-define=FAKE_APPLE_SIGN_IN=true` to skip Apple and send a
  /// fake token the backend accepts only in Development. For the simulator
  /// without a paid developer account.
  static const _fake = bool.fromEnvironment('FAKE_APPLE_SIGN_IN');
  static const _fakeToken = 'fake-apple-token';

  /// Sign in with Apple is offered on iOS only.
  static bool get available => defaultTargetPlatform == TargetPlatform.iOS;

  /// Returns null if the user closed Apple's sheet.
  Future<AppleCredential?> signIn() async {
    if (_fake) {
      return const AppleCredential(
        idToken: _fakeToken,
        displayName: 'Fake Apple User',
      );
    }
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw StateError('Apple did not return an ID token.');
      }
      // Apple only sends the name on the very first sign-in.
      final name = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().join(' ');
      return AppleCredential(
        idToken: idToken,
        displayName: name.isEmpty ? null : name,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }
}

final appleAuthProvider = Provider<AppleAuth>((ref) => AppleAuth());
