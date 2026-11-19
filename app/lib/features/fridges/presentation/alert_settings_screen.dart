import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/core/widgets/adaptive.dart';
import 'package:app/features/fridges/data/fridge_details.dart';
import 'package:app/features/fridges/data/fridges_controller.dart';
import 'package:app/features/fridges/domain/fridge.dart';
import 'package:app/features/fridges/presentation/fridge_actions.dart';
import 'package:app/features/fridges/presentation/widgets/management_page.dart';
import 'package:app/features/fridges/presentation/widgets/management_widgets.dart';

/// Expiry alerts: when the reminders go out, and who gets them.
///
/// The backend has two reminders, a heads-up and a last call, and a time of
/// day, where the design has one "days before"; and it has no off switch,
/// so the design's toggle isn't here. Who gets them is everyone, whoever
/// added the item and the owners, or people the owner picks.
class AlertSettingsScreen extends StatelessWidget {
  const AlertSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => ManagementPage(
    title: 'A little housekeeping.',
    subtitle:
        'Set expiry rules, keep your crew in the loop, and see what’s changed.',
    builder: (context, fridge) => [
      _AlertsCard(key: ValueKey(fridge.id), fridge: fridge),
    ],
  );
}

class _AlertsCard extends ConsumerStatefulWidget {
  const _AlertsCard({super.key, required this.fridge});

  final Fridge fridge;

  @override
  ConsumerState<_AlertsCard> createState() => _AlertsCardState();
}

class _AlertsCardState extends ConsumerState<_AlertsCard> {
  /// The user's changes, until saved; null to show what's saved.
  AlertSettings? _draft;
  bool _busy = false;
  String? _error;

  Fridge get _fridge => widget.fridge;

  void _edit(AlertSettings settings) => setState(() {
    _draft = settings;
    _error = null;
  });

  Future<void> _pickTime(AlertSettings settings) async {
    final time = await Adaptive.pickTime(
      context,
      initial: TimeOfDay(
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      ),
    );
    if (time == null) return;
    _edit(
      settings.copyWith(
        notificationHour: time.hour,
        notificationMinute: time.minute,
      ),
    );
  }

  /// Ticking someone picks people by hand, starting from who gets the
  /// alerts now.
  void _toggle(
    AlertSettings settings,
    List<FridgeMember> members,
    FridgeMember member,
  ) {
    final picked = {
      for (final m in members)
        if (settings.notifies(m)) m.userId,
    };
    picked.contains(member.userId)
        ? picked.remove(member.userId)
        : picked.add(member.userId);
    HapticFeedback.selectionClick();
    _edit(
      settings.copyWith(
        scope: RecipientsScope.custom,
        recipientUserIds: picked,
      ),
    );
  }

  Future<void> _save(AlertSettings settings) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await ref
          .read(alertSettingsProvider(_fridge.id).notifier)
          .change(_fridge, settings);
      if (!mounted) return;
      setState(() => _draft = null);
      FridgeActions.showMessage(
        context,
        outcome == SaveOutcome.queued
            ? FridgeActions.savedOnPhoneMessage(_fridge)
            : 'Alerts saved',
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(alertSettingsProvider(_fridge.id));
    final members = ref.watch(fridgeMembersProvider(_fridge.id)).value ?? [];
    final online = ref.watch(isOnlineProvider);
    final loaded = saved.value;
    if (loaded == null) {
      return ManagementCard(
        child: saved.hasError
            ? SectionMessage(
                ApiException.messageFor(saved.error),
                onRetry: () =>
                    ref.invalidate(alertSettingsProvider(_fridge.id)),
              )
            : const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final settings = _draft ?? loaded;
    final canEdit =
        _fridge.isOwner && canChangeFridge(_fridge, online: online) && !_busy;
    final notified = [
      for (final m in members)
        if (settings.notifies(m)) m,
    ];
    final missingPick =
        settings.scope == RecipientsScope.custom && notified.isEmpty;
    final changed = _draft != null && _draft != loaded;

    return ManagementCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const CardHeading(icon: LucideIcons.bell, title: 'Expiry alerts'),
          Row(
            spacing: 6,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.statusFresh,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  'On · ${_daysLabel(settings.warningDaysBefore)} & '
                  '${_daysLabel(settings.dangerDaysBefore)} · '
                  '${settings.timeLabel}',
                  style: AppText.nunito(
                    12,
                    FontWeight.w800,
                    AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (!_fridge.isOwner)
            Text(
              'Only the owner can change these.',
              style: AppText.nunito(12, FontWeight.w600, AppColors.brandAccent),
            ),
          _SettingRow(
            title: 'Heads-up',
            detail: 'Days before the item expires',
            control: _DayStepper(
              value: settings.warningDaysBefore,
              // The heads-up comes before the last call.
              min: settings.dangerDaysBefore + 1,
              max: AlertSettings.maxDays,
              label: 'Heads-up days',
              onChanged: canEdit
                  ? (days) => _edit(settings.copyWith(warningDaysBefore: days))
                  : null,
            ),
          ),
          _SettingRow(
            title: 'Last call',
            detail: '0 is on the day it expires',
            control: _DayStepper(
              value: settings.dangerDaysBefore,
              min: 0,
              max: settings.warningDaysBefore - 1,
              label: 'Last call days',
              onChanged: canEdit
                  ? (days) => _edit(settings.copyWith(dangerDaysBefore: days))
                  : null,
            ),
          ),
          _SettingRow(
            title: 'Reminder time',
            detail: "In your phone's time zone",
            control: Material(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: canEdit ? () => _pickTime(settings) : null,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: Text(
                    settings.timeLabel,
                    style: AppText.nunito(
                      16,
                      FontWeight.w900,
                      AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!_fridge.isLocal)
            _Recipients(
              me: ref.watch(currentUserIdProvider),
              settings: settings,
              members: members,
              notified: notified,
              onScope: canEdit
                  ? (scope) => _edit(
                      settings.copyWith(
                        scope: scope,
                        recipientUserIds: scope == RecipientsScope.custom
                            ? {for (final m in notified) m.userId}
                            : const {},
                      ),
                    )
                  : null,
              onToggle: canEdit
                  ? (member) => _toggle(settings, members, member)
                  : null,
            ),
          if (missingPick)
            Text(
              'Pick at least one person.',
              style: AppText.nunito(12, FontWeight.w700, AppColors.statusSoon),
            ),
          if (_error case final error?)
            Text(
              error,
              style: AppText.nunito(12, FontWeight.w700, AppColors.statusSoon),
            ),
          if (_fridge.isOwner)
            CardButton(
              label: 'Save alerts',
              busy: _busy,
              onPressed: canEdit && changed && !missingPick
                  ? () => _save(settings)
                  : null,
            ),
        ],
      ),
    );
  }

  static String _daysLabel(int days) => switch (days) {
    0 => 'on the day',
    1 => '1 day before',
    _ => '$days days before',
  };
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.detail,
    required this.control,
  });

  final String title;
  final String detail;
  final Widget control;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 12,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 3,
          children: [
            Text(
              title,
              style: AppText.nunito(13, FontWeight.w900, AppColors.textPrimary),
            ),
            Text(
              detail,
              style: AppText.nunito(11, FontWeight.w400, AppColors.textPrimary),
            ),
          ],
        ),
      ),
      control,
    ],
  );
}

