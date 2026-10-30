import 'package:flutter/foundation.dart';

/// Build-time configuration, overridable with `--dart-define=KEY=value`.
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
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '597020758457-gu30jespd4t681ks9h68ffja5phoskvm.apps.googleusercontent.com',
  );
}
