import 'package:flutter/material.dart';

import 'package:app/l10n/app_localizations.dart';

/// Placeholder "Management" tab until the fridges feature exists.
class FridgesScreen extends StatelessWidget {
  const FridgesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.tr('fridges.title'))),
    body: Center(child: Text(context.l10n.tr('fridges.comingSoon'))),
  );
}
