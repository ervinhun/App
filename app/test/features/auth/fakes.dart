import 'dart:async';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/generated/export.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/data/google_auth.dart';

const anna = UserDto(
  id: '00000000-0000-0000-0000-000000000001',
  email: 'anna@example.com',
  displayName: 'Anna',
  locale: 'en',
);

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token, this.refreshToken]);

  String? token;
  String? refreshToken;

  @override
  Future<String?> read() async => token;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {
    token = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    token = null;
    refreshToken = null;
  }
}

class FakeAuthClient implements AuthClient {
  /// What `me()` returns for a stored token; an [ApiException] is thrown instead.
  Object meResult = anna;
  int meCalls = 0;

  /// When set, `me()` waits for this before answering.
  Completer<void>? meGate;

  /// Thrown by every sign-in call when set.
  ApiException? signInError;

  /// Thrown by `logout()` when set.
  ApiException? logoutError;

  final externalCalls = <ExternalLoginRequest>[];
  int logoutCalls = 0;

  AuthResponse _session() {
    if (signInError != null) throw signInError!;
    return AuthResponse(
      accessToken: 'backend-jwt',
      expiresAt: DateTime.utc(2030),
      refreshToken: 'backend-refresh',
      refreshTokenExpiresAt: DateTime.utc(2030),
      user: anna,
    );
  }

  @override
  Future<UserDto> me() async {
    meCalls++;
    await meGate?.future;
    return meResult is UserDto ? meResult as UserDto : throw meResult;
  }

  @override
  Future<AuthResponse> login({required LoginRequest body}) async => _session();

  @override
  Future<AuthResponse> register({required RegisterRequest body}) async =>
      _session();

  @override
  Future<AuthResponse> externalLogin({
    required ExternalLoginRequest body,
  }) async {
    externalCalls.add(body);
    return _session();
  }

  @override
  Future<AuthResponse> refresh({required RefreshRequest body}) =>
      throw UnimplementedError('AuthInterceptor refreshes, not the client.');

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError != null) throw logoutError!;
  }
}

class FakeGoogleAuth implements GoogleAuth {
  /// null simulates the user closing Google's account picker.
  GoogleCredential? credential = const GoogleCredential(
    idToken: 'google-id-token',
    displayName: 'Anna G',
  );
  bool signedOut = false;

  /// Thrown by `signIn()` when set.
  Object? signInError;

  /// Thrown by `signOut()` when set.
  Exception? signOutError;

  @override
  Future<GoogleCredential?> signIn() async {
    if (signInError != null) throw signInError!;
    return credential;
  }

  @override
  Future<void> signOut() async {
    if (signOutError != null) throw signOutError!;
    signedOut = true;
  }
}
