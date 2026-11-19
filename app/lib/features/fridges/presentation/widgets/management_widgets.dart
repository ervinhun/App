import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/core/widgets/brand_logo.dart';
import 'package:app/features/fridges/domain/fridge.dart';

/// The top of the Management screens: the logo and fridge switcher, a back
/// link, the title, and a card about the fridge being managed.
class ManagementHeader extends StatelessWidget {
  const ManagementHeader({
    super.key,
    required this.fridgeName,
    required this.onSwitchFridge,
    required this.backLabel,
    required this.onBack,
    required this.title,
    this.card,
    this.subtitle,
  });

  final String? fridgeName;
  final VoidCallback onSwitchFridge;
  final String backLabel;
  final VoidCallback onBack;
  final String title;
  final String? subtitle;
  final Widget? card;

  @override
  Widget build(BuildContext context) {
    // The main screen's back link is quieter than the ones under it.
    final main = subtitle == null;
    final backColor = main ? AppColors.textSecondary : AppColors.brandPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Shrinks rather than overflows on narrow screens or large text.
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: BrandLogo(),
              ),
            ),
            if (fridgeName case final name?) ...[
              const SizedBox(width: 8),
              FridgeSwitcherPill(name: name, onTap: onSwitchFridge),
            ],
          ],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: main ? 4 : 5,
                children: [
                  Icon(LucideIcons.arrowLeft, size: 14, color: backColor),
                  Text(
                    backLabel,
                    style: AppText.nunito(12, FontWeight.w800, backColor),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: main ? 1 : 3),
        Text(
          title,
          style: AppText.nunito(
            main ? 34 : 32,
            FontWeight.w900,
            AppColors.textPrimary,
            height: 1.12,
          ).copyWith(letterSpacing: main ? null : -0.8),
        ),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: AppText.nunito(
              13,
              FontWeight.w400,
              AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
        if (card case final card?) ...[const SizedBox(height: 20), card],
      ],
    );
  }
}

/// The fridge being managed; tapping it switches to another.
class FridgeSwitcherPill extends StatelessWidget {
  const FridgeSwitcherPill({
    super.key,
    required this.name,
    required this.onTap,
  });

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Fridge: $name. Switch fridge',
    excludeSemantics: true,
    child: Material(
      color: AppColors.surfaceBlue,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.nunito(
                    11,
                    FontWeight.w800,
                    AppColors.brandPrimary,
                  ),
                ),
              ),
              const Icon(
                LucideIcons.chevronDown,
                size: 12,
                color: AppColors.brandPrimary,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The light blue card under a sub-screen's title: which fridge, and whose.
class FridgeContextCard extends StatelessWidget {
  const FridgeContextCard({
    super.key,
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceBlue,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      spacing: 10,
      children: [
        const Icon(
          LucideIcons.shieldCheck,
          size: 23,
          color: AppColors.brandPrimary,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 3,
            children: [
              Text(
                title,
                style: AppText.nunito(
                  13,
                  FontWeight.w900,
                  AppColors.textPrimary,
                ),
              ),
              Text(
                detail,
                style: AppText.nunito(
                  11,
                  FontWeight.w400,
                  AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The white, softly shadowed card the management sections sit in.
class ManagementCard extends StatelessWidget {
  const ManagementCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.shadow = AppColors.shadowInk5,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color shadow;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(color: shadow, offset: const Offset(0, 4), blurRadius: 16),
      ],
    ),
    child: child,
  );
}

/// A card's icon and title, with something on the right.
class CardHeading extends StatelessWidget {
  const CardHeading({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 10,
    children: [
      Icon(icon, size: 21, color: AppColors.textPrimary),
      Expanded(
        child: Text(
          title,
          style: AppText.nunito(
            22,
            FontWeight.w900,
            AppColors.textPrimary,
          ).copyWith(letterSpacing: -0.4),
        ),
      ),
      ?trailing,
    ],
  );
}

/// A section's big heading, with a note on the right.
class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: AppText.nunito(24, FontWeight.w900, AppColors.textPrimary),
        ),
      ),
      ?trailing,
    ],
  );
}

/// A small light blue pill: "Owner", "Temporary".
class RoleBadge extends StatelessWidget {
  const RoleBadge(
    this.label, {
    super.key,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
  });

  final String label;
  final IconData? icon;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: const ShapeDecoration(
      color: AppColors.surfaceBlue,
      shape: StadiumBorder(),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        if (icon case final icon?)
          Icon(icon, size: 10, color: AppColors.brandPrimary),
        Text(
          label,
          style: AppText.nunito(10, FontWeight.w900, AppColors.brandPrimary),
        ),
      ],
    ),
  );
}

