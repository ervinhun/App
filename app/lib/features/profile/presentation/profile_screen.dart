import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/featureflags/feature_flags.dart';
import 'package:app/features/auth/data/guest_mode.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';

/// Placeholder "You" tab until the profile screen is designed.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const _GuestProfile();
    return Scaffold(
      appBar: AppBar(
        title: const Text('You'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            // The food stays on the phone (see `AuthController.endSession`).
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Signed in as ${user.displayName}'),
            // Feature flag example: shown only when FeatureHub enables it.
            if (ref.watch(featureEnabledProvider('createContainer')).value ??
                false)
              const Text('createContainer is on'),
          ],
        ),
      ),
    );
  }
}

class _GuestProfile extends ConsumerWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('You')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const Text(
              "You're using FridgeFriend as a guest. Your food is saved on "
              'this phone only. Sign in to keep it safe and share your fridge: '
              'your food comes with you.',
              textAlign: TextAlign.center,
            ),
            FilledButton(
              onPressed: () => ref.read(guestModeProvider.notifier).leave(),
              child: const Text('Sign in or create an account'),
            ),
          ],
        ),
      ),
    ),
  );
}
