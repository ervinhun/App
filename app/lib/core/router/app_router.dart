import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/fridges/presentation/fridges_screen.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/';
}

/// Sends signed-out users to the login screen and signed-in users away from it.
final routerProvider = Provider<GoRouter>((ref) {
  // Re-runs `redirect` whenever the auth state changes.
  final authChanges = ValueNotifier<AsyncValue<Object?>>(
    ref.read(authControllerProvider),
  );
  ref.listen(authControllerProvider, (_, next) => authChanges.value = next);
  ref.onDispose(authChanges.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authChanges,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final at = state.matchedLocation;
      // Still checking the stored token on startup.
      if (auth.isLoading && !auth.hasValue) {
        return at == Routes.splash ? null : Routes.splash;
      }
      final signedIn = auth.value != null;
      if (!signedIn) return at == Routes.login ? null : Routes.login;
      return (at == Routes.login || at == Routes.splash) ? Routes.home : null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.home, builder: (_, _) => const FridgesScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
