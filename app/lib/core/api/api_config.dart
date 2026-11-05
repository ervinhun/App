import 'package:flutter/foundation.dart';

/// Build-time configuration, read from `.env` by building with
/// `--dart-define-from-file=.env`.
abstract final class ApiConfig {
  static const _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// The FridgeFriend backend. Defaults to the API from `dotnet run` / docker compose
  /// on this machine: the Android emulator reaches the host as 10.0.2.2.
  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5092'
        : 'http://localhost:5092';
  }

  /// The Google OAuth "Web application" client id. Google issues the app's ID
  /// tokens for this client, and the backend only accepts tokens issued for it.
  /// Public by design — it is not a secret.
  static String get googleServerClientId {
    if (_googleServerClientId.isEmpty) {
      throw StateError(
        'GOOGLE_SERVER_CLIENT_ID is not set. Copy .env.example to .env and '
        'build with --dart-define-from-file=.env.',
      );
    }
    return _googleServerClientId;
  }

  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Throws if required configuration is missing, so a bad build fails on launch
  /// instead of when someone first taps the Google button.
  static void validate() => googleServerClientId;
}
