import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the backend's access and refresh tokens in the platform keychain / keystore.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

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
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
