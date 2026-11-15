import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/sync/sync_controller.dart';
import 'package:app/features/auth/data/guest_mode.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/food/data/food_items_controller.dart';
import 'package:app/features/food/data/food_store.dart';

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

  /// Signs out and forgets this device's food, so the next person to use the
  /// phone doesn't see it. Asks first if some changes haven't been uploaded.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final pending = ref.read(syncControllerProvider).pending;
    if (pending > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign out?'),
          content: Text(
            pending == 1
                ? "1 change hasn't been saved online yet. Signing out now "
                      'loses it.'
                : "$pending changes haven't been saved online yet. Signing "
                      'out now loses them.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(foodStoreProvider).clear();
    ref.invalidate(foodItemsProvider);
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
