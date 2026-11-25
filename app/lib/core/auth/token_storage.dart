import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:app/core/api/generated/export.dart';

/// Keeps the backend's access and refresh tokens in the platform keychain /
/// keystore, with the signed-in user so the app can start offline.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          // Readable after the first unlock, so a background task can use the
          // tokens while the phone is locked.
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

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

  /// The user the tokens belong to, as the backend last returned them. If none
  /// is saved or it can't be read, e.g. after signing in with an older app
  /// version, the one the access token was issued for: the next check with the
  /// backend saves them again.
  Future<UserDto?> readUser() async =>
      await _readSavedUser() ?? _userOf(await read());

  /// Reads the claims without checking the token, also when it has expired:
  /// the backend checks it on every request.
  static UserDto? _userOf(String? accessToken) {
    if (accessToken == null) return null;
    try {
      final payload = base64Url.normalize(accessToken.split('.')[1]);
      final claims = jsonDecode(
        utf8.decode(base64Url.decode(payload)),
      ) as Map<String, dynamic>;
      return UserDto(
        id: claims['sub'] as String,
        email: claims['email'] as String,
        displayName: claims['name'] as String,
        locale: claims['locale'] as String,
      );
    } catch (e) {
      debugPrint('Could not read the user from the access token: $e');
      return null;
    }
  }

  Future<UserDto?> _readSavedUser() async {
    final json = await _storage.read(key: _userKey);
    if (json == null) return null;
    try {
      return UserDto.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Could not read the saved user: $e');
      return null;
    }
  }

  Future<void> writeUser(UserDto user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  /// Re-saves tokens stored under the iOS default (readable only while
  /// unlocked) with the first-unlock setting. Does nothing if there are none.
  Future<void> migrateAccessibility() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    final access = await read();
    final refresh = await readRefreshToken();
    if (access != null && refresh != null) {
      await write(accessToken: access, refreshToken: refresh);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
