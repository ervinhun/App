import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/features/food/domain/food_item.dart';

final _shortDate = DateFormat('d MMM');

/// A food item on the dashboard, tinted by category with an urgency-coloured
/// edge. [compact] is the two-column grid layout.
///
/// It has square corners: SwipeableFoodCard rounds it, together with what
/// shows behind it, so its edge meets that cleanly while it slides.
class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.item,
    required this.today,
    this.compact = false,
    this.showStatusEdge = true,
  });

  final FoodItem item;
  final DateTime today;
  final bool compact;

  /// Fades the urgency-coloured edge out, keeping its space, e.g. while the
  /// card is being swiped.
  final bool showStatusEdge;

  @override
  Widget build(BuildContext context) {
    final urgency = item.urgency(today);
    final statusColor = urgencyColor(urgency);
    final background = categoryColor(item.category);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: BoxConstraints(
        minHeight: compact || urgency != ExpiryUrgency.soon ? 88 : 100,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        border: Border(
          right: BorderSide(
            color: showStatusEdge ? statusColor : background,
            width: 4,
          ),
        ),
      ),
      child: compact ? _buildCompact(statusColor) : _buildRow(statusColor),
    );
  }

  Widget _buildRow(Color statusColor) => Row(
    children: [
      _FoodIcon(item),
      const SizedBox(width: 12),
      Expanded(child: _Details(item)),
      const SizedBox(width: 12),
      // At least the design's 52 px, wider for "150 days"; the details shrink.
      ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 52),
        child: _ExpiryIndicator(item, today: today, color: statusColor),
      ),
    ],
  );

  Widget _buildCompact(Color statusColor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FoodIcon(item),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _ExpiryIndicator(item, today: today, color: statusColor),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _Details(item),
    ],
  );

  static Color urgencyColor(ExpiryUrgency urgency) => switch (urgency) {
    ExpiryUrgency.soon => AppColors.statusSoon,
    ExpiryUrgency.upcoming => AppColors.statusUpcoming,
    ExpiryUrgency.later => AppColors.statusFresh,
  };

  // The design has no fish or "other" colour yet, so those use the plain blue.
  static Color categoryColor(FoodCategory category) => switch (category) {
    FoodCategory.meat => AppColors.categoryMeat,
    FoodCategory.dairy => AppColors.categoryDairy,
    FoodCategory.veg => AppColors.categoryProduce,
    FoodCategory.eggs => AppColors.categoryEggs,
    FoodCategory.fish || FoodCategory.other => AppColors.surfaceBlue,
  };
}

/// The food's icon, chosen from its product category and type.
class _FoodIcon extends StatelessWidget {
  const _FoodIcon(this.item);

  final FoodItem item;

  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      item.icon,
      size: 30,
      color: AppColors.brandPrimary,
      semanticLabel: item.productType,
    ),
  );
}

class _Details extends StatelessWidget {
  const _Details(this.item);

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final openedOn = item.openedOn;
    final openedExpiresOn = item.openedExpiresOn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: AppText.nunito(15, FontWeight.w800, AppColors.textPrimary),
        ),
        const SizedBox(height: 3),
        Text(
          [
            if (item.amount.isNotEmpty) item.amount,
            openedOn == null
                ? 'Unopened'
                : 'Opened ${_shortDate.format(openedOn)}',
          ].join(' · '),
          style: AppText.nunito(12, FontWeight.w500, AppColors.brandPrimary),
        ),
        if (openedExpiresOn != null) ...[
          const SizedBox(height: 4),
          _ExpirySticker(from: item.bestBefore, to: openedExpiresOn),
        ],
      ],
    );
  }
}

/// "2 Nov → 29 Oct": the printed date, and the earlier one now it's open.
class _ExpirySticker extends StatelessWidget {
  const _ExpirySticker({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.surfaceBlue,
      border: Border.all(color: AppColors.textSecondary),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          LucideIcons.alarmClock,
          size: 11,
          color: AppColors.brandAccent,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${_shortDate.format(from)} → ${_shortDate.format(to)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.nunito(10, FontWeight.w700, AppColors.brandPrimary),
          ),
        ),
      ],
    ),
  );
}

class _ExpiryIndicator extends StatelessWidget {
  const _ExpiryIndicator(this.item, {required this.today, required this.color});

  final FoodItem item;
  final DateTime today;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final days = item.daysLeft(today);
    return Column(
      children: [
        Text(
          switch (days) {
            < 0 => 'Expired',
            0 => 'Today',
            1 => '1 day',
            _ => '$days days',
          },
          maxLines: 1,
          style: AppText.nunito(16, FontWeight.w800, color),
        ),
        const SizedBox(height: 1),
        Text(
          _shortDate.format(item.expiresOn),
          style: AppText.nunito(10, FontWeight.w500, AppColors.brandPrimary),
        ),
      ],
    );
  }
}
