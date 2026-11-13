import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/router/home_shell.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/auth/presentation/login_screen.dart';
import 'package:app/features/auth/presentation/startup_error_screen.dart';
import 'package:app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/food/presentation/add_food_screen.dart';
import 'package:app/features/fridges/presentation/fridges_screen.dart';
import 'package:app/features/profile/presentation/profile_screen.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const startupError = '/startup-error';
  static const home = '/';
  static const management = '/management';
  static const you = '/you';

  /// Takes `?storage=fridge|freezer|pantry` for where it goes by default.
  static const addFood = '/add-food';
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
      // Couldn't check the stored token. The user may still be signed in.
      if (auth.hasError && !auth.hasValue) {
        return at == Routes.startupError ? null : Routes.startupError;
      }
      // Still checking the stored token on startup.
      if (auth.isLoading && !auth.hasValue) {
        return at == Routes.splash ? null : Routes.splash;
      }
      final signedIn = auth.value != null;
      if (!signedIn) return at == Routes.login ? null : Routes.login;
      return (at == Routes.login ||
              at == Routes.splash ||
              at == Routes.startupError)
          ? Routes.home
          : null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: Routes.startupError,
        builder: (_, _) => const StartupErrorScreen(),
      ),
      // Outside the shell: full screen, over the navigation bar.
      GoRoute(
        path: Routes.addFood,
        builder: (_, state) => AddFoodScreen(
          storage:
              StorageLocation.values
                  .asNameMap()[state.uri.queryParameters['storage']] ??
              StorageLocation.fridge,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.management,
                builder: (_, _) => const FridgesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.you,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
