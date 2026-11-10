import 'package:app/core/auth/token_storage.dart';
import 'package:app/core/storage/hint_storage.dart';
import 'package:app/core/api/api_client.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:app/features/food/data/sample_food.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/storage/fake_hint_storage.dart';
import '../auth/fakes.dart';

void main() {
  final today = DateTime.now();
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  final items = [
    FoodItem(
      id: 'milk',
      name: 'Whole milk',
      amount: '1 litre',
      category: FoodCategory.dairy,
      productCategory: 'Dairy & Eggs',
      productType: 'Milk (plain or flavored)',
      storage: StorageLocation.fridge,
      bestBefore: day(5),
      openedOn: day(-1),
      openedExpiresOn: day(1),
    ),
    FoodItem(
      id: 'chicken',
      name: 'Chicken breasts',
      amount: '500 g',
      category: FoodCategory.meat,
      productCategory: 'Poultry',
      productType: 'Chicken parts (breast halves, boneless)',
      storage: StorageLocation.fridge,
      bestBefore: day(0),
    ),
    FoodItem(
      id: 'eggs',
      name: 'Free-range eggs',
      amount: '6 eggs',
      category: FoodCategory.eggs,
      productCategory: 'Dairy & Eggs',
      productType: 'Eggs (in shell)',
      storage: StorageLocation.fridge,
      bestBefore: day(11),
    ),
    FoodItem(
      id: 'peas',
      name: 'Frozen peas',
      amount: '900 g',
      category: FoodCategory.veg,
      productCategory: 'Frozen',
      productType: 'Vegetables',
      storage: StorageLocation.freezer,
      bestBefore: day(120),
    ),
  ];

  /// The swipe tip is already done unless [hints] says otherwise, so most
  /// tests see the plain list.
  Future<void> pumpDashboard(
    WidgetTester tester, {
    HintStorage? hints,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(FakeTokenStorage('jwt')),
          authClientProvider.overrideWithValue(FakeAuthClient()),
          googleAuthProvider.overrideWithValue(FakeGoogleAuth()),
          initialFoodProvider.overrideWithValue(items),
          hintStorageProvider.overrideWithValue(
            hints ?? FakeHintStorage(swipeDone: true),
          ),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  // The expiry sticker on opened food, e.g. "8 Nov → 4 Nov".
  final stickers = find.textContaining('→');
  final tip = find.textContaining('swipe a card', findRichText: true);

  testWidgets('lists the fridge, soonest to expire first', (tester) async {
    await pumpDashboard(tester);

    expect(find.textContaining('HELLO, ANNA!'), findsOneWidget);
    expect(find.text('Frozen peas'), findsNothing);
    final names = ['Chicken breasts', 'Whole milk', 'Free-range eggs'];
    final tops = [for (final n in names) tester.getTopLeft(find.text(n)).dy];
    expect(tops, orderedEquals([...tops]..sort()));

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('11 days'), findsOneWidget);
    expect(find.text('All 3'), findsOneWidget);
    expect(find.text('Expiring 2'), findsOneWidget);
  });

  testWidgets('filters by chip, search and storage', (tester) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('Expiring 2'));
    await tester.pumpAndSettle();
    expect(find.text('Free-range eggs'), findsNothing);
    expect(find.text('Whole milk'), findsOneWidget);

    await tester.ensureVisible(find.text('Dairy'));
    await tester.tap(find.text('Dairy'));
    await tester.pumpAndSettle();
    expect(find.text('Chicken breasts'), findsNothing);
    expect(find.text('Whole milk'), findsOneWidget);

    await tester.ensureVisible(find.text('All 3'));
    await tester.tap(find.text('All 3'));
    await tester.enterText(find.byType(TextField), 'EGG');
    await tester.pumpAndSettle();
    expect(find.text('Free-range eggs'), findsOneWidget);
    expect(find.text('Whole milk'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Freezer'));
    await tester.pumpAndSettle();
    expect(find.text('Frozen peas'), findsOneWidget);
    expect(find.text('Whole milk'), findsNothing);
    expect(find.text('All 1'), findsOneWidget);
  });

  testWidgets('switches to the grid view', (tester) async {
    await pumpDashboard(tester);
    final listWidth = tester.getSize(find.text('Whole milk')).width;

    await tester.tap(find.byTooltip('Grid view'));
    await tester.pumpAndSettle();

    final milk = tester.getTopLeft(find.text('Whole milk'));
    final chicken = tester.getTopLeft(find.text('Chicken breasts'));
    expect(milk.dy, chicken.dy, reason: 'side by side in one row');
    expect(tester.getSize(find.text('Whole milk')).width, listWidth);
  });

  testWidgets('long expiry values stay clear of the coloured edge', (
    tester,
  ) async {
    await pumpDashboard(tester);
    await tester.tap(find.text('Freezer'));
    await tester.pumpAndSettle();

    // 430 wide screen - 22 page padding - 4 coloured edge - 12 card padding.
    expect(tester.getRect(find.text('120 days')).right, lessThanOrEqualTo(392));
  });

  testWidgets('Scan and Add manual stay on screen, messages above them', (
    tester,
  ) async {
    await pumpDashboard(tester);
    tester.view.physicalSize = const Size(430, 500);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    final buttons = tester.getRect(find.text('Scan'));
    expect(
      tester.getRect(find.byType(SnackBar)).bottom,
      lessThanOrEqualTo(buttons.top),
    );

    final listTop = tester.getTopLeft(find.text('First dibs')).dy;
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('First dibs')).dy,
      lessThan(listTop),
      reason: 'the list scrolled',
    );
    expect(tester.getRect(find.text('Scan')), buttons);
    expect(tester.getRect(find.text('Add manual')).bottom, lessThan(500));
  });

  group('swiping', () {
    testWidgets('right marks unopened food opened, with undo', (tester) async {
      await pumpDashboard(tester);
      expect(stickers, findsOneWidget, reason: 'only the milk is open');

      await tester.drag(find.text('Chicken breasts'), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.text('Chicken breasts'), findsOneWidget);
      expect(stickers, findsNWidgets(2));
      expect(
        find.textContaining('Chicken breasts opened · eat by'),
        findsOneWidget,
      );

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(stickers, findsOneWidget);
    });

    testWidgets('right does nothing to food that is already open', (
      tester,
    ) async {
      await pumpDashboard(tester);

      await tester.drag(find.text('Whole milk'), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.text('Whole milk'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('left removes food, and undo puts it back', (tester) async {
      await pumpDashboard(tester);

      await tester.drag(find.text('Whole milk'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.text('Whole milk'), findsNothing);
      expect(find.text('All 2'), findsOneWidget);
      expect(find.text('Whole milk removed'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Whole milk'), findsOneWidget);
      expect(find.text('All 3'), findsOneWidget);
    });

    testWidgets('the label shows only once letting go would act', (
      tester,
    ) async {
      await pumpDashboard(tester);
      final card = find.text('Whole milk');

      final gesture = await tester.startGesture(tester.getCenter(card));
      // Past the touch slop first, so the drag has started.
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      expect(find.byIcon(LucideIcons.trash), findsOneWidget);
      expect(find.text('Remove'), findsNothing);

      await gesture.moveBy(const Offset(-140, 0));
      await tester.pump();
      expect(find.text('Remove'), findsOneWidget);

      // Back under the threshold: letting go now does nothing.
      await gesture.moveBy(const Offset(160, 0));
      await tester.pump();
      expect(find.text('Remove'), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(card, findsOneWidget);
    });

    testWidgets('screen readers get the same actions', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpDashboard(tester);

      final chicken = tester.getSemantics(find.text('Chicken breasts'));
      expect(
        chicken,
        isSemantics(
          customActions: [
            const CustomSemanticsAction(label: 'Mark opened'),
            const CustomSemanticsAction(label: 'Remove'),
          ],
        ),
      );
      semantics.dispose();
    });
  });

  group('swipe tip', () {
    testWidgets('shows until closed, and stays closed', (tester) async {
      final hints = FakeHintStorage();
      await pumpDashboard(tester, hints: hints);
      expect(tip, findsOneWidget);

      await tester.tap(find.byTooltip('Close tip'));
      await tester.pumpAndSettle();
      expect(tip, findsNothing);
      expect(hints.swipeDone, isTrue);

      await tester.pumpWidget(const SizedBox());
      await pumpDashboard(tester, hints: hints);
      expect(tip, findsNothing);
    });

    testWidgets('goes away after the first swipe', (tester) async {
      final hints = FakeHintStorage();
      await pumpDashboard(tester, hints: hints);

      await tester.drag(find.text('Free-range eggs'), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(tip, findsNothing);
      expect(hints.swipeDone, isTrue);
    });

    testWidgets('the top card peeks once to show what is underneath', (
      tester,
    ) async {
      await pumpDashboard(tester, hints: FakeHintStorage(), settle: false);
      await tester.pump();
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 1000));
      expect(
        find.byIcon(LucideIcons.trash),
        findsOneWidget,
        reason: 'nudged left',
      );

      await tester.pumpAndSettle();
      expect(
        find.byIcon(LucideIcons.trash),
        findsNothing,
        reason: 'back in place',
      );
    });

    testWidgets('no peek once the user knows how to swipe', (tester) async {
      await pumpDashboard(tester, settle: false);
      await tester.pump();
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byIcon(LucideIcons.trash), findsNothing);
      await tester.pumpAndSettle();
    });
  });
}
