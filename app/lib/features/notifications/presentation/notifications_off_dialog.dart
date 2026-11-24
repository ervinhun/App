import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoDialogAction;
import 'package:material_ui/material_ui.dart';

/// A native alert saying expiry reminders stay off until notifications are
/// allowed. Returns true if the user chose to open the system settings.
Future<bool> showNotificationsOffDialog(BuildContext context) async {
  final open = await showAdaptiveDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: const Text('Notifications are off'),
      content: const Text(
        "You won't be told about food that is about to expire until you turn "
        'notifications on for FridgeFriend.',
      ),
      actions: [
        _action(
          context: context,
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        _action(
          context: context,
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Open settings'),
        ),
      ],
    ),
  );
  return open ?? false;
}

Widget _action({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget child,
}) => switch (Theme.of(context).platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => CupertinoDialogAction(
    onPressed: onPressed,
    child: child,
  ),
  _ => TextButton(onPressed: onPressed, child: child),
};
