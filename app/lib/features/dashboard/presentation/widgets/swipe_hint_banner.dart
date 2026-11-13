import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/storage/hint_storage.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';

/// Whether to teach the swipe gestures: true until the user first swipes a
/// card or closes the tip.
class SwipeHintController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      !await ref.read(hintStorageProvider).swipeHintDone();

  Future<void> done() async {
    if (state.value == false) return;
    state = const AsyncData(false);
    await ref.read(hintStorageProvider).markSwipeHintDone();
  }
}

final swipeHintProvider = AsyncNotifierProvider<SwipeHintController, bool>(
  SwipeHintController.new,
);

/// "Tip: swipe a card → to mark it opened, or ← to remove it."
class SwipeHintBanner extends StatelessWidget {
  const SwipeHintBanner({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
    decoration: BoxDecoration(
      color: AppColors.surfaceBlue,
      border: Border.all(color: AppColors.textSecondary),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(LucideIcons.hand, size: 18, color: AppColors.brandAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Tip: ',
                  style: AppText.nunito(
                    12,
                    FontWeight.w800,
                    AppColors.textPrimary,
                  ),
                ),
                const TextSpan(
                  text: 'swipe a card → to mark it opened, or ← to remove it.',
                ),
              ],
            ),
            style: AppText.nunito(12, FontWeight.w600, AppColors.brandPrimary),
          ),
        ),
        IconButton(
          tooltip: 'Close tip',
          onPressed: onClose,
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            LucideIcons.x,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
