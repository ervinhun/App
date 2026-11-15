import 'dart:async';

import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file: loads the translations up front, as `main()`
/// does, so widgets get their strings on the first frame.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await AppLocalizations.preload();
  await testMain();
}
