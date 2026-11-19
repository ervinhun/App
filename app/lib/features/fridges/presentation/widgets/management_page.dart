import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/features/fridges/data/fridge_details.dart';
import 'package:app/features/fridges/data/fridges_controller.dart';
import 'package:app/features/fridges/domain/fridge.dart';
import 'package:app/features/fridges/presentation/fridge_actions.dart';
import 'package:app/features/fridges/presentation/widgets/management_widgets.dart';

/// The frame of the Management screens: the header for the current fridge,
/// an offline notice when it applies, then what [builder] gives.
///
/// The main screen ([sub] false) goes back to My food; the others go back to
/// it, and have a [subtitle] and a card about the fridge's owner.
class ManagementPage extends ConsumerWidget {
  const ManagementPage({
    super.key,
    required this.title,
    required this.builder,
    this.sub = true,
    this.subtitle,
    this.mainCard,
    this.empty,
  });

  final String title;
  final String? subtitle;
  final bool sub;

  /// The main screen's card about the fridge.
  final Widget Function(Fridge fridge)? mainCard;

  /// What shows when the user has no fridge yet.
  final Widget? empty;

  final List<Widget> Function(BuildContext context, Fridge fridge) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fridges = ref.watch(fridgesProvider);
    final state = fridges.value;
    final fridge = state?.current;
    final online = ref.watch(isOnlineProvider);

    final members = fridge == null
        ? null
        : ref.watch(fridgeMembersProvider(fridge.id)).value;
    final header = ManagementHeader(
      fridgeName: fridge?.name,
      onSwitchFridge: () => FridgeActions.switchFridge(context, ref),
      backLabel: sub ? 'Back to management' : 'Back to my food',
      onBack: () => _back(context),
      title: title,
      subtitle: subtitle,
      card: fridge == null
          ? null
          : mainCard?.call(fridge) ??
                FridgeContextCard(
                  title: ownershipLine(fridge, members),
                  detail: separationLine(fridge, state!.others),
                ),
    );
    final content = [
      header,
      SizedBox(height: sub && fridge != null ? 48 : 26),
      if (state == null)
        fridges.hasError
            ? SectionMessage(
                ApiException.messageFor(fridges.error),
                onRetry: () => ref.invalidate(fridgesProvider),
              )
            : const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
      else if (fridge == null)
        ?empty
      else ...[
        if (!online && !fridge.isLocal) ...[
          ManagementOfflineNotice(solo: fridge.isSolo),
          const SizedBox(height: 16),
        ],
        ...builder(context, fridge),
      ],
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator.adaptive(
            onRefresh: () async {
              ref.invalidate(fridgesProvider);
              if (fridge != null) {
                ref
                  ..invalidate(fridgeMembersProvider(fridge.id))
                  ..invalidate(alertSettingsProvider(fridge.id))
                  ..invalidate(activityLogProvider(fridge.id));
              }
            },
            child: ListView(
              // Pull to refresh even when it all fits on the screen.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24, 14, 24, sub ? 28 : 24),
              children: content,
            ),
          ),
        ),
      ),
    );
  }

  void _back(BuildContext context) {
    if (!sub) return context.go(Routes.home);
    // maybePop, so a screen with unsaved changes can ask first.
    context.canPop()
        ? Navigator.of(context).maybePop()
        : context.go(Routes.management);
  }
}
