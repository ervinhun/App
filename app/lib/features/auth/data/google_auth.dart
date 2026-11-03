import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/api/api_config.dart';

/// The result of the on-device Google sign-in.
class GoogleCredential {
  const GoogleCredential({required this.idToken, this.displayName});

  final String idToken;
  final String? displayName;
}

/// Wraps the Google Sign-In SDK: shows Google's account picker and returns the
/// ID token to send to the backend.
class GoogleAuth {
  Future<void>? _initialized;

  /// Returns null if the user closed the picker.
  Future<GoogleCredential?> signIn() async {
    final google = GoogleSignIn.instance;
    // initialize() must run exactly once per app run.
    await (_initialized ??= google.initialize(
      serverClientId: ApiConfig.googleServerClientId,
    ));

    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google did not return an ID token.');
      }
      return GoogleCredential(
        idToken: idToken,
        displayName: account.displayName,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  /// Forgets the chosen Google account, so the next sign-in shows the picker again.
  Future<void> signOut() async {
    if (_initialized == null) return;
    await _initialized;
    await GoogleSignIn.instance.signOut();
  }
}

final googleAuthProvider = Provider<GoogleAuth>((ref) => GoogleAuth());
