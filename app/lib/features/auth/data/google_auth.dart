import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:app/core/api/api_config.dart';

/// The result of the on-device Google sign-in.
class GoogleCredential {
  const GoogleCredential({required this.idToken, this.displayName});

  final String idToken;
  final String? displayName;
}

/// Wraps the Google Sign-In SDK: shows Google's account picker and returns the
/// ID token to send to the backend.
class GoogleAuth {
  GoogleAuth({GoogleSignIn? google, this._serverClientId})
    : _google = google ?? GoogleSignIn.instance;

  final GoogleSignIn _google;
  final String? _serverClientId;
  Future<void>? _initialized;

  /// Returns null if the user closed the picker.
  Future<GoogleCredential?> signIn() async {
    await _ensureInitialized();

    try {
      final account = await _google.authenticate();
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
    await _ensureInitialized();
    await _google.signOut();
  }

  /// initialize() must only succeed once per app run. A failure is forgotten so
  /// the next attempt tries again.
  Future<void> _ensureInitialized() async {
    final initializing = _initialized ??= _google.initialize(
      serverClientId: _serverClientId ?? ApiConfig.googleServerClientId,
    );
    try {
      await initializing;
    } catch (_) {
      // Parallel callers share a failure, and must not forget a newer attempt.
      if (identical(_initialized, initializing)) _initialized = null;
      rethrow;
    }
  }
}

final googleAuthProvider = Provider<GoogleAuth>((ref) => GoogleAuth());
