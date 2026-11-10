import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/features/dashboard/presentation/widgets/food_card.dart';
import 'package:app/features/food/domain/food_item.dart';

/// A [FoodCard] that can be swiped right to mark it opened, or left to
/// remove it.
///
/// With [peek], the card nudges left and right once after it first appears,
/// showing what's underneath, to teach the gesture.
class SwipeableFoodCard extends StatefulWidget {
  const SwipeableFoodCard({
    super.key,
    required this.item,
    required this.today,
    required this.onOpened,
    required this.onRemoved,
    this.onSwiped,
    this.compact = false,
    this.peek = false,
  });

  final FoodItem item;
  final DateTime today;

  /// Marks the item opened. Never called for items that already are.
  final VoidCallback onOpened;
  final VoidCallback onRemoved;

  /// Called when the user completes either swipe, after the action itself.
  final VoidCallback? onSwiped;
  final bool compact;
  final bool peek;

  @override
  State<SwipeableFoodCard> createState() => _SwipeableFoodCardState();
}

class _SwipeableFoodCardState extends State<SwipeableFoodCard>
    with SingleTickerProviderStateMixin {
  static const _peekDistance = 48.0;

  // A short pause, so the peek starts once the screen has settled, then
  // left, back, right, back.
  late final _peek = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final Animation<double> _peekOffset = TweenSequence([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 6),
    for (final (from, to) in [
      (0.0, -_peekDistance),
      (-_peekDistance, 0.0),
      (0.0, _peekDistance),
      (_peekDistance, 0.0),
    ])
      TweenSequenceItem(
        tween: Tween(
          begin: from,
          end: to,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 4,
      ),
  ]).animate(_peek);

  /// Whether the current swipe has gone far enough to act when released.
  bool _armed = false;

  /// Whether the card is off its resting place, being dragged or springing
  /// back. Its urgency edge would look odd against the swipe colour then.
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    if (widget.peek) _startPeek();
  }

  @override
  void didUpdateWidget(SwipeableFoodCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.peek && !oldWidget.peek) _startPeek();
  }

  void _startPeek() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted &&
        !_peek.isAnimating &&
        !MediaQuery.disableAnimationsOf(context)) {
      _peek.forward(from: 0);
    }
  });

  @override
  void dispose() {
    _peek.dispose();
    super.dispose();
  }

  void _onUpdate(DismissUpdateDetails details) {
    final moving = details.progress > 0;
    if (details.reached == _armed && moving == _moving) return;
    if (details.reached && !_armed) HapticFeedback.mediumImpact();
    setState(() {
      _armed = details.reached;
      _moving = moving;
    });
  }

  Future<bool> _confirm(DismissDirection direction) async {
    _armed = false;
    if (direction == DismissDirection.startToEnd) {
      widget.onOpened();
      widget.onSwiped?.call();
      // Spring back: the card stays, now showing it's open.
      return false;
    }
    return true;
  }

  void _onDismissed(DismissDirection _) {
    widget.onRemoved();
    widget.onSwiped?.call();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final canOpen = !item.isOpened;
    FoodCard card({required bool atRest}) => FoodCard(
      item: item,
      today: widget.today,
      compact: widget.compact,
      showStatusEdge: atRest,
    );

    // One rounded outline for the card and what's behind it: the card's
    // moving edge stays straight, so it meets the swipe colour cleanly.
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowInk8,
            offset: Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Dismissible(
          key: ValueKey(item.id),
          direction: canOpen
              ? DismissDirection.horizontal
              : DismissDirection.endToStart,
          dismissThresholds: const {
            DismissDirection.startToEnd: 0.35,
            DismissDirection.endToStart: 0.35,
          },
          background: _SwipeBackground.open(
            armed: _armed,
            showLabel: _armed && !widget.compact,
          ),
          secondaryBackground: _SwipeBackground.remove(
            armed: _armed,
            showLabel: _armed && !widget.compact,
          ),
          onUpdate: _onUpdate,
          confirmDismiss: _confirm,
          onDismissed: _onDismissed,
          // Screen readers can't swipe, so offer the same actions.
          child: Semantics(
            customSemanticsActions: {
              if (canOpen)
                const CustomSemanticsAction(label: 'Mark opened'):
                    widget.onOpened,
              const CustomSemanticsAction(label: 'Remove'): widget.onRemoved,
            },
            child: AnimatedBuilder(
              animation: _peekOffset,
              builder: (context, _) {
                final dx = _peekOffset.value;
                if (dx == 0) return card(atRest: !_moving);
                return Stack(
                  children: [
                    Positioned.fill(
                      child: dx > 0
                          ? const _SwipeBackground.open(armed: false)
                          : const _SwipeBackground.remove(armed: false),
                    ),
                    Transform.translate(
                      offset: Offset(dx, 0),
                      child: card(atRest: false),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// What shows behind a card while it's swiped.
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground.open({required this.armed, this.showLabel = false})
    : color = AppColors.brandAccent,
      icon = LucideIcons.lockOpen,
      label = 'Mark opened',
      alignment = Alignment.centerLeft;

  const _SwipeBackground.remove({required this.armed, this.showLabel = false})
    : color = AppColors.statusSoon,
      icon = LucideIcons.trash,
      label = 'Remove',
      alignment = Alignment.centerRight;

  final bool armed;

  /// Until the swipe is far enough to act, the card still covers where the
  /// label would go, so only the icon at the outer edge shows.
  final bool showLabel;
  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final iconWidget = AnimatedScale(
      scale: armed ? 1.25 : 1,
      duration: const Duration(milliseconds: 150),
      child: Icon(icon, color: AppColors.surface, size: 22),
    );
    final text = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.nunito(13, FontWeight.w800, AppColors.surface),
      ),
    );
    // Square: the card's clip rounds the outline.
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: color,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        // The icon sits at the edge the card is moving away from.
        children: [
          if (alignment == Alignment.centerLeft) iconWidget,
          if (showLabel) text,
          if (alignment == Alignment.centerRight) iconWidget,
        ],
      ),
    );
  }
}
