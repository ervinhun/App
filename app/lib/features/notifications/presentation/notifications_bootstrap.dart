import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/features/notifications/data/notification_service.dart';
import 'package:app/features/notifications/presentation/notifications_controller.dart';
import 'package:app/features/notifications/presentation/notifications_off_dialog.dart';

/// Starts the expiry notifications once signed in, asks for permission, and
/// opens My food, filtered to what is expiring, when a reminder is tapped.
class NotificationsBootstrap extends ConsumerStatefulWidget {
  const NotificationsBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationsBootstrap> createState() =>
      _NotificationsBootstrapState();
}

class _NotificationsBootstrapState
    extends ConsumerState<NotificationsBootstrap> {
  StreamSubscription<String?>? _taps;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _taps?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final notifications = ref.read(notificationsControllerProvider);
    final service = ref.read(notificationServiceProvider);
    try {
      await service.init();
      _taps = service.taps.listen((_) {
        if (mounted) context.go(Routes.expiring);
      });
      if (await service.launchedByReminder() && mounted) {
        context.go(Routes.expiring);
      }
      // Not awaited: the permission prompt shouldn't wait for the network.
      unawaited(notifications.start());
      if (await notifications.ensureAllowed() || !mounted) return;
      if (await showNotificationsOffDialog(context)) {
        await notifications.openSystemSettings();
      }
    } catch (e) {
      debugPrint('Could not set up notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
