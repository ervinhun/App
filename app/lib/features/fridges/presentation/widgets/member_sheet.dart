import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/core/widgets/adaptive.dart';
import 'package:app/features/fridges/data/fridge_details.dart';
import 'package:app/features/fridges/domain/fridge.dart';
import 'package:app/features/fridges/presentation/widgets/management_widgets.dart';

/// The owner's editor for what [member] may do in [fridge], and for how long;
/// or for removing them.
Future<void> showMemberSheet(
  BuildContext context, {
  required Fridge fridge,
  required FridgeMember member,
}) => Adaptive.showSheet(
  context,
  builder: (_) => _MemberSheet(fridge: fridge, member: member),
);

class _MemberSheet extends ConsumerStatefulWidget {
  const _MemberSheet({required this.fridge, required this.member});

  final Fridge fridge;
  final FridgeMember member;

  @override
  ConsumerState<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends ConsumerState<_MemberSheet> {
  late bool _canPut = widget.member.canPut;
  late bool _canUse = widget.member.canUse;
  late DateTime? _until = widget.member.accessExpiresAt?.toLocal();
  bool _busy = false;
  String? _error;

  bool get _changed =>
      _canPut != widget.member.canPut ||
      _canUse != widget.member.canUse ||
      _until != widget.member.accessExpiresAt?.toLocal();

  FridgeMembersController get _members =>
      ref.read(fridgeMembersProvider(widget.fridge.id).notifier);

  DateTime get _tomorrow {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  Future<void> _pickUntil() async {
    final date = await Adaptive.pickDate(
      context,
      title: 'Access ends',
      initial: _until ?? _tomorrow.add(const Duration(days: 6)),
      first: _tomorrow,
      last: _tomorrow.add(const Duration(days: 365 * 2)),
    );
    // Until the end of that day: the backend wants a time still to come.
    if (date != null) {
      setState(
        () => _until = DateTime(date.year, date.month, date.day, 23, 59),
      );
    }
  }

  Future<void> _save() => _guard(() async {
    await _members.updateRights(
      widget.member,
      canPut: _canPut,
      canUse: _canUse,
      accessExpiresAt: _until,
    );
    if (mounted) Navigator.pop(context);
  });

  Future<void> _remove() async {
    final name = widget.member.displayName;
    final confirmed = await Adaptive.confirm(
      context,
      title: 'Remove $name?',
      message:
          "$name won't see ${widget.fridge.name}'s food any more. The food "
          'they added stays.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed) return;
    await _guard(() async {
      await _members.remove(widget.member);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('$name removed from ${widget.fridge.name}')),
      );
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final until = _until;
    return SingleChildScrollView(
      primary: true,
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 12,
            children: [
              MemberAvatar(member),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      member.displayName,
                      style: AppText.nunito(
                        20,
                        FontWeight.w900,
                        AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'In ${widget.fridge.name}',
                      style: AppText.nunito(
                        12,
                        FontWeight.w600,
                        AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Group(
            title: 'What can they do?',
            children: [
              _SwitchRow(
                icon: LucideIcons.plus,
                title: 'Add food',
                detail: 'Put new food in the fridge',
                value: _canPut,
                onChanged: _busy ? null : (v) => setState(() => _canPut = v),
              ),
              _SwitchRow(
                icon: LucideIcons.minus,
                title: 'Use & remove food',
                detail: 'Mark food as used up or gone',
                value: _canUse,
                onChanged: _busy ? null : (v) => setState(() => _canUse = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Group(
            title: 'How long?',
            children: [
              _SwitchRow(
                icon: LucideIcons.clock3,
                title: 'Temporary access',
                detail: until == null
                    ? 'No expiry'
                    : 'Ends automatically on its expiry date',
                value: until != null,
                onChanged: _busy
                    ? null
                    : (temporary) => temporary
                          ? _pickUntil()
                          : setState(() => _until = null),
              ),
              if (until != null)
                InkWell(
                  onTap: _busy ? null : _pickUntil,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Access ends',
                            style: AppText.nunito(
                              14,
                              FontWeight.w800,
                              AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            DateFormat('d MMM y').format(until),
                            style: AppText.nunito(
                              14,
                              FontWeight.w900,
                              AppColors.brandPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: AppText.nunito(13, FontWeight.w700, AppColors.statusSoon),
            ),
          ],
          const SizedBox(height: 20),
          CardButton(
            label: 'Save changes',
            icon: LucideIcons.check,
            busy: _busy,
            onPressed: _changed ? _save : null,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _busy ? null : _remove,
            style: TextButton.styleFrom(foregroundColor: AppColors.statusSoon),
            icon: const Icon(LucideIcons.userMinus, size: 16),
            label: Text(
              'Remove from ${widget.fridge.name}',
              style: AppText.nunito(14, FontWeight.w800, AppColors.statusSoon),
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled white card of rows.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      Text(
        title,
        style: AppText.nunito(13, FontWeight.w900, AppColors.textPrimary),
      ),
      ManagementCard(
        padding: EdgeInsets.zero,
        radius: 18,
        shadow: AppColors.shadowInk6,
        child: Column(
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: AppColors.surfaceBlue,
                ),
              child,
            ],
          ],
        ),
      ),
    ],
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        spacing: 12,
        children: [
          Icon(icon, size: 18, color: AppColors.brandPrimary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
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
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.brandPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    ),
  );
}
