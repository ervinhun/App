import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/features/food/data/food_items_controller.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/food/domain/product_type.dart';
import 'package:app/features/food/presentation/widgets/product_type_picker.dart';

/// "Add manual": type in something that wasn't scanned.
///
/// Pops with the new [FoodItem] once it's been added.
class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key, this.storage = StorageLocation.fridge});

  /// Where it goes unless the user picks somewhere else.
  final StorageLocation storage;

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  late StorageLocation _storage = widget.storage;
  ProductType? _type;
  DateTime? _bestBefore;

  /// Whether the user picked the date, rather than taking the suggestion.
  bool _datePicked = false;
  bool _showTypeError = false;

  /// Why the type was cleared, after the user moved it somewhere it isn't
  /// kept.
  String? _typeNote;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickType() async {
    final type = await showProductTypePicker(
      context,
      storage: _storage,
      category: _type?.category,
    );
    if (type == null || !mounted) return;
    setState(() {
      // Keep a name the user typed; replace one we filled in.
      if (_name.text.trim().isEmpty || _name.text == _type?.name) {
        _name.text = type.name;
      }
      _type = type;
      _showTypeError = false;
      _typeNote = null;
      _suggestDate();
    });
  }

  /// Suggests when it's best before from its type and where it goes, unless
  /// the user picked a date.
  void _suggestDate() {
    final days = _type?.expiryDaysIn(_storage);
    if (days == null || _datePicked) return;
    _bestBefore = _today.add(Duration(days: days));
  }

  /// The picker only offers what's kept in [storage], so a type that isn't is
  /// cleared, along with what was filled in from it.
  void _changeStorage(StorageLocation storage) {
    setState(() {
      _storage = storage;
      final type = _type;
      if (type == null || type.keepsIn(storage)) {
        _suggestDate();
        return;
      }
      if (_name.text == type.name) _name.clear();
      if (!_datePicked) _bestBefore = null;
      _type = null;
      _typeNote =
          "${type.name} isn't usually kept in the ${storage.name}. "
          'Choose what it is again.';
    });
  }

  Future<void> _pickDate() async {
    final today = _today;
    final date = await showDatePicker(
      context: context,
      initialDate: _bestBefore ?? today,
      firstDate: today.subtract(const Duration(days: 30)),
      lastDate: today.add(const Duration(days: 365 * 5)),
      helpText: 'Best before',
    );
    if (date == null) return;
    setState(() {
      _bestBefore = date;
      _datePicked = true;
    });
  }

  void _save() {
    final type = _type;
    final valid = _formKey.currentState!.validate();
    setState(() => _showTypeError = type == null);
    if (!valid || type == null) return;

    final item = FoodItem(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      amount: _amount.text.trim(),
      category: type.group,
      productCategory: type.category,
      productType: type.name,
      storage: _storage,
      bestBefore:
          _bestBefore ??
          _today.add(
            Duration(
              days: type.expiryDaysIn(_storage) ?? type.defaultExpiryDays,
            ),
          ),
    );
    ref.read(foodItemsProvider.notifier).add(item);
    context.pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final bestBefore = _bestBefore;
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
              children: [
                _BackLink(onTap: () => context.pop()),
                const SizedBox(height: 7),
                Text(
                  'Add food by hand.',
                  style: AppText.nunito(
                    32,
                    FontWeight.w900,
                    AppColors.textPrimary,
                    height: 1.12,
                  ).copyWith(letterSpacing: -0.8),
                ),
                const SizedBox(height: 7),
                Text(
                  "Pick what it is and we'll suggest when it needs eating.",
                  style: AppText.nunito(
                    13,
                    FontWeight.w400,
                    AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                _FormCard(
                  children: [
                    _Field(
                      label: 'Where does it go?',
                      child: _StorageChoices(
                        selected: _storage,
                        onSelected: _changeStorage,
                      ),
                    ),
                    _Field(
                      label: 'What is it?',
                      error: _showTypeError ? 'Choose what it is.' : null,
                      note: _typeNote,
                      child: _TypeField(type: _type, onTap: _pickType),
                    ),
                    _Field(
                      label: 'Name',
                      child: _TextInput(
                        controller: _name,
                        hint: 'e.g. Greek yoghurt',
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Give it a name.'
                            : null,
                      ),
                    ),
                    _Field(
                      label: 'Amount (optional)',
                      child: _TextInput(
                        controller: _amount,
                        hint: 'e.g. 500 g',
                      ),
                    ),
                    _Field(
                      label: 'Best before',
                      child: _DateField(
                        date: bestBefore,
                        suggested: bestBefore != null && !_datePicked,
                        onTap: _pickDate,
                      ),
                    ),
                    _PrimaryButton(
                      label: 'Add to ${_storage.name}',
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
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
              'Back to my food',
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

/// The white, rounded panel the form sits in.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D0D4F6B),
          offset: Offset(0, 4),
          blurRadius: 16,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: children,
    ),
  );
}

/// A small label above a control, and an error under it.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.error,
    this.note,
  });

  final String label;
  final Widget child;
  final String? error;

  /// A hint under the control, shown when there's no [error].
  final String? note;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppText.nunito(11, FontWeight.w800, AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        child,
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: AppText.nunito(11, FontWeight.w600, AppColors.statusSoon),
          ),
        ] else if (note case final note?) ...[
          const SizedBox(height: 4),
          Text(
            note,
            style: AppText.nunito(11, FontWeight.w600, AppColors.brandPrimary),
          ),
        ],
      ],
    );
  }
}

