import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/generated/export.dart';
import '../../../core/auth/token_storage.dart';
import '../data/google_auth.dart';

/// Who is signed in: `null` when signed out, loading while a stored token is
/// checked on startup.
///
/// Sign-in methods throw [ApiException] (or a Google SDK error) on failure and
/// leave the state unchanged, so screens can show the error themselves.
class AuthController extends AsyncNotifier<UserDto?> {
  TokenStorage get _tokens => ref.read(tokenStorageProvider);
  AuthClient get _api => ref.read(authClientProvider);

  /// Sent with every sign-in and stored on the backend's session.
  String get _platform => defaultTargetPlatform.name.toLowerCase();

  @override
  Future<UserDto?> build() async {
    if (await _tokens.read() == null) return null;
    try {
      return await apiCall(_api.me());
    } on ApiException catch (e) {
      // The session ended (even a refresh didn't help), or the account was deleted.
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
          _api.login(
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
      _api.register(
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
        _api.externalLogin(
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

  Future<void> signOut() async {
    if (await _tokens.read() != null) {
      try {
        await apiCall(_api.logout());
      } on ApiException {
        // Offline or already signed out: the local sign-out below still happens.
      }
    }
    await _tokens.clear();
    await ref.read(googleAuthProvider).signOut();
    state = const AsyncData(null);
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
