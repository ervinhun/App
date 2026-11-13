import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_config.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_theme.dart';

void main() {
  ApiConfig.validate();
  runApp(const ProviderScope(child: FridgeFriendApp()));
}

class FridgeFriendApp extends ConsumerWidget {
  const FridgeFriendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FridgeFriend',
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
