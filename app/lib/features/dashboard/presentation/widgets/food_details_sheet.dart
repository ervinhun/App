import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/fridges/domain/fridge_space.dart';

/// A tapped food card: its details, and what can be done with it. The sheet
/// closes before an action runs, so the Dashboard can offer Undo.
Future<void> showFoodDetails(
  BuildContext context, {
  required FoodItem item,
  required DateTime today,
  required List<StorageLocation> moveTo,
  required VoidCallback? onOpened,
  required ValueChanged<StorageLocation> onMoved,
  required VoidCallback onRemoved,
}) {
  final date = DateFormat('EEE, d MMM y');
  final days = item.daysLeft(today);
  void close(VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.icon, size: 32, color: AppColors.brandPrimary),
              title: Text(
                item.name,
                style: AppText.nunito(
                  20,
                  FontWeight.w800,
                  AppColors.textPrimary,
                ),
              ),
              subtitle: Text('${item.amount} · ${item.storage.label}'),
            ),
            for (final (label, value) in [
              ('Type', item.productType),
              ('Best before', date.format(item.bestBefore)),
              if (item.openedOn case final opened?)
                ('Opened', date.format(opened)),
              (
                'Eat by',
                '${date.format(item.expiresOn)} · ${switch (days) {
                  < 0 => 'expired ${-days} d ago',
                  0 => 'today',
                  _ => 'in $days d',
                }}',
              ),
            ])
              Text.rich(
                TextSpan(
                  text: '$label  ',
                  style: AppText.nunito(
                    14,
                    FontWeight.w800,
                    AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: value,
                      style: AppText.nunito(
                        14,
                        FontWeight.w600,
                        AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onOpened != null)
                  FilledButton(
                    onPressed: () => close(onOpened),
                    child: const Text('Mark opened'),
                  ),
                for (final to in moveTo)
                  OutlinedButton(
                    onPressed: () => close(() => onMoved(to)),
                    child: Text('Move to ${to.label}'),
                  ),
                TextButton(
                  onPressed: () => close(onRemoved),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
