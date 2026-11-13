import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/features/dashboard/presentation/widgets/food_card.dart';
import 'package:app/features/food/data/product_catalog_api.dart';
import 'package:app/features/food/domain/food_icons.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/food/domain/product_type.dart';

/// Asks which product type something is, from the backend's catalogue: first
/// the category, then a type in it. Only lists types that are kept in
/// [storage], with how long they keep there. Starts in [category] when given,
/// e.g. the category of the type picked before.
Future<ProductType?> showProductTypePicker(
  BuildContext context, {
  required StorageLocation storage,
  String? category,
}) => showModalBottomSheet<ProductType>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppColors.canvas,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.85,
    child: _ProductTypePicker(storage: storage, initialCategory: category),
  ),
);

/// An icon on a food group's colour, as on the Expiry Defaults screen.
class _Emblem extends StatelessWidget {
  const _Emblem({required this.icon, required this.group});

  final IconData icon;
  final FoodCategory group;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 34,
    decoration: BoxDecoration(
      color: FoodCard.categoryColor(group),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 17, color: AppColors.textPrimary),
  );
}

/// A product type's icon on its food group's colour.
class ProductTypeEmblem extends StatelessWidget {
  const ProductTypeEmblem(this.type, {super.key});

  final ProductType type;

  @override
  Widget build(BuildContext context) =>
      _Emblem(icon: type.icon, group: type.group);
}

class _ProductTypePicker extends ConsumerStatefulWidget {
  const _ProductTypePicker({required this.storage, this.initialCategory});

  final StorageLocation storage;
  final String? initialCategory;

  @override
  ConsumerState<_ProductTypePicker> createState() => _ProductTypePickerState();
}

class _ProductTypePickerState extends ConsumerState<_ProductTypePicker> {
  final _search = TextEditingController();
  String _query = '';

  /// The category whose types are shown; null while choosing a category.
  late String? _category = widget.initialCategory;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openCategory(String? category) {
    _search.clear();
    setState(() {
      _category = category;
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(productTypesProvider);
    final category = _category;
    // Back steps out of a category before it closes the sheet.
    return PopScope(
      canPop: category == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _openCategory(null);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (category != null) ...[
              _BackToCategories(onTap: () => _openCategory(null)),
              const SizedBox(height: 4),
            ],
            Text(
              category == null
                  ? 'What is it?'
                  : (category.isEmpty ? 'Other' : category),
              style: AppText.nunito(
                22,
                FontWeight.w900,
                AppColors.textPrimary,
              ).copyWith(letterSpacing: -0.4),
            ),
            const SizedBox(height: 2),
            Text(
              'Food that keeps in the ${widget.storage.name}',
              style: AppText.nunito(12, FontWeight.w400, AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _SearchField(
              controller: _search,
              hint: category == null
                  ? 'Search all types'
                  : 'Search ${category.isEmpty ? 'other' : category}',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: switch (types) {
                AsyncData(:final value) => _buildList(value),
                AsyncError(:final error) => _LoadError(
                  message: ApiException.messageFor(error),
                  onRetry: () => ref.invalidate(productTypesProvider),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ProductType> all) {
    final category = _category;
    final query = _query.trim().toLowerCase();
    void select(ProductType type) => Navigator.pop(context, type);
    final fitting = [
      for (final type in all)
        if (type.keepsIn(widget.storage)) type,
    ];

    if (category == null && query.isEmpty) {
      return _CategoryList(types: fitting, onSelected: _openCategory);
    }
    // Searching from the top looks through every category.
    final inScope = [
      for (final type in fitting)
        if (category == null || type.category == category) type,
    ];
    final matches = [
      for (final type in inScope)
        if (type.name.toLowerCase().contains(query) ||
            (category == null && type.category.toLowerCase().contains(query)))
          type,
    ];
    return _TypeList(
      types: matches,
      storage: widget.storage,
      showCategories: category == null,
      onSelected: select,
    );
  }
}

class _BackToCategories extends StatelessWidget {
  const _BackToCategories({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            const Icon(
              LucideIcons.arrowLeft,
              size: 14,
              color: AppColors.brandPrimary,
            ),
            Text(
              'All categories',
              style: AppText.nunito(
                12,
                FontWeight.w800,
                AppColors.brandPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Each category once, with how many types it has.
class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.types, required this.onSelected});

  final List<ProductType> types;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final type in types) {
      counts[type.category] = (counts[type.category] ?? 0) + 1;
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final MapEntry(key: category, value: count) in counts.entries)
          InkWell(
            onTap: () => onSelected(category),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                spacing: 8,
                children: [
                  _Emblem(
                    icon:
                        FoodIcons.categoryIcons[category] ?? FoodIcons.fallback,
                    group: FoodCategory.fromProduct(category, ''),
                  ),
                  Expanded(
                    child: Text(
                      category.isEmpty ? 'Other' : category,
                      style: AppText.nunito(
                        13,
                        FontWeight.w800,
                        AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    count == 1 ? '1 type' : '$count types',
                    style: AppText.nunito(
                      11,
                      FontWeight.w400,
                      AppColors.textSecondary,
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: AppColors.brandAccent,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.textSecondary),
    );
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.brandAccent,
        style: AppText.nunito(13, FontWeight.w600, AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.nunito(
            12,
            FontWeight.w400,
            AppColors.textSecondary,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              LucideIcons.search,
              size: 16,
              color: AppColors.brandAccent,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.only(right: 12),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.brandAccent),
          ),
        ),
      ),
    );
  }
}

/// The types, under their category's name when [showCategories].
class _TypeList extends StatelessWidget {
  const _TypeList({
    required this.types,
    required this.storage,
    required this.showCategories,
    required this.onSelected,
  });

  final List<ProductType> types;
  final StorageLocation storage;
  final bool showCategories;
  final ValueChanged<ProductType> onSelected;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(
          'No types match.',
          textAlign: TextAlign.center,
          style: AppText.nunito(14, FontWeight.w600, AppColors.textSecondary),
        ),
      );
    }
    final rows = <Widget>[];
    String? category;
    for (final type in types) {
      if (showCategories && type.category != category) {
        category = type.category;
        rows.add(
          Padding(
            padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 16, bottom: 4),
            child: Text(
              category.isEmpty ? 'Other' : category,
              style: AppText.nunito(11, FontWeight.w800, AppColors.textPrimary),
            ),
          ),
        );
      }
      rows.add(
        _TypeRow(
          type,
          days: type.expiryDaysIn(storage)!,
          onTap: () => onSelected(type),
        ),
      );
    }
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: rows);
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow(this.type, {required this.days, required this.onTap});

  final ProductType type;

  /// How long it keeps where it's going.
  final int days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        spacing: 8,
        children: [
          ProductTypeEmblem(type),
          Expanded(
            child: Text(
              type.name,
              style: AppText.nunito(13, FontWeight.w800, AppColors.textPrimary),
            ),
          ),
          Text(
            '$days d',
            style: AppText.nunito(11, FontWeight.w400, AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 24),
      Text(
        message,
        textAlign: TextAlign.center,
        style: AppText.nunito(14, FontWeight.w600, AppColors.textPrimary),
      ),
      TextButton(onPressed: onRetry, child: const Text('Try again')),
    ],
  );
}
