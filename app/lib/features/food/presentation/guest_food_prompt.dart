import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/features/food/data/guest_food_question.dart';

/// Asks, over [child], whether to add the food a guest added on this phone to
/// the account just signed in to, when the sync controller wants to know.
class GuestFoodPrompt extends ConsumerStatefulWidget {
  const GuestFoodPrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GuestFoodPrompt> createState() => _GuestFoodPromptState();
}

class _GuestFoodPromptState extends ConsumerState<GuestFoodPrompt> {
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    // Fires at once for a question asked while signing in, before this
    // screen showed.
    ref.listenManual(guestFoodQuestionProvider, (_, food) {
      if (food != null && !_showing) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
      } else if (food == null && _showing) {
        // The question was dropped, e.g. by a sign-out.
        Navigator.of(context, rootNavigator: true).pop();
      }
    }, fireImmediately: true);
  }

  Future<void> _ask() async {
    if (!mounted || _showing) return;
    _showing = true;
    final add = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const PopScope(canPop: false, child: _GuestFoodDialog()),
    );
    _showing = false;
    if (add != null) {
      ref.read(guestFoodQuestionProvider.notifier).answer(add: add);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Figma: "Add phone food to account". Pops true to add the food.
class _GuestFoodDialog extends StatelessWidget {
  const _GuestFoodDialog();

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    // 382 wide, as in the design on a 412-wide phone.
    insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 382),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            Center(
              child: SizedBox.square(
                dimension: 56,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6.04, top: 6.04),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SvgPicture.asset(
                      'assets/images/logo_mark.svg',
                      width: 43.91,
                      height: 44.66,
                    ),
                  ),
                ),
              ),
            ),
            Column(
              spacing: 10,
              children: [
                Text(
                  'Add food to your account?',
                  textAlign: TextAlign.center,
                  style: AppText.nunito(
                    25,
                    FontWeight.w900,
                    AppColors.textPrimary,
                    height: 30 / 25,
                  ),
                ),
                Text(
                  'You have food saved on this phone. Would you like to add it '
                  'to your account?',
                  textAlign: TextAlign.center,
                  style: AppText.nunito(
                    15,
                    FontWeight.w400,
                    AppColors.textPrimary,
                    height: 22 / 15,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                _DialogButton(
                  label: 'Add to account',
                  color: AppColors.brandPrimary,
                  textColor: AppColors.surface,
                  onPressed: () => Navigator.pop(context, true),
                ),
                _DialogButton(
                  label: 'Keep on this phone',
                  color: AppColors.surfaceBlue,
                  textColor: AppColors.textPrimary,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onPressed,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.nunito(
                14,
                FontWeight.w800,
                textColor,
                height: 20 / 14,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
