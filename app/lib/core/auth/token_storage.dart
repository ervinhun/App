import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the backend access token in the platform keychain / keystore.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _accessTokenKey);

  Future<void> write(String accessToken) =>
      _storage.write(key: _accessTokenKey, value: accessToken);

  Future<void> clear() => _storage.delete(key: _accessTokenKey);
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
