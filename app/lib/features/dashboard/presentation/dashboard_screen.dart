import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:app/features/dashboard/presentation/widgets/food_details_sheet.dart';
import 'package:app/features/dashboard/presentation/widgets/food_filters.dart';
import 'package:app/features/dashboard/presentation/widgets/swipe_hint_banner.dart';
import 'package:app/features/dashboard/presentation/widgets/swipeable_food_card.dart';
import 'package:app/features/food/data/food_items_controller.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/fridges/data/fridge_spaces_controller.dart';
import 'package:app/features/fridges/domain/fridge_space.dart';
import 'package:app/features/fridges/presentation/fridge_space_sheets.dart';

/// The "My food" tab: what's in the current fridge, soonest to expire first.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.initialFilter});

  /// The filter to start on, and to switch to when it changes.
  final FoodFilter? initialFilter;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _query = '';
  late FoodFilter _filter = widget.initialFilter ?? FoodFilter.all;
  StorageLocation _storage = StorageLocation.fridge;
  FoodView _view = FoodView.list;

  /// Whether the top card has already nudged to teach swiping, this session.
  bool _peeked = false;

  @override
  void didUpdateWidget(DashboardScreen old) {
    super.didUpdateWidget(old);
    final filter = widget.initialFilter;
    if (filter != null && filter != old.initialFilter) _filter = filter;
  }

  // Redraws every minute, so "days left" is right after midnight too.
  late final Timer _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  String get _spaceId =>
      ref.read(fridgeSpacesProvider).requireValue.current!.id;

  FoodItemsController get _food =>
      ref.read(spaceFoodProvider(_spaceId).notifier);

  // Until these features exist, their buttons say so instead of doing nothing.
  void _notYet(String feature) =>
      _showSnackBar(Text('$feature is coming soon.'));

  /// The Dashboard's own messenger, so messages show above the sticky add
  /// buttons rather than over them.
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  void _showSnackBar(Widget content, {SnackBarAction? action}) {
    _messenger.currentState!
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: content,
          action: action,
          persist: false,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  void _showUndo(String message, VoidCallback undo) => _showSnackBar(
    Text(message),
    action: SnackBarAction(label: 'Undo', onPressed: undo),
  );

  void _markOpened(FoodItem item, DateTime today) {
    final before = _food.markOpened(item.id, today);
    final eatBy = ref
        .read(spaceFoodProvider(_spaceId))
        .firstWhere((i) => i.id == item.id)
        .expiresOn;
    _showUndo(
      '${item.name} opened · eat by ${DateFormat('d MMM').format(eatBy)}',
      () => _food.replace(before),
    );
  }

  Future<void> _addManually() async {
    final item = await context.push<FoodItem>(
      Uri(
        path: Routes.addFood,
        queryParameters: {'storage': _storage.name},
      ).toString(),
    );
    if (item == null || !mounted) return;
    // Show where it went, even if a filter would have hidden it.
    setState(() {
      _storage = item.storage;
      _filter = FoodFilter.all;
    });
    _showUndo('${item.name} added', () => _food.remove(item.id));
  }

  void _remove(FoodItem item) {
    final (removed, index) = _food.remove(item.id);
    _showUndo('${item.name} removed', () => _food.restore(removed, index));
  }

  void _details(FoodItem item, DateTime today) => showFoodDetails(
    context,
    item: item,
    today: today,
    moveTo: [
      for (final s
          in ref.read(fridgeSpacesProvider).requireValue.current!.storages)
        if (s != item.storage) s,
    ],
    onOpened: item.isOpened ? null : () => _markOpened(item, today),
    onMoved: (to) {
      _food.replace(item.movedTo(to));
      _showUndo('${item.name} moved to ${to.label}', () => _food.replace(item));
    },
    onRemoved: () => _remove(item),
  );

  void _removeAll(List<FoodItem> items) {
    final before = _food.removeWhere(items.contains);
    _showUndo('${items.length} removed', () => _food.undoTo(before));
  }

  Future<void> _switchSpace() async {
    _messenger.currentState!.hideCurrentSnackBar(); // Its Undo is for this one.
    final added = await showFridgeSpaceSwitcher(context);
    if (added != null) _showSnackBar(Text('Switched to ${added.name}'));
  }

  @override
  Widget build(BuildContext context) {
    final space = ref.watch(fridgeSpacesProvider).value?.current;
    if (space == null) return const NoFridgeSpace();
    if (!space.storages.contains(_storage) && space.storages.isNotEmpty) {
      _storage = space.storages.first;
    }
    final thresholds =
        ref.watch(expiryThresholdsProvider(space.id)).value ??
        defaultThresholds;
    final today = DateTime.now();
    final items = ref.watch(spaceFoodProvider(space.id));
    final user = ref.watch(authControllerProvider).value;
    final showSwipeHint = ref.watch(swipeHintProvider).value ?? false;
    final firstName = user?.displayName.trim().split(' ').first ?? '';

    final inStorage = [
      for (final item in items)
        if (item.storage == _storage) item,
    ];
    final query = _query.trim().toLowerCase();
    final visible = [
      for (final item in inStorage)
        if (_filter.matches(item, today, thresholds) &&
            '${item.name}\n${item.productType}'.toLowerCase().contains(query))
          item,
    ]..sort((a, b) => a.expiresOn.compareTo(b.expiresOn));
    // "Soon" is within the space's expiry warning, as its notifications.
    final expired = [...visible.where((i) => i.isExpired(today))];
    final soon = [
      for (final item in visible)
        if (!item.isExpired(today) &&
            item.urgency(today, thresholds) != ExpiryUrgency.later)
          item,
    ];
    final later = [
      for (final item in visible)
        if (item.urgency(today, thresholds) == ExpiryUrgency.later) item,
    ];

    // Nudge the top card once, while the user hasn't swiped yet.
    String? peekId;
    if (showSwipeHint && !_peeked && visible.isNotEmpty) {
      peekId = visible.first.id;
      _peeked = true;
    }

    return ScaffoldMessenger(
      key: _messenger,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        // Always in reach, while the list scrolls behind.
        bottomNavigationBar: !space.canPut || space.storages.isEmpty
            ? null
            : _AddFoodButtons(
                onScan: () => _notYet('Scanning'),
                onAddManual: _addManually,
              ),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
              children: [
                DashboardHeader(
                  fridgeName: space.name,
                  userName: firstName.isEmpty ? 'there' : firstName,
                  today: today,
                  hasUnread: false, // No notifications exist yet.
                  onSwitchFridge: _switchSpace,
                  onNotifications: () => _notYet('Notifications'),
                ),
                const SizedBox(height: 18),
                FoodSearchField(
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 10),
                FoodFilterBar(
                  selected: _filter,
                  counts: {
                    FoodFilter.all: inStorage.length,
                    FoodFilter.expiring: inStorage
                        .where(
                          (i) =>
                              FoodFilter.expiring.matches(i, today, thresholds),
                        )
                        .length,
                  },
                  view: _view,
                  onSelected: (filter) => setState(() => _filter = filter),
                  onViewChanged: (view) => setState(() => _view = view),
                  onMoreFilters: () => _notYet('More filters'),
                ),
                const SizedBox(height: 18),
                StorageTabs(
                  storages: space.storages,
                  labelFor: space.labelFor,
                  selected: _storage,
                  counts: {
                    for (final location in StorageLocation.values)
                      location: items
                          .where((i) => i.storage == location)
                          .length,
                  },
                  onSelected: (storage) => setState(() => _storage = storage),
                ),
                const SizedBox(height: 18),
                if (showSwipeHint && visible.isNotEmpty) ...[
                  SwipeHintBanner(
                    onClose: () => ref.read(swipeHintProvider.notifier).done(),
                  ),
                  const SizedBox(height: 8),
                ],
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      inStorage.isEmpty
                          ? 'Nothing in here yet.'
                          : 'No food matches.',
                      textAlign: TextAlign.center,
                      style: AppText.nunito(
                        14,
                        FontWeight.w600,
                        AppColors.textSecondary,
                      ),
                    ),
                  ),
                if (inStorage.isEmpty && space.canPut)
                  _AddButton(
                    label: 'Add food here',
                    icon: LucideIcons.plus,
                    filled: false,
                    onTap: _addManually,
                  ),
                for (final (i, (title, group)) in [
                  ('Expired', expired),
                  ('First dibs', soon),
                  ('Fine for a while', later),
                ].where((g) => g.$2.isNotEmpty).indexed) ...[
                  if (i > 0) const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppText.nunito(
                            20,
                            FontWeight.w800,
                            AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (group == expired && space.canPut)
                        TextButton(
                          onPressed: () => _removeAll(expired),
                          child: const Text('Remove all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _FoodGroup(
                    items: group,
                    today: today,
                    thresholds: thresholds,
                    view: _view,
                    peekId: peekId,
                    onOpened: (item) => _markOpened(item, today),
                    onTapped: (item) => _details(item, today),
                    onRemoved: _remove,
                    onSwiped: () => ref.read(swipeHintProvider.notifier).done(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodGroup extends StatelessWidget {
  const _FoodGroup({
    required this.items,
    required this.today,
    required this.thresholds,
    required this.view,
    required this.peekId,
    required this.onOpened,
    required this.onTapped,
    required this.onRemoved,
    required this.onSwiped,
  });

  final List<FoodItem> items;
  final DateTime today;
  final ExpiryThresholds thresholds;
  final FoodView view;

  /// The card that nudges to teach swiping, if any.
  final String? peekId;
  final ValueChanged<FoodItem> onOpened;
  final ValueChanged<FoodItem> onTapped;
  final ValueChanged<FoodItem> onRemoved;
  final VoidCallback onSwiped;

  @override
  Widget build(BuildContext context) {
    Widget card(FoodItem item) => SwipeableFoodCard(
      key: ValueKey(item.id),
      item: item,
      today: today,
      thresholds: thresholds,
      compact: view == FoodView.grid,
      peek: item.id == peekId,
      onOpened: () => onOpened(item),
      onTap: () => onTapped(item),
      onRemoved: () => onRemoved(item),
      onSwiped: onSwiped,
    );

    if (view == FoodView.list) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [for (final item in items) card(item)],
      );
    }
    return Column(
      spacing: 8,
      children: [
        for (var i = 0; i < items.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Expanded(child: card(items[i])),
                Expanded(
                  child: i + 1 < items.length
                      ? card(items[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AddFoodButtons extends StatelessWidget {
  const _AddFoodButtons({required this.onScan, required this.onAddManual});

  final VoidCallback onScan;
  final VoidCallback onAddManual;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
    decoration: const BoxDecoration(
      color: AppColors.canvas,
      boxShadow: [
        BoxShadow(
          color: Color(0x120D4F6B),
          offset: Offset(0, -2),
          blurRadius: 12,
        ),
      ],
    ),
    child: Row(
      spacing: 8,
      children: [
        Expanded(
          child: _AddButton(
            label: 'Scan',
            icon: LucideIcons.scanBarcode,
            filled: true,
            onTap: onScan,
          ),
        ),
        Expanded(
          child: _AddButton(
            label: 'Add manual',
            icon: LucideIcons.plus,
            filled: false,
            onTap: onAddManual,
          ),
        ),
      ],
    ),
  );
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: filled ? AppColors.shadowInk19 : AppColors.shadowInk8,
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ],
    ),
    child: Material(
      color: filled ? AppColors.brandPrimary : AppColors.surfaceBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: filled
            ? BorderSide.none
            : const BorderSide(color: AppColors.textSecondary),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Icon(
                icon,
                size: 16,
                color: filled ? AppColors.surface : AppColors.brandPrimary,
              ),
              Text(
                label,
                style: AppText.nunito(
                  14,
                  FontWeight.w800,
                  filled ? AppColors.surface : AppColors.brandPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