/// A row of equal-width pills, one of them chosen: storages, filters.
class PillChoices<T> extends StatelessWidget {
  const PillChoices({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 8,
    children: [
      for (final (value, label) in options)
        Expanded(
          child: Semantics(
            button: true,
            selected: value == selected,
            child: Material(
              color: value == selected
                  ? AppColors.brandPrimary
                  : AppColors.surfaceBlue,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onSelected == null ? null : () => onSelected!(value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.nunito(
                      14,
                      FontWeight.w800,
                      value == selected
                          ? AppColors.surface
                          : AppColors.textPrimary,
                      height: 20 / 14,
                    ).copyWith(letterSpacing: 0.014),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

/// The full-width dark blue button at the bottom of a card.
class CardButton extends StatelessWidget {
  const CardButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => Material(
    color: onPressed == null ? AppColors.textSecondary : AppColors.brandPrimary,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: busy ? null : onPressed,
      child: SizedBox(
        height: 46,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            if (busy)
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.surface),
                ),
              )
            else if (icon case final icon?)
              Icon(icon, size: 16, color: AppColors.surface),
            // Shrinks rather than overflows with large text.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.nunito(14, FontWeight.w900, AppColors.surface),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A member's initials in a light blue circle.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar(this.member, {super.key, this.size = 44});

  final FridgeMember member;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: AppColors.surfaceBlue,
      shape: BoxShape.circle,
    ),
    child: member.userId == Fridge.localId
        ? Icon(
            LucideIcons.userRound,
            size: size * 0.45,
            color: AppColors.brandPrimary,
          )
        : Text(
            member.initials,
            style: AppText.nunito(
              size * 14 / 44,
              FontWeight.w900,
              AppColors.brandPrimary,
            ),
          ),
  );
}

/// Says the app is offline, and what that means for this fridge.
class ManagementOfflineNotice extends StatelessWidget {
  const ManagementOfflineNotice({super.key, required this.solo});

  /// Whether the user is alone in the fridge, so changes still work.
  final bool solo;

  @override
  Widget build(BuildContext context) => Container(
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
            solo
                ? "You're offline. Nobody else uses this fridge, so you can "
                      "still change it: it syncs when you're back online."
                : "You're offline. Others use this fridge too, so changes "
                      "wait until you're back online.",
            style: AppText.nunito(12, FontWeight.w600, AppColors.brandPrimary),
          ),
        ),
      ],
    ),
  );
}

/// A one-line message where a section couldn't load.
class SectionMessage extends StatelessWidget {
  const SectionMessage(this.message, {super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      spacing: 4,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppText.nunito(13, FontWeight.w600, AppColors.textSecondary),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}

/// "Home fridge · Maya Patel, owner" for [fridge].
String ownershipLine(Fridge fridge, List<FridgeMember>? members) {
  final owner = members?.where((m) => m.isOwner).firstOrNull;
  if (fridge.isLocal) return '${fridge.name} · on this phone';
  if (owner == null) return fridge.name;
  return '${fridge.name} · ${owner.displayName}, owner';
}

/// "Food & members stay separate from Work." for [fridge], next to [others].
String separationLine(Fridge fridge, List<Fridge> others) {
  if (fridge.isLocal) return 'Sign in to share it with your crew.';
  return switch (others) {
    [] => 'Only its members see its food.',
    [final other] => 'Food & members stay separate from ${other.name}.',
    _ => 'Food & members stay separate from your other fridges.',
  };
}
