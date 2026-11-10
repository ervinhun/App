import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';

/// The logo, fridge switcher and notifications, then the greeting and title.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.fridgeName,
    required this.userName,
    required this.today,
    required this.hasUnread,
    required this.onSwitchFridge,
    required this.onNotifications,
  });

  final String fridgeName;
  final String userName;
  final DateTime today;
  final bool hasUnread;
  final VoidCallback onSwitchFridge;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final greeting =
        '${DateFormat('EEE, d MMM').format(today)} · Hello, $userName!';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Shrinks rather than overflows on narrow screens or large text.
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _Brand(),
              ),
            ),
            const SizedBox(width: 8),
            _FridgeSwitcher(name: fridgeName, onTap: onSwitchFridge),
            const SizedBox(width: 8),
            _NotificationsButton(hasUnread: hasUnread, onTap: onNotifications),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          greeting.toUpperCase(),
          style: AppText.nunito(10, FontWeight.w600, AppColors.statusUpcoming),
        ),
        const SizedBox(height: 3),
        Text(
          fridgeName,
          style: AppText.nunito(
            34,
            FontWeight.w800,
            AppColors.textPrimary,
            height: 1.08,
          ),
        ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox.square(
        dimension: 34,
        child: Padding(
          padding: const EdgeInsets.only(left: 3.67, top: 3.67),
          child: Align(
            alignment: Alignment.topLeft,
            child: SvgPicture.asset(
              'assets/images/logo_mark.svg',
              width: 26.66,
              height: 27.12,
            ),
          ),
        ),
      ),
      const SizedBox(width: 7),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Fridge', style: AppText.brand(Colors.black)),
            TextSpan(
              text: 'Friend',
              style: AppText.brand(AppColors.brandPrimary),
            ),
          ],
        ),
      ),
    ],
  );
}

class _FridgeSwitcher extends StatelessWidget {
  const _FridgeSwitcher({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _OutlinedPill(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: AppText.nunito(12, FontWeight.w700, AppColors.brandAccent),
        ),
        const SizedBox(width: 5),
        const Icon(
          LucideIcons.chevronDown,
          size: 11,
          color: AppColors.brandAccent,
        ),
      ],
    ),
  );
}

class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton({required this.hasUnread, required this.onTap});

  final bool hasUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: hasUnread ? 'Notifications, unread' : 'Notifications',
    child: _OutlinedPill(
      onTap: onTap,
      child: SizedBox.square(
        dimension: 38,
        child: Stack(
          children: [
            const Center(
              child: Icon(
                LucideIcons.bell,
                size: 18,
                color: AppColors.brandAccent,
              ),
            ),
            if (hasUnread)
              Positioned(
                left: 24,
                top: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.statusSoon,
                    border: Border.all(color: AppColors.surface),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// The light blue, outlined pill shape used by the header buttons.
class _OutlinedPill extends StatelessWidget {
  const _OutlinedPill({
    required this.onTap,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceBlue,
    shape: const StadiumBorder(
      side: BorderSide(color: AppColors.textSecondary),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}
