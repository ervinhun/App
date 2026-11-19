import 'package:app/features/food/data/expiry_defaults_controller.dart';
import 'package:app/features/food/data/food_items_controller.dart';
import 'package:app/features/food/data/product_catalog_api.dart';
import 'package:app/features/food/data/sample_food.dart';
import 'package:app/features/food/domain/expiry_defaults.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/food/domain/product_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/db/test_database.dart';
import '../fridges/fakes.dart';
import 'food_store_test.dart' show food;
import 'product_types_test.dart' show eggs, milk;

void main() {
  const fridge = StorageLocation.fridge;
  const freezer = StorageLocation.freezer;
  const dairy = 'Dairy & Eggs';

  group('unopened', () {
    test("goes by the catalogue's time where the user set none", () {
      expect(ExpiryDefaults.none.unopenedDays(milk, fridge), 7);
      expect(
        ExpiryDefaults.none.unopenedDays(milk, StorageLocation.pantry),
        isNull,
      );
    });

    test("a type's rule wins over its category's", () {
      final defaults = ExpiryDefaults.none
          .withRule(
            ExpiryDefaults.key(fridge, dairy),
            const ExpiryRule(unopened: 5),
          )
          .withRule(
            ExpiryDefaults.key(fridge, dairy, 'Milk'),
            const ExpiryRule(unopened: 3),
          );

      expect(defaults.unopenedDays(milk, fridge), 3);
      // Eggs only have the category's.
      expect(defaults.unopenedDays(eggs, fridge), 5);
      // Other storages are unaffected.
      expect(defaults.unopenedDays(milk, freezer), 90);
    });

    test('applied to a type, the type picker and Add food use it', () {
      final defaults = ExpiryDefaults.none.withRule(
        ExpiryDefaults.key(fridge, dairy, 'Eggs (in shell)'),
        const ExpiryRule(unopened: 21),
      );

      final adjusted = defaults.applyTo(eggs);

      expect(adjusted.expiryDaysIn(fridge), 21);
      // Eggs had one time for anywhere; elsewhere it stays.
      expect(adjusted.expiryDaysIn(freezer), 35);
      expect(identical(defaults.applyTo(milk), milk), isTrue);
    });
  });

  group('once opened', () {
    test('suggests a time by food group', () {
      expect(
        ExpiryDefaults.none.openedDays(fridge, category: dairy, type: 'Milk'),
        4,
      );
      expect(
        ExpiryDefaults.none.openedDays(fridge, category: dairy, type: 'Eggs'),
        7,
      );
    });

    test("the category's rule, then the type's, win", () {
      var defaults = ExpiryDefaults.none.withRule(
        ExpiryDefaults.key(fridge, dairy),
        const ExpiryRule(opened: 2),
      );
      expect(defaults.openedDays(fridge, category: dairy, type: 'Milk'), 2);

      defaults = defaults.withRule(
        ExpiryDefaults.key(fridge, dairy, 'Milk'),
        const ExpiryRule(opened: 6),
      );
      expect(defaults.openedDays(fridge, category: dairy, type: 'Milk'), 6);
    });
  });

  test('an emptied rule is removed', () {
    final key = ExpiryDefaults.key(fridge, dairy);
    final defaults = ExpiryDefaults.none
        .withRule(key, const ExpiryRule(opened: 2))
        .withRule(key, const ExpiryRule());

    expect(defaults.rules, isEmpty);
  });

  test('saved rules survive a round trip', () {
    final defaults = ExpiryDefaults.none.withRule(
      ExpiryDefaults.key(freezer, dairy, 'Milk'),
      const ExpiryRule(unopened: 60, opened: 3),
    );

    expect(ExpiryDefaults.fromJson(defaults.toJson()).rules, defaults.rules);
  });

  group('in the app', () {
    late FakeExpiryDefaultsStorage storage;
    late ProviderContainer c;

    setUp(() {
      storage = FakeExpiryDefaultsStorage(
        ExpiryDefaults.none.withRule(
          ExpiryDefaults.key(fridge, dairy),
          const ExpiryRule(unopened: 10, opened: 2),
        ),
      );
      c = ProviderContainer.test(
        overrides: [
          inMemoryDatabase(),
          initialFoodProvider.overrideWithValue(const []),
          expiryDefaultsStorageProvider.overrideWithValue(storage),
          productTypesProvider.overrideWith(
            (ref) => Stream.value(const <ProductType>[milk]),
          ),
        ],
      );
    });

    test('opening food uses its rule', () async {
      await c.read(expiryDefaultsProvider.future);
      // Lets the food load from the device first, so it doesn't replace
      // what's added below.
      c.listen(foodItemsProvider, (_, _) {});
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      c.read(foodItemsProvider.notifier)
        ..add(food('a'))
        ..markOpened('a', DateTime(2026, 11, 15));

      expect(
        c.read(foodItemsProvider).requireValue.single.openedExpiresOn,
        DateTime(2026, 11, 17),
      );
    });

    test('the type picker gets the adjusted catalogue', () async {
      await c.read(expiryDefaultsProvider.future);
      c.listen(adjustedProductTypesProvider, (_, _) {});
      await c.read(productTypesProvider.future);

      expect(
        c.read(adjustedProductTypesProvider).value!.single.expiryDaysIn(fridge),
        10,
      );
    });

    test('changing the rules saves them', () async {
      await c.read(expiryDefaultsProvider.future);

      await c.read(expiryDefaultsProvider.notifier).change(ExpiryDefaults.none);

      expect(storage.defaults.rules, isEmpty);
    });
  });
}