BoxDecoration _outlined({bool error = false}) => BoxDecoration(
  color: AppColors.surface,
  border: Border.all(
    color: error ? AppColors.statusSoon : AppColors.textSecondary,
  ),
  borderRadius: BorderRadius.circular(12),
);

class _TypeField extends StatelessWidget {
  const _TypeField({required this.type, required this.onTap});

  final ProductType? type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = this.type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: _outlined(),
          child: Row(
            spacing: 8,
            children: [
              if (type == null) ...[
                const SizedBox(width: 3),
                const Icon(
                  LucideIcons.search,
                  size: 16,
                  color: AppColors.brandAccent,
                ),
                Expanded(
                  child: Text(
                    'Choose a type',
                    style: AppText.nunito(
                      13,
                      FontWeight.w400,
                      AppColors.textSecondary,
                    ),
                  ),
                ),
              ] else ...[
                ProductTypeEmblem(type),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.nunito(
                          13,
                          FontWeight.w900,
                          AppColors.textPrimary,
                        ),
                      ),
                      if (type.category.isNotEmpty)
                        Text(
                          type.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.nunito(
                            11,
                            FontWeight.w400,
                            AppColors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: AppColors.brandAccent,
              ),
              const SizedBox(width: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hint,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: color),
    );
    return TextFormField(
      controller: controller,
      validator: validator,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.next,
      cursorColor: AppColors.brandAccent,
      style: AppText.nunito(15, FontWeight.w900, AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.nunito(13, FontWeight.w400, AppColors.textSecondary),
        errorStyle: AppText.nunito(11, FontWeight.w600, AppColors.statusSoon),
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: border(AppColors.textSecondary),
        enabledBorder: border(AppColors.textSecondary),
        focusedBorder: border(AppColors.brandAccent),
        errorBorder: border(AppColors.statusSoon),
        focusedErrorBorder: border(AppColors.statusSoon),
      ),
    );
  }
}

/// Fridge / Freezer / Pantry pills, as on the Expiry Defaults screen.
class _StorageChoices extends StatelessWidget {
  const _StorageChoices({required this.selected, required this.onSelected});

  final StorageLocation selected;
  final ValueChanged<StorageLocation> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 8,
    children: [
      for (final (storage, label) in [
        (StorageLocation.fridge, 'Fridge'),
        (StorageLocation.freezer, 'Freezer'),
        (StorageLocation.pantry, 'Pantry'),
      ])
        Expanded(
          child: Semantics(
            selected: storage == selected,
            button: true,
            child: Material(
              color: storage == selected
                  ? AppColors.brandPrimary
                  : AppColors.surfaceBlue,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelected(storage),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppText.nunito(
                      14,
                      FontWeight.w800,
                      storage == selected
                          ? AppColors.surface
                          : AppColors.textPrimary,
                      height: 20 / 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.suggested,
    required this.onTap,
  });

  final DateTime? date;

  /// Whether [date] came from the product type rather than the user.
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = this.date;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: _outlined(),
          child: Row(
            spacing: 8,
            children: [
              const Icon(
                LucideIcons.calendar,
                size: 16,
                color: AppColors.brandAccent,
              ),
              Expanded(
                child: date == null
                    ? Text(
                        'Choose a type first, or pick a date',
                        style: AppText.nunito(
                          13,
                          FontWeight.w400,
                          AppColors.textSecondary,
                        ),
                      )
                    : Text(
                        DateFormat('EEE, d MMM y').format(date),
                        style: AppText.nunito(
                          15,
                          FontWeight.w900,
                          AppColors.textPrimary,
                        ),
                      ),
              ),
              if (suggested)
                Text(
                  'suggested',
                  style: AppText.nunito(
                    11,
                    FontWeight.w400,
                    AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.brandPrimary,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onPressed,
      child: SizedBox(
        height: 46,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            const Icon(LucideIcons.check, size: 16, color: AppColors.surface),
            Text(
              label,
              style: AppText.nunito(14, FontWeight.w900, AppColors.surface),
            ),
          ],
        ),
      ),
    ),
  );
}