/// − n +, in the design's light blue box.
class _DayStepper extends StatelessWidget {
  const _DayStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final String label;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, String tooltip, int to) {
      final enabled = onChanged != null && to >= min && to <= max;
      return IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 32, height: 40),
        padding: EdgeInsets.zero,
        iconSize: 14,
        color: AppColors.textPrimary,
        disabledColor: AppColors.textSecondary,
        onPressed: enabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged!(to);
              }
            : null,
        icon: Icon(icon),
      );
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          step(LucideIcons.minus, 'Fewer days', value - 1),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 24),
            child: Semantics(
              label: label,
              value: '$value',
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppText.nunito(
                  16,
                  FontWeight.w900,
                  AppColors.textPrimary,
                ),
              ),
            ),
          ),
          step(LucideIcons.plus, 'More days', value + 1),
        ],
      ),
    );
  }
}

class _Recipients extends StatelessWidget {
  const _Recipients({
    required this.me,
    required this.settings,
    required this.members,
    required this.notified,
    required this.onScope,
    required this.onToggle,
  });

  final String me;
  final AlertSettings settings;
  final List<FridgeMember> members;
  final List<FridgeMember> notified;
  final ValueChanged<RecipientsScope>? onScope;
  final ValueChanged<FridgeMember>? onToggle;

  @override
  Widget build(BuildContext context) {
    final sorted = [...members]
      ..sort((a, b) {
        if (a.isOwner != b.isOwner) return a.isOwner ? -1 : 1;
        return a.displayName.compareTo(b.displayName);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Who gets notified?',
                style: AppText.nunito(
                  13,
                  FontWeight.w900,
                  AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${notified.length} selected',
              style: AppText.nunito(
                11,
                FontWeight.w800,
                AppColors.brandPrimary,
              ),
            ),
          ],
        ),
        PillChoices(
          options: const [
            (RecipientsScope.allMembers, 'Everyone'),
            (RecipientsScope.adderAndOwners, 'Who added it'),
            (RecipientsScope.custom, 'Pick'),
          ],
          selected: settings.scope,
          onSelected: onScope,
        ),
        for (var i = 0; i < sorted.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                for (final member in sorted.skip(i).take(2))
                  Expanded(
                    child: _RecipientChoice(
                      member: member,
                      isMe: member.userId == me,
                      selected: settings.notifies(member),
                      onTap: onToggle == null ? null : () => onToggle!(member),
                    ),
                  ),
                if (i + 1 >= sorted.length) const Expanded(child: SizedBox()),
              ],
            ),
          ),
        if (settings.scope == RecipientsScope.adderAndOwners)
          Text(
            'Plus whoever added the item, for their own food.',
            style: AppText.nunito(11, FontWeight.w400, AppColors.textPrimary),
          ),
      ],
    );
  }
}

class _RecipientChoice extends StatelessWidget {
  const _RecipientChoice({
    required this.member,
    required this.isMe,
    required this.selected,
    required this.onTap,
  });

  final FridgeMember member;
  final bool isMe;
  final bool selected;
  final VoidCallback? onTap;

  String get _role => member.isOwner
      ? 'Owner'
      : member.isTemporary
      ? 'Temporary access'
      : 'Member';

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.surfaceBlue : AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selected ? AppColors.brandPrimary : AppColors.textSecondary,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            spacing: 8,
            children: [
              // Not a Checkbox: the whole tile is the control.
              ExcludeSemantics(
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brandPrimary
                        : AppColors.surface,
                    border: Border.all(color: AppColors.brandPrimary),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: selected
                      ? const Icon(
                          LucideIcons.check,
                          size: 12,
                          color: AppColors.surface,
                        )
                      : null,
                ),
              ),
              Expanded(
                child: Semantics(
                  checked: selected,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 2,
                    children: [
                      Text(
                        member.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.nunito(
                          12,
                          FontWeight.w900,
                          AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isMe ? 'You · $_role' : _role,
                        style: AppText.nunito(
                          10,
                          FontWeight.w400,
                          AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
