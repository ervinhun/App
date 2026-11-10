import 'package:app/core/api/api_client.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/storage/hint_storage.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:app/features/food/data/product_catalog_api.dart';
import 'package:app/features/food/data/sample_food.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/food/domain/product_type.dart';
import 'package:app/features/food/presentation/add_food_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/storage/fake_hint_storage.dart';
import '../auth/fakes.dart';

const types = [
  ProductType(
    id: 'milk',
    name: 'Milk',
    category: 'Dairy & Eggs',
    defaultExpiryDays: 7,
  ),
  ProductType(
    id: 'fish',
    name: 'Fresh fish',
    category: 'Fish & Seafood',
    defaultExpiryDays: 2,
  ),
  ProductType(
    id: 'eggs',
    name: 'Eggs (in shell)',
    category: 'Dairy & Eggs',
    defaultExpiryDays: 35,
    fridgeExpiryDays: 35,
  ),
  ProductType(
    id: 'strawberries',
    name: 'Strawberries',
    category: 'Fruit',
    defaultExpiryDays: 3,
    fridgeExpiryDays: 3,
    freezerExpiryDays: 360,
  ),
];

void main() {
  /// The Dashboard and the Add food route, as in the app's router.
  Future<void> pumpApp(
    WidgetTester tester, {
    Future<List<ProductType>> Function()? loadTypes,
  }) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
        GoRoute(
          path: Routes.addFood,
          builder: (_, state) => AddFoodScreen(
            storage:
                StorageLocation.values
                    .asNameMap()[state.uri.queryParameters['storage']] ??
                StorageLocation.fridge,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        // A failed load would otherwise be retried on a timer.
        retry: (_, _) => null,
        overrides: [
          tokenStorageProvider.overrideWithValue(FakeTokenStorage('jwt')),
          authClientProvider.overrideWithValue(FakeAuthClient()),
          googleAuthProvider.overrideWithValue(FakeGoogleAuth()),
          hintStorageProvider.overrideWithValue(
            FakeHintStorage(swipeDone: true),
          ),
          initialFoodProvider.overrideWithValue(const []),
          productTypesProvider.overrideWith(
            (ref) => loadTypes?.call() ?? Future.value(types),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openAddFood(WidgetTester tester) async {
    await tester.tap(find.text('Add manual'));
    await tester.pumpAndSettle();
  }

  testWidgets('Scan is a placeholder for now', (tester) async {
    await pumpApp(tester);

    expect(find.text('Add food'), findsNothing);
    await tester.tap(find.text('Scan'));
    await tester.pump();
    expect(find.text('Scanning is coming soon.'), findsOneWidget);
  });

  testWidgets('starts on the storage tab the user was looking at', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Freezer'));
    await tester.pumpAndSettle();

    await openAddFood(tester);
    expect(find.text('Add to freezer'), findsOneWidget);
  });

  testWidgets('needs a type and a name', (tester) async {
    await pumpApp(tester);
    await openAddFood(tester);

    await tester.tap(find.text('Add to fridge'));
    await tester.pumpAndSettle();

    expect(find.text('Choose what it is.'), findsOneWidget);
    expect(find.text('Give it a name.'), findsOneWidget);
    expect(find.text('Add food by hand.'), findsOneWidget, reason: 'stays');
  });

  testWidgets('adds food: type, suggested date, and back to the list', (
    tester,
  ) async {
    await pumpApp(tester);
    await openAddFood(tester);

    await tester.tap(find.text('Choose a type'));
    await tester.pumpAndSettle();
    expect(find.text('Dairy & Eggs'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'mil');
    await tester.pumpAndSettle();
    expect(find.text('Fresh fish'), findsNothing);
    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    // The name comes from the type; the date from its usual shelf life.
    final name = tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(name.controller!.text, 'Milk');
    final now = DateTime.now();
    final suggested = DateTime(now.year, now.month, now.day + 7);
    expect(
      find.text(DateFormat('EEE, d MMM y').format(suggested)),
      findsOneWidget,
    );
    expect(find.text('suggested'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Oat milk');
    await tester.enterText(find.byType(TextFormField).last, '1 litre');
    await tester.tap(find.text('Pantry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to pantry'));
    await tester.pumpAndSettle();

    // Back on the Dashboard, on the Pantry tab.
    expect(find.text('First dibs'), findsOneWidget);
    expect(find.text('Oat milk'), findsOneWidget);
    expect(find.text('1 litre · Unopened'), findsOneWidget);
    expect(find.text('All 1'), findsOneWidget);
    expect(find.text('Oat milk added'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Oat milk'), findsNothing);
  });

  group('type picker', () {
    testWidgets('shows categories first, then the types in one', (
      tester,
    ) async {
      await pumpApp(tester);
      await openAddFood(tester);
      await tester.tap(find.text('Choose a type'));
      await tester.pumpAndSettle();

      expect(find.text('Dairy & Eggs'), findsOneWidget);
      expect(find.text('Fish & Seafood'), findsOneWidget);
      expect(find.text('2 types'), findsOneWidget, reason: 'Dairy & Eggs');
      expect(find.text('1 type'), findsNWidgets(2));
      expect(find.text('Milk'), findsNothing);

      await tester.tap(find.text('Dairy & Eggs'));
      await tester.pumpAndSettle();
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Fresh fish'), findsNothing);

      await tester.tap(find.text('All categories'));
      await tester.pumpAndSettle();
      expect(find.text('Milk'), findsNothing);

      await tester.tap(find.text('Fish & Seafood'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fresh fish'));
      await tester.pumpAndSettle();
      expect(find.text('Add food by hand.'), findsOneWidget);
      expect(find.text('Fresh fish'), findsNWidgets(2), reason: 'type, name');
    });

    testWidgets('back steps out of a category before closing', (tester) async {
      await pumpApp(tester);
      await openAddFood(tester);
      await tester.tap(find.text('Choose a type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dairy & Eggs'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      // Still open, on the categories.
      expect(find.text('All categories'), findsNothing);
      expect(find.text('Fish & Seafood'), findsOneWidget);
      expect(find.text('Milk'), findsNothing);
    });

    testWidgets("reopens in the chosen type's category", (tester) async {
      await pumpApp(tester);
      await openAddFood(tester);
      await tester.tap(find.text('Choose a type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dairy & Eggs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Milk'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dairy & Eggs'));
      await tester.pumpAndSettle();
      expect(find.text('All categories'), findsOneWidget);
      expect(find.text('Milk'), findsWidgets);
    });
  });

  String inDays(int days) {
    final now = DateTime.now();
    return DateFormat('EEE, d MMM y')
        .format(DateTime(now.year, now.month, now.day + days));
  }

  Future<void> pickType(
    WidgetTester tester,
    String category,
    String type,
  ) async {
    await tester.tap(find.text('Choose a type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(category));
    await tester.pumpAndSettle();
    await tester.tap(find.text(type));
    await tester.pumpAndSettle();
  }

  testWidgets('asks where it goes before what it is', (tester) async {
    await pumpApp(tester);
    await openAddFood(tester);

    expect(
      tester.getTopLeft(find.text('Where does it go?')).dy,
      lessThan(tester.getTopLeft(find.text('What is it?')).dy),
    );
  });

  testWidgets('only offers food that keeps where it is going', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Freezer'));
    await tester.pumpAndSettle();
    await openAddFood(tester);

    await tester.tap(find.text('Choose a type'));
    await tester.pumpAndSettle();
    expect(find.text('Food that keeps in the freezer'), findsOneWidget);
    // Eggs keep in the fridge only; Milk has no per-storage times at all.
    await tester.tap(find.text('Dairy & Eggs'));
    await tester.pumpAndSettle();
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Eggs (in shell)'), findsNothing);

    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'shell');
    await tester.pumpAndSettle();
    expect(
      find.text('No types match.'),
      findsOneWidget,
      reason: 'not by search',
    );
  });

  testWidgets('suggests the date for where it goes', (tester) async {
    await pumpApp(tester);
    await openAddFood(tester);
    await tester.tap(find.text('Choose a type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fruit'));
    await tester.pumpAndSettle();
    expect(find.text('3 d'), findsOneWidget, reason: 'days in the fridge');
    await tester.tap(find.text('Strawberries'));
    await tester.pumpAndSettle();
    expect(find.text(inDays(3)), findsOneWidget);

    await tester.tap(find.text('Freezer'));
    await tester.pumpAndSettle();
    expect(find.text(inDays(360)), findsOneWidget);
    expect(find.text('suggested'), findsOneWidget);
  });

  testWidgets('moving it where its type is not kept clears the type', (
    tester,
  ) async {
    await pumpApp(tester);
    await openAddFood(tester);
    await pickType(tester, 'Fruit', 'Strawberries');

    await tester.tap(find.text('Pantry'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Strawberries isn't usually kept in the pantry. "
        'Choose what it is again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Choose a type'), findsOneWidget);
    final name = tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(name.controller!.text, isEmpty, reason: 'it was filled in');
    expect(find.text('Choose a type first, or pick a date'), findsOneWidget);
  });

  testWidgets('a date or name the user chose stays put', (tester) async {
    await pumpApp(tester);
    await openAddFood(tester);
    await pickType(tester, 'Fruit', 'Strawberries');
    await tester.enterText(find.byType(TextFormField).first, 'Garden berries');
    await tester.tap(find.text(inDays(3)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Freezer'));
    await tester.pumpAndSettle();
    expect(find.text(inDays(3)), findsOneWidget);
    expect(find.text('suggested'), findsNothing);

    await tester.tap(find.text('Pantry'));
    await tester.pumpAndSettle();
    expect(find.text(inDays(3)), findsOneWidget);
    final name = tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(name.controller!.text, 'Garden berries');
  });

  testWidgets('says when the types could not be loaded', (tester) async {
    await pumpApp(
      tester,
      loadTypes: () =>
          Future.error(ApiException('Could not reach the server.')),
    );
    await openAddFood(tester);

    await tester.tap(find.text('Choose a type'));
    await tester.pumpAndSettle();

    expect(find.text('Could not reach the server.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  group('FoodCategory.fromProduct', () {
    for (final (category, type, group) in [
      (
        'Fish & Seafood',
        'Lean fish (cod, flounder, haddock, halibut, sole, etc.)',
        FoodCategory.fish,
      ),
      (
        'Fish & Seafood',
        'Live clams, mussels, crab, and oysters',
        FoodCategory.fish,
      ),
      ('Poultry', 'Chicken (whole)', FoodCategory.meat),
      ('Meat', 'Beef (ground)', FoodCategory.meat),
      ('Dairy & Eggs', 'Eggs (in shell)', FoodCategory.eggs),
      ('Dairy & Eggs', 'Milk (plain or flavored)', FoodCategory.dairy),
      ('Fruit', 'Strawberries', FoodCategory.veg),
      ('Vegetables', 'Eggplant', FoodCategory.veg),
      ('Pantry', 'Tuna (canned)', FoodCategory.fish),
      ('Pantry', 'Peanut butter (commercial)', FoodCategory.other),
    ]) {
      test('$category / $type', () {
        expect(FoodCategory.fromProduct(category, type), group);
      });
    }
  });
}
