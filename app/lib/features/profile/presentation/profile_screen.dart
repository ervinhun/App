import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/sync/sync_controller.dart';
import 'package:app/core/widgets/adaptive.dart';
import 'package:app/features/auth/data/guest_mode.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/fridges/data/fridges_controller.dart';

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
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: Center(child: Text('Signed in as ${user.displayName}')),
    );
  }

  /// Signs out (see `AuthController.endSession` for what stays on the
  /// phone). Food from someone else's fridge is forgotten, so this asks first
  /// if some of its changes aren't uploaded yet.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final pending = ref.read(syncControllerProvider).pending;
    final fridge = ref.read(fridgesProvider).value?.current;
    if (pending > 0 && fridge != null && !fridge.isOwner) {
      final confirmed = await Adaptive.confirm(
        context,
        title: 'Sign out?',
        message: pending == 1
            ? "1 change hasn't been saved online yet. Signing out now loses "
                  'it.'
            : "$pending changes haven't been saved online yet. Signing out "
                  'now loses them.',
        confirmLabel: 'Sign out',
        destructive: true,
      );
      if (!confirmed) return;
    }
    await ref.read(authControllerProvider.notifier).signOut();
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
