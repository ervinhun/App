import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/food/domain/food_item.dart';

/// What the fridge holds when the app starts: see `foodItemsProvider`.
///
/// Sample data until the backend has an items endpoint. Dates are relative to
/// today, so the dashboard always shows a mix of soon, upcoming and later.
final initialFoodProvider = Provider<List<FoodItem>>(
  (ref) => sampleFood(DateTime.now()),
);

List<FoodItem> sampleFood(DateTime today) {
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  // Product categories and types are the backend's seeded names.
  return [
    FoodItem(
      id: 'chicken',
      name: 'Chicken breasts',
      amount: '500 g',
      category: FoodCategory.meat,
      productCategory: 'Poultry',
      productType: 'Chicken parts (breast halves, boneless)',
      storage: StorageLocation.fridge,
      bestBefore: day(1),
    ),
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
      id: 'yoghurt',
      name: 'Greek yoghurt',
      amount: '450 g',
      category: FoodCategory.dairy,
      productCategory: 'Dairy & Eggs',
      productType: 'Yogurt',
      storage: StorageLocation.fridge,
      bestBefore: day(7),
      openedOn: day(0),
      openedExpiresOn: day(2),
    ),
    FoodItem(
      id: 'strawberries',
      name: 'Strawberries',
      amount: '250 g',
      category: FoodCategory.veg,
      productCategory: 'Fruit',
      productType: 'Strawberries',
      storage: StorageLocation.fridge,
      bestBefore: day(3),
    ),
    FoodItem(
      id: 'spinach',
      name: 'Baby spinach',
      amount: '200 g',
      category: FoodCategory.veg,
      productCategory: 'Vegetables',
      productType: 'Bagged greens (leaf, spinach, lettuce, etc.)',
      storage: StorageLocation.fridge,
      bestBefore: day(4),
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
    for (final (name, amount, category, productCategory, productType, days) in [
      ('Frozen peas', '900 g', FoodCategory.veg, 'Frozen', 'Vegetables', 120),
      (
        'Salmon fillets',
        '2 fillets',
        FoodCategory.fish,
        'Frozen',
        'Fish (raw but headed and gutted)',
        60,
      ),
      ('Beef mince', '500 g', FoodCategory.meat, 'Meat', 'Beef (ground)', 45),
      (
        'Vanilla ice cream',
        '1 litre',
        FoodCategory.dairy,
        'Frozen',
        'Ice cream',
        90,
      ),
    ])
      FoodItem(
        id: 'freezer-$name',
        name: name,
        amount: amount,
        category: category,
        productCategory: productCategory,
        productType: productType,
        storage: StorageLocation.freezer,
        bestBefore: day(days),
      ),
    for (final (name, amount, productCategory, productType, days) in [
      (
        'Basmati rice',
        '1 kg',
        'Grains, Beans & Pasta',
        'Rice (white or wild)',
        300,
      ),
      (
        'Penne pasta',
        '500 g',
        'Grains, Beans & Pasta',
        'Pasta (dry, without eggs)',
        240,
      ),
      (
        'Chopped tomatoes',
        '2 tins',
        'Pantry',
        'Canned goods (high acid (such as juices, fruit, pickles, sauerkraut, '
            'tomato soup, and foods in vinegar-based sauce))',
        400,
      ),
      (
        'Rolled oats',
        '1 kg',
        'Grains, Beans & Pasta',
        'Oats (whole grain)',
        150,
      ),
      ('Peanut butter', '340 g', 'Pantry', 'Peanut butter (commercial)', 6),
      (
        'Sourdough loaf',
        '800 g',
        'Bakery',
        'Commercial bread products (including pan breads, flat breads, rolls, '
            'and buns)',
        2,
      ),
      (
        'Olive oil',
        '500 ml',
        'Baking & Cooking',
        'Oils (olive or vegetable)',
        365,
      ),
      ('Tinned tuna', '3 tins', 'Pantry', 'Tuna (canned)', 500),
    ])
      FoodItem(
        id: 'pantry-$name',
        name: name,
        amount: amount,
        category: name == 'Tinned tuna'
            ? FoodCategory.fish
            : FoodCategory.other,
        productCategory: productCategory,
        productType: productType,
        storage: StorageLocation.pantry,
        bestBefore: day(days),
      ),
  ];
}
