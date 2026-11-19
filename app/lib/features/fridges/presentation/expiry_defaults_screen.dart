import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/core/widgets/adaptive.dart';
import 'package:app/features/dashboard/presentation/widgets/food_card.dart';
import 'package:app/features/food/data/expiry_defaults_controller.dart';
import 'package:app/features/food/data/product_catalog_api.dart';
import 'package:app/features/food/domain/expiry_defaults.dart';
import 'package:app/features/food/domain/food_icons.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/food/domain/product_type.dart';
import 'package:app/features/fridges/presentation/fridge_actions.dart';
import 'package:app/features/fridges/presentation/widgets/management_page.dart';
import 'package:app/features/fridges/presentation/widgets/management_widgets.dart';

/// How long food keeps, by storage, product category and product type.
///
/// The backend has a catalogue of how long each type keeps unopened, but no
/// place for anyone's own rules, so these are saved on the phone and used
/// when food is added or opened here. That makes them each person's own,
/// rather than the owner's for the whole fridge as in the design. An empty
/// field goes by what's shown faintly in it: the category's rule, else the
/// catalogue's, or for opened food, a suggestion for the food group.
class ExpiryDefaultsScreen extends StatelessWidget {
  const ExpiryDefaultsScreen({super.key});

  @override
  Widget build(BuildContext context) => ManagementPage(
    title: 'A little housekeeping.',
    subtitle:
        'Set expiry rules, keep your crew in the loop, and see what’s changed.',
    builder: (context, fridge) => [const _ExpiryDefaultsCard()],
  );
}

class _ExpiryDefaultsCard extends ConsumerStatefulWidget {
  const _ExpiryDefaultsCard();

  @override
  ConsumerState<_ExpiryDefaultsCard> createState() =>
      _ExpiryDefaultsCardState();
}

class _ExpiryDefaultsCardState extends ConsumerState<_ExpiryDefaultsCard> {
  StorageLocation _storage = StorageLocation.fridge;

  /// The user's changes, until saved; null to show what's saved.
  ExpiryDefaults? _draft;
  final _open = <String>{};

  ExpiryDefaults get _saved =>
      ref.read(expiryDefaultsProvider).value ?? ExpiryDefaults.none;

  bool get _dirty => _draft != null && !mapEquals(_draft!.rules, _saved.rules);

  void _edit(String key, ExpiryRule rule) =>
      setState(() => _draft = (_draft ?? _saved).withRule(key, rule));

  Future<void> _save() async {
    await ref.read(expiryDefaultsProvider.notifier).change(_draft!);
    if (!mounted) return;
    setState(() => _draft = null);
    FridgeActions.showMessage(context, 'Expiry defaults saved');
  }

