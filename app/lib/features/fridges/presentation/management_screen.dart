import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/features/auth/data/guest_mode.dart';
import 'package:app/features/food/data/expiry_defaults_controller.dart';
import 'package:app/features/fridges/data/fridge_details.dart';
import 'package:app/features/fridges/data/fridges_controller.dart';
import 'package:app/features/fridges/domain/fridge.dart';
import 'package:app/features/fridges/presentation/fridge_actions.dart';
import 'package:app/features/fridges/presentation/widgets/management_page.dart';
import 'package:app/features/fridges/presentation/widgets/management_widgets.dart';
import 'package:app/features/fridges/presentation/widgets/member_sheet.dart';

/// The "Management" tab: the current fridge, inviting people to it, its
/// members and their rights, and the way into its settings.
class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ManagementPage(
    sub: false,
    title: 'Our fridge, our crew.',
    mainCard: (fridge) => _ActiveFridgeCard(fridge),
    empty: const _NoFridgeCard(),
    builder: (context, fridge) => [
      if (fridge.isLocal)
        const _GuestShareCard()
      else if (fridge.isOwner && fridge.inviteCode != null)
        _InviteCard(fridge),
      const SizedBox(height: 28),
      _Crew(fridge),
      const SizedBox(height: 28),
      _Housekeeping(fridge),
    ],
  );
}

class _ActiveFridgeCard extends ConsumerWidget {
  const _ActiveFridgeCard(this.fridge);

