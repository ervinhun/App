import 'package:flutter/material.dart';

/// Placeholder "Management" tab until the fridges feature exists.
class FridgesScreen extends StatelessWidget {
  const FridgesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your fridges')),
    body: const Center(child: Text('Fridge management is coming soon.')),
  );
}
