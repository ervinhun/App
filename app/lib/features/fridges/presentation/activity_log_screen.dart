import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/features/fridges/data/fridge_details.dart';
import 'package:app/features/fridges/data/fridges_controller.dart';
import 'package:app/features/fridges/domain/fridge.dart';
import 'package:app/features/fridges/presentation/widgets/management_page.dart';
import 'package:app/features/fridges/presentation/widgets/management_widgets.dart';

/// Who added what to the fridge, and what's gone since: the owner's only.
///
/// The backend has no activity log, so this is built from the fridge's
/// items, which say who added each and when, and whether it has been used
/// up, thrown out or removed, but not by whom or when. So an entry is an
/// item: who added it, and whether it's gone.
class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) => ManagementPage(
    title: 'A little housekeeping.',
    subtitle:
        'Set expiry rules, keep your crew in the loop, and see what’s changed.',
    builder: (context, fridge) => [
      _ActivityCard(key: ValueKey(fridge.id), fridge: fridge),
    ],
  );
}

enum _Filter { all, added, removed }

class _ActivityCard extends ConsumerStatefulWidget {
  const _ActivityCard({super.key, required this.fridge});

  final Fridge fridge;

  @override
  ConsumerState<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends ConsumerState<_ActivityCard> {
  _Filter _filter = _Filter.all;

  /// How many entries show; more on request.
  int _shown = 20;

  @override
  Widget build(BuildContext context) {
    final fridge = widget.fridge;
    final heading = CardHeading(
      icon: LucideIcons.history,
      title: 'Activity log',
      trailing: const RoleBadge(
        'Owner only',
        icon: LucideIcons.lockKeyhole,
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      ),
    );
    if (!fridge.isOwner || fridge.isLocal) {
      return ManagementCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            heading,
            Text(
              fridge.isLocal
                  ? 'Only you use this fridge, so there is nobody to keep a '
                        'log of.'
                  : 'Only the owner of ${fridge.name} can see its log.',
              style: _body,
            ),
          ],
        ),
      );
    }

    final log = ref.watch(activityLogProvider(fridge.id));
    final members = ref.watch(fridgeMembersProvider(fridge.id)).value ?? [];
    final me = ref.watch(currentUserIdProvider);
    final entries = [
      for (final entry in log.value ?? const <ActivityEntry>[])
        if (switch (_filter) {
          _Filter.all => true,
          _Filter.added => !entry.isGone,
          _Filter.removed => entry.isGone,
        })
          entry,
    ];
    final shown = entries.take(_shown).toList();

    return ManagementCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          heading,
          Text(
            'Who added food to ${fridge.name}, and what has gone since. Only '
            'owners can see this log, not members.',
            style: _body.copyWith(height: 1.45),
          ),
          PillChoices(
            options: const [
              (_Filter.all, 'All'),
              (_Filter.added, 'Still in'),
              (_Filter.removed, 'Gone'),
            ],
            selected: _filter,
            onSelected: (filter) => setState(() {
              _filter = filter;
              _shown = 20;
            }),
          ),
          switch (log) {
            AsyncValue(hasValue: true) when shown.isEmpty => SectionMessage(
              _filter == _Filter.all
                  ? 'No food added yet.'
                  : 'Nothing here yet.',
            ),
            AsyncValue(hasValue: true) => Column(
              children: [
                for (final (i, entry) in shown.indexed) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColors.surfaceBlue),
                  _EntryRow(
                    entry: entry,
                    adder: members
                        .where((m) => m.userId == entry.addedByUserId)
                        .firstOrNull,
                    isMe: entry.addedByUserId == me,
                  ),
                ],
              ],
            ),
            AsyncError(:final error) => SectionMessage(
              ApiException.messageFor(error),
              onRetry: () => ref.invalidate(activityLogProvider(fridge.id)),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
          },
          if (entries.length > shown.length)
            TextButton(
              onPressed: () => setState(() => _shown += 20),
              child: Text(
                'Show more',
                style: AppText.nunito(
                  13,
                  FontWeight.w900,
                  AppColors.brandPrimary,
                ),
              ),
            ),
          if (log.hasValue && shown.isNotEmpty)
            Text(
              'Latest ${shown.length} food changes · ${fridge.name} only. '
              "Who took something out isn't recorded.",
              style: AppText.nunito(10, FontWeight.w400, AppColors.textPrimary),
            ),
        ],
      ),
    );
  }

  static final _body = AppText.nunito(
    12,
    FontWeight.w400,
    AppColors.textPrimary,
  );
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.adder,
    required this.isMe,
  });

  final ActivityEntry entry;

  /// Null when they've left the fridge.
  final FridgeMember? adder;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final adder = this.adder;
    final name = adder == null
        ? 'A former member'
        : isMe
        ? '${adder.displayName} · You'
        : adder.displayName;
    final meta = [
      if (entry.category.isNotEmpty) entry.category,
      if (entry.amount.isNotEmpty) entry.amount,
      _when(entry.addedAt.toLocal()),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          if (adder != null)
            MemberAvatar(adder, size: 34)
          else
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.surfaceBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.userRound,
                size: 15,
                color: AppColors.brandPrimary,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      name,
                      style: AppText.nunito(
                        12,
                        FontWeight.w900,
                        AppColors.textPrimary,
                      ),
                    ),
                    if (adder?.isTemporary ?? false)
                      Text(
                        'Temporary',
                        style: AppText.nunito(
                          9,
                          FontWeight.w800,
                          AppColors.brandPrimary,
                        ),
                      ),
                  ],
                ),
                Text(
                  'Added ${entry.name}',
                  style: AppText.nunito(
                    13,
                    FontWeight.w700,
                    AppColors.textPrimary,
                  ),
                ),
                Text(
                  meta,
                  style: AppText.nunito(
                    10,
                    FontWeight.w400,
                    AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (entry.isGone)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: RoleBadge(switch (entry.status) {
                      ItemStatus.consumed => 'Used up since',
                      ItemStatus.expired => 'Thrown out, expired',
                      _ => 'Removed since',
                    }),
                  ),
              ],
            ),
          ),
          Icon(
            entry.isGone ? LucideIcons.minus : LucideIcons.plus,
            size: 14,
            color: AppColors.brandPrimary,
          ),
        ],
      ),
    );
  }

  /// "Today · 09:12", "Yesterday · 18:30", "12 Nov · 08:45".
  static String _when(DateTime at) {
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(at.year, at.month, at.day)).inDays;
    final day = switch (days) {
      0 => 'Today',
      1 => 'Yesterday',
      _ when at.year == now.year => DateFormat('d MMM').format(at),
      _ => DateFormat('d MMM y').format(at),
    };
    return '$day · ${DateFormat('HH:mm').format(at)}';
  }
}