  final Fridge fridge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final others = ref.watch(fridgesProvider).value?.others ?? const [];
    final people = fridge.isSolo ? 'Just you' : '${fridge.memberCount} people';
    final role = fridge.isLocal
        ? 'On this phone'
        : fridge.isOwner
        ? "You're the owner"
        : 'Shared with you';
    return Material(
      color: AppColors.surfaceBlue,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => FridgeActions.manage(context, ref, fridge),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 12,
            children: [
              SvgPicture.asset(
                'assets/images/fridge_emblem.svg',
                width: 46,
                height: 50,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Text(
                      fridge.name,
                      style: AppText.nunito(
                        19,
                        FontWeight.w900,
                        AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$people · $role\n${separationLine(fridge, others)}',
                      style: AppText.nunito(
                        11,
                        FontWeight.w600,
                        AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Manage ${fridge.name}',
                child: const Icon(
                  LucideIcons.ellipsis,
                  size: 18,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The owner's invite code, to copy or share. The backend gives every
/// member the same rights on joining (add & remove, no expiry), and its codes
/// don't expire; the owner changes rights per member, below.
class _InviteCard extends ConsumerWidget {
  const _InviteCard(this.fridge);

  final Fridge fridge;

  String get _code => fridge.inviteCode!;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _code));
    HapticFeedback.selectionClick();
    FridgeActions.showMessage(context, 'Invite code copied');
  }

  Future<void> _share(BuildContext button) async {
    final box = button.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Join ${fridge.name} on FridgeFriend',
        text:
            'Join my fridge "${fridge.name}" on FridgeFriend, so we can keep '
            'track of our food together. Open the app, tap Management, then '
            'the fridge switcher, and join with the invite code: $_code',
        // Where the share popover points on iPad.
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    return ManagementCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Row(
            spacing: 12,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.link,
                  size: 21,
                  color: AppColors.brandPrimary,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      'Good food. Better shared.',
                      style: AppText.nunito(
                        21,
                        FontWeight.w900,
                        AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Invite someone to your ${fridge.name}.',
                      style: AppText.nunito(
                        13,
                        FontWeight.w400,
                        AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Semantics(
            label: 'Invite code ${_code.split('').join(' ')}',
            excludeSemantics: true,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.textSecondary),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(
                    'Invite code',
                    style: AppText.nunito(
                      12,
                      FontWeight.w600,
                      AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  SelectableText(
                    _code,
                    style: AppText.nunito(
                      16,
                      FontWeight.w900,
                      AppColors.brandPrimary,
                    ).copyWith(letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ),
          Column(
            spacing: 12,
            children: [
              const _InviteFact(
                label: 'New members can',
                value: 'Add & remove',
              ),
              _InviteFact(
                label: 'Crew size',
                value: '${fridge.memberCount} of ${fridge.maxMembers}',
                warn: fridge.isFull,
              ),
            ],
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: _ShareButton(
                  label: 'Copy code',
                  icon: LucideIcons.copy,
                  filled: false,
                  onTap: _copy,
                ),
              ),
              Expanded(
                child: _ShareButton(
                  label: 'Share code',
                  icon: LucideIcons.share2,
                  filled: true,
                  onTap: _share,
                ),
              ),
            ],
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: Text(
                  fridge.isFull
                      ? 'The fridge is full: nobody else can join.'
                      : 'Anyone with this code can join. Share with care.',
                  style: AppText.nunito(
                    11,
                    FontWeight.w400,
                    fridge.isFull
                        ? AppColors.statusSoon
                        : AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
              InkWell(
                onTap: online
                    ? () => FridgeActions.regenerateInviteCode(
                        context,
                        ref,
                        fridge,
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Reset code',
                    style:
                        AppText.nunito(
                          11,
                          FontWeight.w900,
                          online
                              ? AppColors.brandPrimary
                              : AppColors.textSecondary,
                        ).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.brandPrimary,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteFact extends StatelessWidget {
  const _InviteFact({
    required this.label,
    required this.value,
    this.warn = false,
  });

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: AppText.nunito(13, FontWeight.w600, AppColors.textSecondary),
        ),
      ),
      Text(
        value,
        style: AppText.nunito(
          13,
          FontWeight.w900,
          warn ? AppColors.statusSoon : AppColors.brandPrimary,
        ),
      ),
    ],
  );
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;

  /// Gets the button's own context, which the share sheet points at.
  final ValueChanged<BuildContext> onTap;

  @override
  Widget build(BuildContext context) {
    final color = filled ? AppColors.surface : AppColors.brandPrimary;
    return Material(
      color: filled ? AppColors.brandPrimary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: filled
            ? BorderSide.none
            : const BorderSide(color: AppColors.brandPrimary, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(context),
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Icon(icon, size: 18, color: color),
              // Shrinks rather than overflows with large text.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.nunito(14, FontWeight.w800, color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Instead of the invite card, for a guest: sharing needs an account.
class _GuestShareCard extends ConsumerWidget {
  const _GuestShareCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ManagementCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        const CardHeading(
          icon: LucideIcons.link,
          title: 'Good food. Better shared.',
        ),
        Text(
          'Sign in to invite your crew: everyone sees the same food, and '
          "what's on this phone comes with you.",
          style: AppText.nunito(
            13,
            FontWeight.w400,
            AppColors.textPrimary,
            height: 1.4,
          ),
        ),
        CardButton(
          label: 'Sign in or create an account',
          onPressed: () => ref.read(guestModeProvider.notifier).leave(),
        ),
      ],
    ),
  );
}

/// For a signed-in user who isn't in any fridge yet.
class _NoFridgeCard extends ConsumerWidget {
  const _NoFridgeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    return ManagementCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const CardHeading(
            icon: LucideIcons.refrigerator,
            title: 'No fridge yet',
          ),
          Text(
            online
                ? 'Create your first fridge and invite your crew, or join '
                      'one with the invite code its owner gave you.'
                : "You're offline. Creating or joining a fridge needs a "
                      'connection.',
            style: AppText.nunito(
              13,
              FontWeight.w400,
              AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          CardButton(
            label: 'Create a fridge',
            icon: LucideIcons.plus,
            onPressed: online ? () => FridgeActions.create(context, ref) : null,
          ),
          OutlinedButton(
            onPressed: online ? () => FridgeActions.join(context, ref) : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              foregroundColor: AppColors.brandPrimary,
              side: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Join with an invite code',
              style: AppText.nunito(
                14,
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

class _Crew extends ConsumerWidget {
  const _Crew(this.fridge);

  final Fridge fridge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(fridgeMembersProvider(fridge.id));
    final me = ref.watch(currentUserIdProvider);
    final online = ref.watch(isOnlineProvider);
    final list = [...?members.value]
      ..sort((a, b) {
        int rank(FridgeMember m) => m.isOwner ? 0 : (m.userId == me ? 1 : 2);
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : a.displayName.compareTo(b.displayName);
      });

    void open(FridgeMember member) {
      if (!online) {
        return FridgeActions.showMessage(
          context,
          FridgesController.sharedOfflineMessage,
        );
      }
      if (member.userId == me) {
        FridgeActions.leave(context, ref, fridge);
      } else {
        showMemberSheet(context, fridge: fridge, member: member);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        SectionHeading(
          title: 'The fridge crew',
          trailing: Text(
            fridge.memberCount == 1
                ? '1 member'
                : '${fridge.memberCount} members',
            style: AppText.nunito(13, FontWeight.w800, AppColors.textSecondary),
          ),
        ),
        ManagementCard(
          padding: EdgeInsets.zero,
          shadow: AppColors.shadowInk6,
          child: switch (members) {
            AsyncValue(hasValue: true) => Column(
              children: [
                for (final (i, member) in list.indexed) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.surfaceBlue,
                    ),
                  _MemberRow(
                    member: member,
                    isMe: member.userId == me,
                    // The owner manages the others; a member can leave.
                    onTap: member.isOwner || fridge.isLocal
                        ? null
                        : fridge.isOwner || member.userId == me
                        ? () => open(member)
                        : null,
                  ),
                ],
              ],
            ),
            AsyncError(:final error) => SectionMessage(
              ApiException.messageFor(error),
              onRetry: () => ref.invalidate(fridgeMembersProvider(fridge.id)),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
          },
        ),
        if (fridge.isOwner && !fridge.isLocal)
          Row(
            spacing: 7,
            children: [
              const Icon(
                LucideIcons.clock3,
                size: 13,
                color: AppColors.textSecondary,
              ),
              Expanded(
                child: Text(
                  'Temporary access ends automatically on its expiry date.',
                  style: AppText.nunito(
                    11,
                    FontWeight.w400,
                    AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.onTap,
  });

  final FridgeMember member;
  final bool isMe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final until = member.accessExpiresAt;
    final detail = member.isOwner
        ? member.rightsLabel
        : '${member.rightsLabel} · '
              '${until == null ? 'No expiry' : 'Until ${DateFormat('d MMM').format(until.toLocal())}'}';
    final name = isMe && member.userId != Fridge.localId
        ? '${member.displayName} · You'
        : member.displayName;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          spacing: 12,
          children: [
            MemberAvatar(member),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        name,
                        style: AppText.nunito(
                          14,
                          FontWeight.w900,
                          AppColors.textPrimary,
                        ),
                      ),
                      if (member.isOwner)
                        const RoleBadge('Owner')
                      else if (member.isTemporary)
                        const RoleBadge('Temporary')
                      else
                        Text(
                          'Member',
                          style: AppText.nunito(
                            10,
                            FontWeight.w700,
                            AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    detail,
                    style: AppText.nunito(
                      11,
                      FontWeight.w600,
                      AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (member.isOwner)
              const Icon(
                LucideIcons.shieldCheck,
                size: 17,
                color: AppColors.brandPrimary,
              )
            else if (onTap != null)
              Icon(
                isMe ? LucideIcons.logOut : LucideIcons.chevronRight,
                size: 17,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

/// The way into the fridge's settings. The activity log is the owner's only,
/// as in the design; everyone may see the alerts (only the owner changes
/// them), and expiry defaults are each phone's own.
class _Housekeeping extends ConsumerWidget {
  const _Housekeeping(this.fridge);

  final Fridge fridge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(expiryDefaultsProvider).value?.rules.length ?? 0;
    final alerts = ref.watch(alertSettingsProvider(fridge.id)).value;
    final members = ref.watch(fridgeMembersProvider(fridge.id)).value;
    final rows = [
      _HousekeepingRow(
        icon: LucideIcons.calendarDays,
        title: 'Expiry defaults',
        detail: rules == 0
            ? 'By storage container & product type'
            : '$rules custom ${rules == 1 ? 'rule' : 'rules'} · On this phone',
        onTap: () => context.go(Routes.expiryDefaults),
      ),
      _HousekeepingRow(
        icon: LucideIcons.bell,
        title: 'Expiry alerts',
        detail: alerts == null
            ? 'When reminders go out, and to whom'
            : alertsSummary(alerts, members, local: fridge.isLocal),
        onTap: () => context.go(Routes.alertSettings),
      ),
      if (fridge.isOwner && !fridge.isLocal)
        _HousekeepingRow(
          icon: LucideIcons.history,
          title: 'Activity log',
          detail: 'Who added or removed food · Owners only',
          onTap: () => context.go(Routes.activityLog),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        const SectionHeading(title: 'A little housekeeping'),
        ManagementCard(
          padding: EdgeInsets.zero,
          radius: 22,
          shadow: AppColors.shadowInk6,
          child: Column(
            children: [
              for (final (i, row) in rows.indexed) ...[
                if (i > 0)
                  const Divider(height: 1, color: AppColors.surfaceBlue),
                row,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HousekeepingRow extends StatelessWidget {
  const _HousekeepingRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        spacing: 12,
        children: [
          Icon(icon, size: 20, color: AppColors.brandPrimary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  title,
                  style: AppText.nunito(
                    14,
                    FontWeight.w900,
                    AppColors.textPrimary,
                  ),
                ),
                Text(
                  detail,
                  style: AppText.nunito(
                    11,
                    FontWeight.w400,
                    AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}

/// "7 & 2 days before · Maya & Leo notified".
String alertsSummary(
  AlertSettings alerts,
  List<FridgeMember>? members, {
  required bool local,
}) {
  final when = alerts.dangerDaysBefore == 0
      ? '${alerts.warningDaysBefore} days before & on the day'
      : '${alerts.warningDaysBefore} & ${alerts.dangerDaysBefore} days before';
  if (local) return when;
  final who = switch (alerts.scope) {
    RecipientsScope.allMembers => 'Everyone notified',
    RecipientsScope.adderAndOwners => 'Whoever added it & owners',
    RecipientsScope.custom => () {
      final names = [
        for (final m in members ?? const <FridgeMember>[])
          if (alerts.notifies(m)) m.displayName.split(' ').first,
      ];
      return switch (names) {
        [] => '${alerts.recipientUserIds.length} notified',
        [final one] => '$one notified',
        [final a, final b] => '$a & $b notified',
        [final a, ...final rest] => '$a & ${rest.length} others notified',
      };
    }(),
  };
  return '$when · $who';
}
