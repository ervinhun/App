import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the backend's access and refresh tokens in the platform keychain / keystore.
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
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
