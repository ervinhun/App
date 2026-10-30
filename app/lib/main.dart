import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: FridgeFriendApp()));
}

class FridgeFriendApp extends ConsumerWidget {
  const FridgeFriendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FridgeFriend',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.teal)),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
