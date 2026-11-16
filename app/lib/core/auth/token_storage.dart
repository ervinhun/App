import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:app/core/api/generated/export.dart';

/// Keeps the backend's access and refresh tokens in the platform keychain /
/// keystore, with the signed-in user so the app can start offline.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user';

  final FlutterSecureStorage _storage;

  /// The access token, sent as the Bearer token.
  Future<String?> read() => _storage.read(key: _accessTokenKey);

  /// The single-use token for `POST /api/auth/refresh`.
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {
    // Refresh token first: it is single use, so losing the new one to a crash
    // would end the session, while an old access token just gets refreshed.
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  /// The user the tokens belong to, as the backend last returned them.
  Future<UserDto?> readUser() async {
    final json = await _storage.read(key: _userKey);
    if (json == null) return null;
    return UserDto.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> writeUser(UserDto user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
