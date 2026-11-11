import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/generated/export.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/data/google_auth.dart';

/// Who is signed in: `null` when signed out, loading while a stored token is
/// checked on startup.
///
/// Sign-in methods throw [ApiException] (or a Google SDK error) on failure and
/// leave the state unchanged, so screens can show the error themselves.
class AuthController extends AsyncNotifier<UserDto?> {
  TokenStorage get _tokens => ref.read(tokenStorageProvider);
  AuthClient get _api => ref.read(authClientProvider);
  AuthClient get _signIn => ref.read(signInClientProvider);

  /// Sent with every sign-in and stored on the backend's session.
  String get _platform => defaultTargetPlatform.name.toLowerCase();

  @override
  Future<UserDto?> build() async {
    if (await _tokens.read() == null) return null;
    try {
      return await apiCall(_api.me());
    } on ApiException catch (e) {
      // The session ended, or the account was deleted.
      if (e.isUnauthorized) {
        await _tokens.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<void> signInWithPassword(String email, String password) async =>
      _start(
        await apiCall(
          _signIn.login(
            body: LoginRequest(
              email: email.trim(),
              password: password,
              platform: _platform,
            ),
          ),
        ),
      );

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async => _start(
    await apiCall(
      _signIn.register(
        body: RegisterRequest(
          email: email.trim(),
          password: password,
          displayName: displayName.trim(),
          platform: _platform,
        ),
      ),
    ),
  );

  /// Returns false if the user closed Google's account picker.
  Future<bool> signInWithGoogle() async {
    final credential = await ref.read(googleAuthProvider).signIn();
    if (credential == null) return false;
    await _start(
      await apiCall(
        _signIn.externalLogin(
          body: ExternalLoginRequest(
            provider: 'google',
            idToken: credential.idToken,
            displayName: credential.displayName,
            platform: _platform,
          ),
        ),
      ),
    );
    return true;
  }

  /// Ends the backend session too, then signs out here even if that failed.
  Future<void> signOut() async {
    if (await _tokens.read() != null) {
      try {
        await apiCall(_api.logout());
      } on ApiException {
        // Offline or already signed out: the local sign-out below still happens.
      }
    }
    await endSession();
  }

  /// Signs out on this device only, for when the backend already ended the
  /// session. Unlike [signOut] it sends no request, so `AuthInterceptor` can
  /// call it while a refresh is in flight.
  Future<void> endSession() async {
    final google = ref.read(googleAuthProvider);
    await _tokens.clear();
    state = const AsyncData(null);
    // Cancels a startup check still running, whose late result would undo this.
    ref.invalidateSelf();
    await google.signOut();
  }

  Future<void> _start(AuthResponse session) async {
    await _tokens.write(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    state = AsyncData(session.user);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, UserDto?>(
  AuthController.new,
);
