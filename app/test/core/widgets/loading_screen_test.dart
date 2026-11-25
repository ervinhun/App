import 'package:app/core/widgets/loading_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('animates for as long as it shows', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingScreen()));

    expect(find.text('Loading…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('stands still with animations turned off', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: LoadingScreen()),
      ),
    );

    expect(tester.hasRunningAnimations, isFalse);
  });
}
