import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/fridges/data/fridge_spaces_controller.dart';
import 'package:app/features/fridges/domain/fridge_space.dart';

/// What the Dashboard shows until there's a fridge space to show: loading, a
/// load error, or the choice to create or join one.
class NoFridgeSpace extends ConsumerWidget {
  const NoFridgeSpace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(fridgeSpacesProvider);
    final (title, text, buttons) = spaces.hasValue
        ? (
            "You don't have a fridge space yet",
            'A fridge space is where your food lives: your home, your office '
                'or a flat you share. Make your own, or join one with the '
                'invite code from its owner.',
            [
              FilledButton(
                onPressed: () => showCreateFridgeSpace(context),
                child: const Text('Create a fridge space'),
              ),
              OutlinedButton(
                onPressed: () => showJoinFridgeSpace(context),
                child: const Text('Join with an invite code'),
              ),
            ],
          )
        : spaces.hasError
        ? (
            null,
            ApiException.messageFor(spaces.error),
            [
              OutlinedButton(
                onPressed: () => ref.invalidate(fridgeSpacesProvider),
                child: const Text('Try again'),
              ),
            ],
          )
        : (null, null, [const CircularProgressIndicator()]);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            spacing: 12,
            children: [
              if (title != null)
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.nunito(
                    24,
                    FontWeight.w800,
                    AppColors.textPrimary,
                  ),
                ),
              if (text != null)
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppText.nunito(
                    14,
                    FontWeight.w600,
                    AppColors.textSecondary,
                  ),
                ),
              ...buttons,
            ],
          ),
        ),
      ),
    );
  }
}

/// Lists the user's fridge spaces to switch between, and ways to add one.
Future<FridgeSpace?> showFridgeSpaceSwitcher(BuildContext context) =>
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final spaces = ref.watch(fridgeSpacesProvider).requireValue;
          Future<void> add(
            Future<FridgeSpace?> Function(BuildContext) show,
          ) async {
            final space = await show(context);
            if (context.mounted) Navigator.pop(context, space);
          }

          return ListView(
            shrinkWrap: true,
            children: [
              for (final space in spaces.all)
                ListTile(
                  title: Text(space.name),
                  subtitle: Text(space.isOwner ? 'Owner' : 'Member'),
                  selected: space.id == spaces.current?.id,
                  onTap: () {
                    ref.read(fridgeSpacesProvider.notifier).select(space.id);
                    Navigator.pop(context);
                  },
                ),
              if (spaces.current?.inviteCode != null)
                ListTile(
                  title: Text('Invite people to ${spaces.current!.name}'),
                  onTap: () => _showInvite(context),
                ),
              ListTile(
                title: const Text('Create a fridge space'),
                onTap: () => add(showCreateFridgeSpace),
              ),
              ListTile(
                title: const Text('Join with an invite code'),
                onTap: () => add(showJoinFridgeSpace),
              ),
            ],
          );
        },
      ),
    );

/// The current space's invite code, to copy, or to replace if it got out.
Future<void> _showInvite(BuildContext context) {
  var copied = false;
  String? error;
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) => StatefulBuilder(
        builder: (context, setState) {
          final space = ref.watch(fridgeSpacesProvider).requireValue.current!;
          Future<void> newCode() async {
            final sure = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Make a new code?'),
                content: const Text(
                  'The old code stops working. Members stay.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Make new code'),
                  ),
                ],
              ),
            );
            if (sure != true) return;
            try {
              await ref
                  .read(fridgeSpacesProvider.notifier)
                  .newInviteCode(space.id);
              setState(() => copied = false);
            } catch (e) {
              setState(() => error = ApiException.messageFor(e));
            }
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(
                  'Invite people to ${space.name}',
                  style: AppText.nunito(
                    20,
                    FontWeight.w800,
                    AppColors.textPrimary,
                  ),
                ),
                Text(
                  'They tap "Join with an invite code" and enter:',
                  style: AppText.nunito(
                    14,
                    FontWeight.w600,
                    AppColors.textSecondary,
                  ),
                ),
                SelectableText(
                  space.inviteCode!,
                  style: AppText.nunito(
                    36,
                    FontWeight.w800,
                    AppColors.brandPrimary,
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: space.inviteCode!));
                    setState(() => copied = true);
                  },
                  child: Text(copied ? 'Copied' : 'Copy code'),
                ),
                TextButton(
                  onPressed: newCode,
                  child: const Text('Make a new code'),
                ),
                if (error != null) Text(error!),
              ],
            ),
          );
        },
      ),
    ),
  );
}

Future<FridgeSpace?> showCreateFridgeSpace(BuildContext context) {
  final storages = {...StorageLocation.values};
  return _showForm(
    context,
    title: 'New fridge space',
    label: 'Name',
    action: 'Create',
    extra: StatefulBuilder(
      builder: (context, setState) => Wrap(
        spacing: 8,
        children: [
          for (final s in StorageLocation.values)
            FilterChip(
              label: Text(s.label),
              selected: storages.contains(s),
              onSelected: (on) =>
                  setState(() => on ? storages.add(s) : storages.remove(s)),
            ),
        ],
      ),
    ),
    submit: (ref, name) async {
      if (storages.isEmpty) throw ApiException('Pick at least one.');
      return ref.read(fridgeSpacesProvider.notifier).create(name, [
        for (final s in StorageLocation.values)
          if (storages.contains(s)) s,
      ]);
    },
  );
}

Future<FridgeSpace?> showJoinFridgeSpace(BuildContext context) => _showForm(
  context,
  title: 'Join a fridge space',
  label: 'Invite code',
  action: 'Join',
  submit: (ref, code) => ref.read(fridgeSpacesProvider.notifier).join(code),
);

/// A sheet with one text field, and [extra] below it. Shows what went wrong,
/// or pops with the space [submit] returns.
Future<FridgeSpace?> _showForm(
  BuildContext context, {
  required String title,
  required String label,
  required String action,
  required Future<FridgeSpace> Function(WidgetRef, String) submit,
  Widget? extra,
}) {
  final text = TextEditingController();
  var saving = false;
  String? error;
  return showModalBottomSheet<FridgeSpace>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> send() async {
            if (text.text.trim().isEmpty) {
              return setState(() => error = 'Please fill this in.');
            }
            setState(() => saving = true);
            try {
              final space = await submit(ref, text.text.trim());
              if (context.mounted) Navigator.pop(context, space);
            } catch (e) {
              setState(() {
                saving = false;
                error = ApiException.messageFor(e);
              });
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              0,
              22,
              22 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(
                  title,
                  style: AppText.nunito(
                    20,
                    FontWeight.w800,
                    AppColors.textPrimary,
                  ),
                ),
                TextField(
                  controller: text,
                  autofocus: true,
                  onSubmitted: (_) => send(),
                  decoration: InputDecoration(
                    labelText: label,
                    errorText: error,
                  ),
                ),
                ?extra,
                FilledButton(
                  onPressed: saving ? null : send,
                  child: Text(action),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
