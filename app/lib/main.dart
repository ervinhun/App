import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_config.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/sync/sync_controller.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/food/data/food_items_controller.dart';
import 'package:app/features/food/data/product_catalog_api.dart';

void main() {
  ApiConfig.validate();
  runApp(const ProviderScope(child: FridgeFriendApp()));
}

class FridgeFriendApp extends ConsumerWidget {
  const FridgeFriendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Refreshes the product types on every launch, so the latest are saved on
    // the device before the type picker needs them offline.
    ref.listen(productTypesProvider, (_, _) {});
    // Reads the food on the phone during the startup check, so My food
    // rarely has to show the loading screen again.
    ref.listen(foodItemsProvider, (_, _) {});
    // Sends changes when the connection comes back, whichever tab is open.
    ref.listen(syncControllerProvider, (_, _) {});
    return MaterialApp.router(
      title: 'FridgeFriend',
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
