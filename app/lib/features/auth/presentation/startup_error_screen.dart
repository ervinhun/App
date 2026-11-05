import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';

/// Shown when the stored tokens couldn't be checked on startup, such as when
/// offline. The user may still be signed in, so this doesn't ask them to sign in.
///
/// The check also keeps retrying by itself for a while. Sign out is the way out
/// if it can never succeed.
class StartupErrorScreen extends ConsumerWidget {
  const StartupErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'FridgeFriend',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    ApiException.messageFor(auth.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  auth.isLoading
                      ? const LinearProgressIndicator()
                      : const SizedBox(height: 4),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => ref.invalidate(authControllerProvider),
                    child: const Text('Try again'),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
