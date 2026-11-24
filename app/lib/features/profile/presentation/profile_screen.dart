import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/featureflags/feature_flags.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';

/// Placeholder "You" tab until the profile screen is designed.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('You'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Signed in as ${user?.displayName ?? ''}'),
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
