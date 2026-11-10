import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/features/food/domain/food_item.dart';

/// The chips under the search field.
enum FoodFilter {
  all('All'),
  expiring('Expiring'),
  dairy('Dairy'),
  veg('Veg'),
  meat('Meat'),
  fish('Fish');

  const FoodFilter(this.label);

  final String label;

  bool matches(FoodItem item, DateTime today) => switch (this) {
    all => true,
    expiring => item.urgency(today) == ExpiryUrgency.soon,
    dairy => item.category == FoodCategory.dairy,
    veg => item.category == FoodCategory.veg,
    meat => item.category == FoodCategory.meat,
    fish => item.category == FoodCategory.fish,
  };
}

enum FoodView { grid, list }

class FoodSearchField extends StatelessWidget {
  const FoodSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.textSecondary),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowInk10,
            offset: Offset(0, 1),
            blurRadius: 6,
          ),
        ],
      ),
      child: SizedBox(
        height: 46,
        child: TextField(
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          cursorColor: AppColors.brandAccent,
          style: AppText.nunito(13, FontWeight.w500, AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search food',
            hintStyle: AppText.nunito(
              13,
              FontWeight.w500,
              AppColors.textSecondary,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 9),
              child: Icon(
                LucideIcons.search,
                size: 16,
                color: AppColors.brandAccent,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
            filled: true,
            fillColor: AppColors.surfaceBlue,
            contentPadding: const EdgeInsets.only(right: 14),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: AppColors.brandAccent),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter chips, which scroll sideways, and the grid/list toggle.
class FoodFilterBar extends StatelessWidget {
  const FoodFilterBar({
    super.key,
    required this.selected,
    required this.counts,
    required this.view,
    required this.onSelected,
    required this.onViewChanged,
    required this.onMoreFilters,
  });

  final FoodFilter selected;

  /// Shown next to the label, for the filters that have one.
  final Map<FoodFilter, int> counts;
  final FoodView view;
  final ValueChanged<FoodFilter> onSelected;
  final ValueChanged<FoodView> onViewChanged;
  final VoidCallback onMoreFilters;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              _RoundButton(
                tooltip: 'More filters',
                onTap: onMoreFilters,
                child: const Icon(
                  LucideIcons.slidersHorizontal,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              for (final filter in FoodFilter.values)
                _Chip(
                  label: [
                    filter.label,
                    if (counts[filter] case final count?) '$count',
                  ].join(' '),
                  selected: filter == selected,
                  onTap: () => onSelected(filter),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 12),
      _ViewToggle(view: view, onChanged: onViewChanged),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? AppColors.brandAccent : AppColors.surfaceBlue,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: AppText.labelLarge(
              selected ? AppColors.surface : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: AppColors.surfaceBlue,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(dimension: 36, child: Center(child: child)),
      ),
    ),
  );
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.onChanged});

  final FoodView view;
  final ValueChanged<FoodView> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: const ShapeDecoration(
      color: AppColors.surfaceBlue,
      shape: StadiumBorder(),
    ),
    child: Row(
      spacing: 4,
      children: [
        for (final (option, icon, tooltip) in [
          (FoodView.grid, LucideIcons.layoutGrid, 'Grid view'),
          (FoodView.list, LucideIcons.list, 'List view'),
        ])
          Tooltip(
            message: tooltip,
            child: Semantics(
              selected: option == view,
              child: Material(
                color: option == view
                    ? AppColors.brandAccent
                    : AppColors.surfaceBlue,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onChanged(option),
                  child: SizedBox(
                    width: 40,
                    height: 32,
                    child: Center(
                      child: Icon(
                        icon,
                        size: 18,
                        color: option == view
                            ? AppColors.surface
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Fridge / Freezer / Pantry, with how many items each holds.
class StorageTabs extends StatelessWidget {
  const StorageTabs({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final StorageLocation selected;
  final Map<StorageLocation, int> counts;
  final ValueChanged<StorageLocation> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 6,
    children: [
      for (final (location, icon, label) in [
        (StorageLocation.fridge, LucideIcons.refrigerator, 'Fridge'),
        (StorageLocation.freezer, LucideIcons.snowflake, 'Freezer'),
        (StorageLocation.pantry, LucideIcons.archive, 'Pantry'),
      ])
        Expanded(
          child: _StorageTab(
            icon: icon,
            label: label,
            count: counts[location] ?? 0,
            active: location == selected,
            onTap: () => onSelected(location),
          ),
        ),
    ],
  );
}

class _StorageTab extends StatelessWidget {
  const _StorageTab({
    required this.icon,
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: active
          ? BorderSide.none
          : const BorderSide(color: AppColors.textSecondary),
    );
    return Semantics(
      selected: active,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: AppColors.shadowInk25,
                    offset: Offset(0, 3),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: active ? AppColors.brandPrimary : AppColors.surfaceBlue,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: active ? AppColors.surface : AppColors.brandAccent,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.nunito(
                        12,
                        active ? FontWeight.w800 : FontWeight.w700,
                        active ? AppColors.surface : AppColors.brandPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: AppText.nunito(
                      12,
                      FontWeight.w500,
                      active ? AppColors.surface : AppColors.textSecondary,
                    ),
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
