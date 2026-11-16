import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/sync/connectivity.dart';
import 'package:app/core/sync/sync_controller.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';

/// Says when the app is offline, and that changes still count.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final network = ref.watch(networkAvailableProvider).value ?? true;
    if (network && sync.reachable) return const SizedBox.shrink();

    final waiting = switch (sync.pending) {
      0 => '',
      1 => ' 1 change is waiting.',
      final n => ' $n changes are waiting.',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceBlue,
          border: Border.all(color: AppColors.textSecondary),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          spacing: 8,
          children: [
            const Icon(
              LucideIcons.cloudOff,
              size: 18,
              color: AppColors.brandAccent,
            ),
            Expanded(
              child: Text(
                "You're offline. Changes are saved on this phone and sync "
                "when you're back online.$waiting",
                style: AppText.nunito(
                  12,
                  FontWeight.w600,
                  AppColors.brandPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
