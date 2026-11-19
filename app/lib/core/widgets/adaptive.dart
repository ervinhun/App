import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';

/// Dialogs, sheets and pickers that look native: Cupertino on iOS, Material
/// on Android.
abstract final class Adaptive {
  static bool isCupertino(BuildContext context) =>
      switch (Theme.of(context).platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => true,
        _ => false,
      };

  /// Asks the user to confirm; true if they did.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(title),
        content: Text(message),
        actions: [
          _DialogAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          _DialogAction(
            label: confirmLabel,
            destructive: destructive,
            isDefault: !destructive,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Asks for a line of text; null if the user cancelled. [validate] returns
  /// an error to show, or null to accept.
  static Future<String?> askText(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String? message,
    String initial = '',
    String? placeholder,
    int? maxLength,
    TextCapitalization capitalization = TextCapitalization.sentences,
    String? Function(String text)? validate,
  }) => showAdaptiveDialog<String>(
    context: context,
    builder: (_) => _TextPrompt(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      initial: initial,
      placeholder: placeholder,
      maxLength: maxLength,
      capitalization: capitalization,
      validate: validate,
    ),
  );

  /// Lets the user pick one of [actions]: an action sheet on iOS, a bottom
  /// sheet on Android. Null if they cancelled.
  static Future<T?> chooseAction<T>(
    BuildContext context, {
    required List<SheetAction<T>> actions,
    String? title,
    String? message,
  }) {
    if (isCupertino(context)) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: title == null ? null : Text(title),
          message: message == null ? null : Text(message),
          actions: [
            for (final action in actions)
              CupertinoActionSheetAction(
                isDestructiveAction: action.destructive,
                isDefaultAction: action.selected,
                // Cupertino actions can't be disabled, so a disabled one is
                // greyed out and does nothing.
                onPressed: action.enabled
                    ? () => Navigator.pop(context, action.value)
                    : () {},
                child: Text(
                  action.selected ? '${action.label}  ✓' : action.label,
                  style: action.enabled
                      ? null
                      : const TextStyle(color: CupertinoColors.inactiveGray),
                ),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      // Over the navigation bar, as the iOS sheets are.
      useRootNavigator: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                child: Text(
                  title,
                  style: AppText.nunito(
                    18,
                    FontWeight.w900,
                    AppColors.textPrimary,
                  ),
                ),
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  message,
                  style: AppText.nunito(
                    13,
                    FontWeight.w400,
                    AppColors.textPrimary,
                  ),
                ),
              ),
            for (final action in actions)
              ListTile(
                enabled: action.enabled,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: action.icon == null
                    ? null
                    : Icon(
                        action.icon,
                        color: action.destructive
                            ? AppColors.statusSoon
                            : AppColors.brandPrimary,
                      ),
                title: Text(
                  action.label,
                  style: AppText.nunito(
                    15,
                    FontWeight.w800,
                    action.destructive
                        ? AppColors.statusSoon
                        : AppColors.textPrimary,
                  ),
                ),
                trailing: action.selected
                    ? const Icon(Icons.check, color: AppColors.brandPrimary)
                    : null,
                onTap: () => Navigator.pop(context, action.value),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// A taller sheet for a small form: the iOS sheet, which stacks the screen
  /// behind it, or a Material bottom sheet.
  static Future<T?> showSheet<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    if (isCupertino(context)) {
      return showCupertinoSheet<T>(
        context: context,
        showDragHandle: true,
        scrollableBuilder: (context, controller) => Material(
          color: AppColors.canvas,
          child: PrimaryScrollController(
            controller: controller,
            child: builder(context),
          ),
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      // Over the navigation bar, as the iOS sheets are.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.canvas,
      builder: builder,
    );
  }

  /// A calendar date: the iOS wheel, or the Material calendar.
  static Future<DateTime?> pickDate(
    BuildContext context, {
    required DateTime initial,
    required DateTime first,
    required DateTime last,
    String? title,
  }) async {
    if (!isCupertino(context)) {
      return showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: first,
        lastDate: last,
        helpText: title,
      );
    }
    var picked = initial;
    final done = await _cupertinoPicker(
      context,
      CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: initial,
        minimumDate: first,
        maximumDate: last,
        onDateTimeChanged: (value) => picked = value,
      ),
    );
    return done ? picked : null;
  }

  /// A time of day: the iOS wheel, or the Material clock.
  static Future<TimeOfDay?> pickTime(
    BuildContext context, {
    required TimeOfDay initial,
  }) async {
    if (!isCupertino(context)) {
      return showTimePicker(context: context, initialTime: initial);
    }
    final now = DateTime.now();
    var picked = initial;
    final done = await _cupertinoPicker(
      context,
      CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        initialDateTime: DateTime(
          now.year,
          now.month,
          now.day,
          initial.hour,
          initial.minute,
        ),
        onDateTimeChanged: (value) => picked = TimeOfDay.fromDateTime(value),
      ),
    );
    return done ? picked : null;
  }

  /// [picker] in a bottom popup with a Done button; true if it was tapped.
  static Future<bool> _cupertinoPicker(
    BuildContext context,
    Widget picker,
  ) async {
    final done = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => Container(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Done'),
                ),
              ),
              SizedBox(height: 216, child: picker),
            ],
          ),
        ),
      ),
    );
    return done ?? false;
  }
}

/// One choice in [Adaptive.chooseAction].
class SheetAction<T> {
  const SheetAction({
    required this.label,
    required this.value,
    this.icon,
    this.destructive = false,
    this.selected = false,
    this.enabled = true,
  });

  final String label;
  final T value;

  /// Shown on Android only: iOS action sheets are text.
  final IconData? icon;
  final bool destructive;

  /// The current choice, which gets a tick.
  final bool selected;
  final bool enabled;
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.isDefault = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    if (Adaptive.isCupertino(context)) {
      return CupertinoDialogAction(
        onPressed: onPressed,
        isDestructiveAction: destructive,
        isDefaultAction: isDefault,
        child: Text(label),
      );
    }
    return TextButton(
      onPressed: onPressed,
      style: destructive
          ? TextButton.styleFrom(foregroundColor: AppColors.statusSoon)
          : null,
      child: Text(label),
    );
  }
}

class _TextPrompt extends StatefulWidget {
  const _TextPrompt({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.initial,
    required this.placeholder,
    required this.maxLength,
    required this.capitalization,
    required this.validate,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String initial;
  final String? placeholder;
  final int? maxLength;
  final TextCapitalization capitalization;
  final String? Function(String text)? validate;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final _text = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _text.text.trim();
    final error = text.isEmpty
        ? 'Please fill this in.'
        : widget.validate?.call(text);
    if (error != null) return setState(() => _error = error);
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final cupertino = Adaptive.isCupertino(context);
    final field = cupertino
        ? CupertinoTextField(
            controller: _text,
            autofocus: true,
            placeholder: widget.placeholder,
            maxLength: widget.maxLength,
            textCapitalization: widget.capitalization,
            onSubmitted: (_) => _submit(),
          )
        : TextField(
            controller: _text,
            autofocus: true,
            maxLength: widget.maxLength,
            textCapitalization: widget.capitalization,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          );
    return AlertDialog.adaptive(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.message case final message?) ...[
            Text(message),
            const SizedBox(height: 12),
          ],
          field,
          if (cupertino && _error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(color: CupertinoColors.destructiveRed),
            ),
          ],
        ],
      ),
      actions: [
        _DialogAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        _DialogAction(
          label: widget.confirmLabel,
          isDefault: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}
