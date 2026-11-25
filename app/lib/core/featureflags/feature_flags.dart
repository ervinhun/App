import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_config.dart';
import 'package:app/core/featureflags/feature_flags_countries.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';

/// Reads FeatureHub flags with a *server-evaluated* API key: FeatureHub applies
/// the strategies (percentage, country, platform, version, plan tier) to the
/// context we send, and returns plain values. The Dart SDK needs Dart < 3, so
/// this calls the Edge REST API directly.
class FeatureFlags {
  FeatureFlags(this._dio, {this.url = '', this.apiKey = ''});

  final Dio _dio;
  final String url;
  final String apiKey;

  /// When FeatureHub last answered successfully; null until then.
  DateTime? lastFetched;

  /// Same contract as the backend's `IsEnabledAsync`. Returns false when
  /// FeatureHub isn't configured or can't be reached, so a flag never breaks the app.
  Future<bool> isEnabled(
    String feature, {
    String? userKey,
    String? country,
    String? platform,
    String? version,
    String? planTier,
  }) async {
    if (url.isEmpty || apiKey.isEmpty) return false;
    final context = {
      'userkey': ?userKey,
      'country': ?country,
      'platform': ?platform,
      'version': ?version,
      'plan_tier':
          ?planTier, // must match the attribute key in the FeatureHub strategy
    };
    try {
      final res = await _dio.get<List<dynamic>>(
        // The path-style `/features/<key>` is an SSE stream (406 for JSON).
        '$url/features',
        queryParameters: {'apiKey': apiKey},
        // FeatureHub's context header: key=value,key=value (values url-encoded).
        options: Options(
          headers: {
            'x-featurehub': context.entries
                .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
                .join(','),
          },
        ),
      );
      lastFetched = DateTime.now();
      // Response: one entry per environment, each a list of features.
      for (final env in res.data ?? const []) {
        for (final f in (env['features'] as List? ?? const [])) {
          if (f['key'] == feature) return f['value'] == true;
        }
      }
    } on DioException {
      // fall through: treat an unreachable FeatureHub as "off"
    }
    return false;
  }
}

final featureFlagsProvider = Provider<FeatureFlags>(
  (ref) => FeatureFlags(
    Dio(BaseOptions(connectTimeout: const Duration(seconds: 5))),
    url: ApiConfig.featureHubUrl,
    apiKey: ApiConfig.featureHubApiKey,
  ),
);

/// EXAMPLE: `ref.watch(featureEnabledProvider('createContainer'))` gives an
/// `AsyncValue<bool>` for the signed-in user on this platform.
final featureEnabledProvider = FutureProvider.family<bool, String>((
  ref,
  feature,
) {
  final user = ref.watch(authControllerProvider).value;
  return ref
      .watch(featureFlagsProvider)
      .isEnabled(
        feature,
        userKey: user?.id,
        country: deviceCountry(),
        platform: switch (defaultTargetPlatform) {
          TargetPlatform.iOS => 'ios',
          TargetPlatform.android => 'android',
          _ => null,
        },
      );
});

/// Refetches flags on return to the foreground if the last successful fetch
/// is 12h+ old. Watch it once near the root (see `FridgeFriendApp`).
final featureFlagRefreshProvider = Provider<void>((ref) {
  final listener = AppLifecycleListener(
    onResume: () {
      final last = ref.read(featureFlagsProvider).lastFetched;
      if (last == null ||
          DateTime.now().difference(last) >= const Duration(hours: 12)) {
        ref.invalidate(featureEnabledProvider);
      }
    },
  );
  ref.onDispose(listener.dispose);
});