  Future<void> _reset() async {
    final confirmed = await Adaptive.confirm(
      context,
      title: 'Reset expiry defaults?',
      message: 'Every storage goes back to the suggested times.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(expiryDefaultsProvider.notifier).change(ExpiryDefaults.none);
    if (!mounted) return;
    setState(() => _draft = null);
    FridgeActions.showMessage(context, 'Back to the suggested times');
  }

  /// Leaving with unsaved changes asks first.
  Future<void> _confirmLeave() async {
    final discard = await Adaptive.confirm(
      context,
      title: 'Discard your changes?',
      message: "Your expiry defaults haven't been saved.",
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (!discard || !mounted) return;
    setState(() => _draft = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(productTypesProvider);
    final saved = ref.watch(expiryDefaultsProvider).value;
    final defaults = _draft ?? saved ?? ExpiryDefaults.none;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: ManagementCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            const CardHeading(
              icon: LucideIcons.calendarDays,
              title: 'Expiry defaults',
            ),
            Text(
              'Choose a storage type, then edit how long each product '
              'category keeps. Saved on this phone, and used when you add or '
              'open food here.',
              style: AppText.nunito(
                13,
                FontWeight.w400,
                AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            PillChoices(
              options: const [
                (StorageLocation.fridge, 'Fridge'),
                (StorageLocation.freezer, 'Freezer'),
                (StorageLocation.pantry, 'Pantry'),
              ],
              selected: _storage,
              onSelected: (storage) => setState(() {
                _storage = storage;
                _open.clear();
              }),
            ),
            switch (catalogue) {
              AsyncData(:final value) => _Rules(
                // New fields for the other storage, with its values.
                key: ValueKey(_storage),
                storage: _storage,
                types: value,
                defaults: defaults,
                open: _open,
                onToggle: (category) => setState(
                  () => _open.contains(category)
                      ? _open.remove(category)
                      : _open.add(category),
                ),
                onChanged: _edit,
              ),
              AsyncError(:final error) => SectionMessage(
                ApiException.messageFor(error),
                onRetry: () => ref.invalidate(productTypesProvider),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
            },
            CardButton(
              label: 'Save defaults',
              icon: LucideIcons.check,
              onPressed: _dirty ? _save : null,
            ),
            if ((saved?.rules.isNotEmpty ?? false) && _draft == null)
              Center(
                child: TextButton(
                  onPressed: _reset,
                  child: Text(
                    'Reset to the suggested times',
                    style: AppText.nunito(
                      13,
                      FontWeight.w800,
                      AppColors.brandPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The rules for one storage: a row per product category, each opening onto
/// its types.
class _Rules extends StatelessWidget {
  const _Rules({
    super.key,
    required this.storage,
    required this.types,
    required this.defaults,
    required this.open,
    required this.onToggle,
    required this.onChanged,
  });

  final StorageLocation storage;
  final List<ProductType> types;
  final ExpiryDefaults defaults;
  final Set<String> open;
  final ValueChanged<String> onToggle;
  final void Function(String key, ExpiryRule rule) onChanged;

  @override
  Widget build(BuildContext context) {
    // What the catalogue keeps here, by category; sorted as it comes.
    final byCategory = <String, List<ProductType>>{};
    for (final type in types) {
      if (type.keepsIn(storage)) {
        byCategory.putIfAbsent(type.category, () => []).add(type);
      }
    }
    final label =
        '${storage.name[0].toUpperCase()}${storage.name.substring(1)} rules';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 10,
          children: [
            Expanded(child: Text(label, style: _headingStyle(11))),
            SizedBox(
              width: 72,
              child: Text(
                'Unopened',
                textAlign: TextAlign.center,
                style: _headingStyle(10),
              ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                'Once opened',
                textAlign: TextAlign.center,
                style: _headingStyle(10),
              ),
            ),
          ],
        ),
        if (byCategory.isEmpty)
          const SectionMessage('Nothing is usually kept here.'),
        for (final MapEntry(key: category, value: inCategory)
            in byCategory.entries) ...[
          _CategoryRow(
            category: category,
            rule: defaults.rule(storage, category),
            open: open.contains(category),
            onToggle: () => onToggle(category),
            onChanged: (rule) =>
                onChanged(ExpiryDefaults.key(storage, category), rule),
          ),
          if (open.contains(category))
            _TypeRules(
              category: category,
              types: inCategory,
              storage: storage,
              defaults: defaults,
              onChanged: onChanged,
            ),
        ],
      ],
    );
  }
}

TextStyle _headingStyle(double size) =>
    AppText.nunito(size, FontWeight.w800, AppColors.textPrimary);

String _categoryName(String category) => category.isEmpty ? 'Other' : category;

FoodCategory _group(String category, [String type = '']) =>
    FoodCategory.fromProduct(category, type);

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.rule,
    required this.open,
    required this.onToggle,
    required this.onChanged,
  });

  final String category;
  final ExpiryRule rule;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<ExpiryRule> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 10,
    children: [
      Expanded(
        child: Semantics(
          button: true,
          expanded: open,
          label: '${_categoryName(category)} types',
          excludeSemantics: true,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              spacing: 8,
              children: [
                _Emblem(
                  group: _group(category),
                  icon: FoodIcons.categoryIcons[category] ?? FoodIcons.fallback,
                ),
                Flexible(
                  child: Text(
                    _categoryName(category),
                    style: AppText.nunito(
                      13,
                      FontWeight.w900,
                      AppColors.textPrimary,
                    ),
                  ),
                ),
                // The design's "▾", which Nunito doesn't have.
                Icon(
                  open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 12,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
      SizedBox(
        width: 72,
        child: _DaysField(
          label: '${_categoryName(category)}, unopened',
          value: rule.unopened,
          // Each type keeps its own time unless the category has one.
          hint: '–',
          onChanged: (days) =>
              onChanged(ExpiryRule(unopened: days, opened: rule.opened)),
        ),
      ),
      SizedBox(
        width: 72,
        child: _DaysField(
          label: '${_categoryName(category)}, once opened',
          value: rule.opened,
          hint: '${ExpiryDefaults.suggestedOpenedDays[_group(category)]}',
          onChanged: (days) =>
              onChanged(ExpiryRule(unopened: rule.unopened, opened: days)),
        ),
      ),
    ],
  );
}

/// A category's types, to give one its own rule; searchable.
class _TypeRules extends StatefulWidget {
  const _TypeRules({
    required this.category,
    required this.types,
    required this.storage,
    required this.defaults,
    required this.onChanged,
  });

  final String category;
  final List<ProductType> types;
  final StorageLocation storage;
  final ExpiryDefaults defaults;
  final void Function(String key, ExpiryRule rule) onChanged;

  @override
  State<_TypeRules> createState() => _TypeRulesState();
}

class _TypeRulesState extends State<_TypeRules> {
  String _query = '';
  int _shown = 15;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final storage = widget.storage;
    final defaults = widget.defaults;
    final categoryRule = defaults.rule(storage, category);
    final query = _query.trim().toLowerCase();
    final matches = [
      for (final type in widget.types)
        if (type.name.toLowerCase().contains(query)) type,
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            '${_categoryName(category)} subcategories',
            style: AppText.nunito(13, FontWeight.w900, AppColors.textPrimary),
          ),
          SizedBox(
            height: 36,
            child: TextField(
              onChanged: (value) => setState(() {
                _query = value;
                _shown = 15;
              }),
              textInputAction: TextInputAction.search,
              style: AppText.nunito(12, FontWeight.w600, AppColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.surface,
                hintText: 'Search subcategories',
                hintStyle: AppText.nunito(
                  12,
                  FontWeight.w400,
                  AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 36),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: _border(AppColors.textSecondary),
                focusedBorder: _border(AppColors.brandPrimary),
              ),
            ),
          ),
          if (matches.isEmpty)
            Text(
              'No types match.',
              style: AppText.nunito(
                12,
                FontWeight.w600,
                AppColors.textSecondary,
              ),
            ),
          for (final type in matches.take(_shown))
            _TypeRule(
              type: type,
              storage: storage,
              rule: defaults.rule(storage, category, type.name),
              unopenedHint: categoryRule.unopened ?? type.expiryDaysIn(storage),
              openedHint:
                  categoryRule.opened ??
                  ExpiryDefaults.suggestedOpenedDays[_group(
                    category,
                    type.name,
                  )]!,
              onChanged: (rule) => widget.onChanged(
                ExpiryDefaults.key(storage, category, type.name),
                rule,
              ),
            ),
          if (matches.length > _shown)
            TextButton(
              onPressed: () => setState(() => _shown += 15),
              child: Text(
                'Show ${matches.length - _shown} more',
                style: AppText.nunito(
                  13,
                  FontWeight.w900,
                  AppColors.brandPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeRule extends StatelessWidget {
  const _TypeRule({
    required this.type,
    required this.storage,
    required this.rule,
    required this.unopenedHint,
    required this.openedHint,
    required this.onChanged,
  });

  final ProductType type;
  final StorageLocation storage;
  final ExpiryRule rule;
  final int? unopenedHint;
  final int openedHint;
  final ValueChanged<ExpiryRule> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      Row(
        spacing: 8,
        children: [
          _Emblem(group: type.group, icon: type.icon),
          Expanded(
            child: Text(
              type.name,
              style: AppText.nunito(13, FontWeight.w800, AppColors.textPrimary),
            ),
          ),
        ],
      ),
      Row(
        spacing: 8,
        children: [
          Expanded(
            child: _LabelledField(
              label: 'Unopened',
              field: _DaysField(
                label: '${type.name}, unopened',
                value: rule.unopened,
                hint: unopenedHint?.toString() ?? '–',
                onChanged: (days) =>
                    onChanged(ExpiryRule(unopened: days, opened: rule.opened)),
              ),
            ),
          ),
          Expanded(
            child: _LabelledField(
              label: 'Once opened',
              field: _DaysField(
                label: '${type.name}, once opened',
                value: rule.opened,
                hint: '$openedHint',
                onChanged: (days) => onChanged(
                  ExpiryRule(unopened: rule.unopened, opened: days),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _LabelledField extends StatelessWidget {
  const _LabelledField({required this.label, required this.field});

  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 4,
    children: [
      ExcludeSemantics(child: Text(label, style: _headingStyle(10))),
      field,
    ],
  );
}

/// The category's tinted tile with its icon.
class _Emblem extends StatelessWidget {
  const _Emblem({required this.group, required this.icon});

  final FoodCategory group;
  final IconData icon;

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

/// A number of days: what the user set, or, faintly, what it goes by.
class _DaysField extends StatefulWidget {
  const _DaysField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final String hint;

  /// Null when the field was emptied.
  final ValueChanged<int?> onChanged;

  @override
  State<_DaysField> createState() => _DaysFieldState();
}

class _DaysFieldState extends State<_DaysField> {
  late final _text = TextEditingController(text: widget.value?.toString());

  @override
  void didUpdateWidget(_DaysField old) {
    super.didUpdateWidget(old);
    // Saved, reset or discarded: show the value it now has.
    if (widget.value != int.tryParse(_text.text)) {
      _text.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: Semantics(
      label: widget.label,
      child: TextField(
        controller: _text,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        onChanged: (text) => widget.onChanged(int.tryParse(text)),
        style: AppText.nunito(15, FontWeight.w900, AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.surface,
          hintText: widget.hint,
          hintStyle: AppText.nunito(
            15,
            FontWeight.w900,
            AppColors.textSecondary,
          ),
          // An icon rather than suffixText, which hides while it's empty.
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 11),
            child: Text(
              'd',
              style: AppText.nunito(11, FontWeight.w400, AppColors.textPrimary),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 11,
          ),
          enabledBorder: _border(AppColors.textSecondary),
          focusedBorder: _border(AppColors.brandPrimary),
        ),
      ),
    ),
  );
}

OutlineInputBorder _border(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: color),
);
