import 'package:app/core/featureflags/feature_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/features/notifications/presentation/notifications_controller.dart';
import 'package:app/features/notifications/presentation/notifications_off_dialog.dart';

/// The "Management" tab: a placeholder for fridge management, with a button
/// that sends a test notification.
class FridgesScreen extends ConsumerWidget {
  const FridgesScreen({super.key});

  Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifications = ref.read(notificationsControllerProvider);
    try {
      if (!await notifications.ensureAllowed()) {
        if (context.mounted && await showNotificationsOffDialog(context)) {
          await notifications.openSystemSettings();
        }
        return;
      }
      final body = await notifications.sendTest();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Sent: $body'),
            persist: false,
            duration: const Duration(seconds: 5),
          ),
        );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiException.messageFor(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Your fridges')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Fridge management is coming soon.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _sendTest(context, ref),
            icon: const Icon(LucideIcons.bellRing),
            label: const Text('Send test notification'),
          ),
          if (ref.watch(featureEnabledProvider('test1')).value ?? false)
            FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    const AlertDialog(content: Text('This is enabled')),
              ),
              icon: const Icon(LucideIcons.circleCheck),
              label: const Text('Feature test1 is enabled'),
            ),
        ],
      ),
    ),
  );
}
