import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';

/// The signed-in app: one tab per branch of [shell], with the main navigation
/// bar underneath.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  // In branch order: see the StatefulShellRoute in app_router.dart.
  static const _destinations = [
    (icon: LucideIcons.refrigerator, label: 'My food'),
    (icon: LucideIcons.shoppingBasket, label: 'Management'),
    (icon: LucideIcons.userRound, label: 'You'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: ColoredBox(
      color: AppColors.canvas,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 12, 40, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final (i, d) in _destinations.indexed)
                _Destination(
                  icon: d.icon,
                  label: d.label,
                  active: i == shell.currentIndex,
                  // Tapping the current tab again goes back to its start.
                  onTap: () => shell.goBranch(
                    i,
                    initialLocation: i == shell.currentIndex,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brandPrimary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: active,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.nunito(
                10,
                active ? FontWeight.w800 : FontWeight.w500,
                color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
