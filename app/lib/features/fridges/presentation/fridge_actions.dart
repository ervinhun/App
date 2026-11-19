import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/widgets/adaptive.dart';
import 'package:app/features/auth/data/guest_mode.dart';
import 'package:app/features/fridges/data/fridges_controller.dart';
import 'package:app/features/fridges/domain/fridge.dart';

/// What can be done to the user's fridges from the Management screens:
/// switching, creating, joining, renaming, deleting and leaving. Failures
/// show as a message at the bottom of the screen.
abstract final class FridgeActions {
  /// The fridge switcher: the user's fridges, and creating or joining one.
  static Future<void> switchFridge(BuildContext context, WidgetRef ref) async {
    final state = ref.read(fridgesProvider).value;
    if (state == null) return;
    final online = ref.read(isOnlineProvider);
    final guest = state.current?.isLocal ?? false;
    final choice = await Adaptive.chooseAction<String>(
      context,
      title: 'Your fridges',
      message: guest
          ? 'As a guest, your food stays in one fridge on this phone.'
          : online
          ? null
          : 'Creating or joining a fridge needs a connection.',
      actions: [
        for (final fridge in state.fridges)
          SheetAction(
            label: fridge.name,
            value: fridge.id,
            icon: LucideIcons.refrigerator,
            selected: fridge.id == state.current?.id,
          ),
        if (guest)
          const SheetAction(
            label: 'Sign in to share or join fridges',
            value: _signIn,
            icon: LucideIcons.logIn,
          )
        else ...[
          SheetAction(
            label: 'Create a fridge',
            value: _create,
            icon: LucideIcons.plus,
            enabled: online,
          ),
          SheetAction(
            label: 'Join with an invite code',
            value: _join,
            icon: LucideIcons.ticket,
            enabled: online,
          ),
        ],
      ],
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _signIn:
        await ref.read(guestModeProvider.notifier).leave();
      case _create:
        await create(context, ref);
      case _join:
        await join(context, ref);
      default:
        await ref.read(fridgesProvider.notifier).select(choice);
    }
  }

  static const _signIn = '#sign-in';
  static const _create = '#create';
  static const _join = '#join';

  static Future<void> create(BuildContext context, WidgetRef ref) async {
    final name = await Adaptive.askText(
      context,
      title: 'New fridge',
      message: 'Its food and members stay separate from your other fridges.',
      placeholder: 'e.g. Home, Work, Cabin',
      confirmLabel: 'Create',
      maxLength: 100,
    );
    if (name == null || !context.mounted) return;
    await _run(context, () async {
      final fridge = await ref.read(fridgesProvider.notifier).create(name);
      if (context.mounted) showMessage(context, '${fridge.name} created');
    });
  }

  static Future<void> join(BuildContext context, WidgetRef ref) async {
    final code = await Adaptive.askText(
      context,
      title: 'Join a fridge',
      message: 'Ask its owner for the invite code.',
      placeholder: 'Invite code',
      confirmLabel: 'Join',
      maxLength: 32,
      capitalization: TextCapitalization.characters,
    );
    if (code == null || !context.mounted) return;
    await _run(context, () async {
      final fridge = await ref.read(fridgesProvider.notifier).join(code);
      if (context.mounted) showMessage(context, 'You joined ${fridge.name}');
    });
  }

  /// Renaming, and deleting or leaving: what the owner and members may do.
  static Future<void> manage(
    BuildContext context,
    WidgetRef ref,
    Fridge fridge,
  ) async {
    final online = ref.read(isOnlineProvider);
    final canChange = canChangeFridge(fridge, online: online);
    final choice = await Adaptive.chooseAction<_Manage>(
      context,
      title: fridge.name,
      message: !online && !fridge.isLocal
          ? (fridge.isSolo
                ? "You're offline: deleting needs a connection."
                : FridgesController.sharedOfflineMessage)
          : null,
      actions: [
        if (fridge.isOwner)
          SheetAction(
            label: 'Rename',
            value: _Manage.rename,
            icon: LucideIcons.pencil,
            enabled: canChange,
          ),
        if (fridge.isOwner && !fridge.isLocal)
          SheetAction(
            label: 'Delete fridge',
            value: _Manage.delete,
            icon: LucideIcons.trash2,
            destructive: true,
            enabled: online,
          ),
        if (!fridge.isOwner)
          SheetAction(
            label: 'Leave fridge',
            value: _Manage.leave,
            icon: LucideIcons.logOut,
            destructive: true,
            enabled: online,
          ),
      ],
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _Manage.rename:
        await rename(context, ref, fridge);
      case _Manage.delete:
        await delete(context, ref, fridge);
      case _Manage.leave:
        await leave(context, ref, fridge);
    }
  }

  static Future<void> rename(
    BuildContext context,
    WidgetRef ref,
    Fridge fridge,
  ) async {
    final name = await Adaptive.askText(
      context,
      title: 'Rename fridge',
      initial: fridge.name,
      confirmLabel: 'Save',
      maxLength: 100,
    );
    if (name == null || name == fridge.name || !context.mounted) return;
    await _run(context, () async {
      final outcome = await ref
          .read(fridgesProvider.notifier)
          .rename(fridge, name);
      if (context.mounted && outcome == SaveOutcome.queued) {
        showMessage(context, savedOnPhoneMessage(fridge));
      }
    });
  }

  static Future<void> delete(
    BuildContext context,
    WidgetRef ref,
    Fridge fridge,
  ) async {
    final confirmed = await Adaptive.confirm(
      context,
      title: 'Delete ${fridge.name}?',
      message: fridge.isSolo
          ? 'Its food and settings are deleted for good.'
          : 'Its food and settings are deleted for good, and its '
                '${fridge.memberCount - 1} other members lose it too.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await _run(context, () async {
      await ref.read(fridgesProvider.notifier).delete(fridge);
      if (context.mounted) showMessage(context, '${fridge.name} deleted');
    });
  }

  static Future<void> leave(
    BuildContext context,
    WidgetRef ref,
    Fridge fridge,
  ) async {
    final confirmed = await Adaptive.confirm(
      context,
      title: 'Leave ${fridge.name}?',
      message:
          "You won't see its food any more. To come back, you'll need a "
          'new invite code from its owner.',
      confirmLabel: 'Leave',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await _run(context, () async {
      await ref.read(fridgesProvider.notifier).leave(fridge);
      if (context.mounted) showMessage(context, 'You left ${fridge.name}');
    });
  }

  static Future<void> regenerateInviteCode(
    BuildContext context,
    WidgetRef ref,
    Fridge fridge,
  ) async {
    final confirmed = await Adaptive.confirm(
      context,
      title: 'Reset the invite code?',
      message:
          'The current code stops working. People already in the fridge '
          'stay in it.',
      confirmLabel: 'Reset',
    );
    if (!confirmed || !context.mounted) return;
    await _run(context, () async {
      await ref.read(fridgesProvider.notifier).regenerateInviteCode(fridge);
      if (context.mounted) showMessage(context, 'New invite code ready');
    });
  }

  /// For a change kept on the phone until it can be uploaded.
  static String savedOnPhoneMessage(Fridge fridge) => fridge.isLocal
      ? 'Saved on this phone'
      : "Saved on this phone. It syncs when you're back online.";

  static void showMessage(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

  /// Runs [action], showing what went wrong if it fails.
  static Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on ApiException catch (e) {
      if (context.mounted) showMessage(context, e.message);
    }
  }
}

enum _Manage { rename, delete, leave }
