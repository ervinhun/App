import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/l10n/app_localizations.dart';

/// Placeholder "You" tab until the profile screen is designed.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tr('profile.title')),
        actions: [
          IconButton(
            tooltip: context.l10n.tr('auth.signOut'),
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          context.l10n.tr(
            'profile.signedInAs',
            args: {'name': user?.displayName ?? ''},
          ),
        ),
      ),
    );
  }
}
