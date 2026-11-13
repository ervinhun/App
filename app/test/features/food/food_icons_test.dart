import 'dart:convert';
import 'dart:io';

import 'package:app/features/food/data/sample_food.dart';
import 'package:app/features/food/domain/food_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The backend's seeded product categories and their types, from
/// DataAccess/Seed/foodkeeper.json (FF-27-Food-Types). To regenerate, from the
/// Backend repo:
///   git show FF-27-Food-Types:DataAccess/Seed/foodkeeper.json \
///     | jq '[.[] | {(.name): [.types[].name]}] | add' \
///     > ../App/app/test/fixtures/foodkeeper_types.json
final Map<String, List<String>> seeded =
    (jsonDecode(File('test/fixtures/foodkeeper_types.json').readAsStringSync())
            as Map<String, dynamic>)
        .map((category, types) => MapEntry(category, List<String>.from(types)));

void main() {
  test('every seeded category has its own icon', () {
    expect(seeded, hasLength(16));
    for (final category in seeded.keys) {
      expect(
        FoodIcons.categoryIcons,
        contains(category),
        reason: '"$category" would get the fallback icon',
      );
    }
  });

  test('every seeded type gets an icon', () {
    expect(seeded.values.expand((types) => types), hasLength(651));
    seeded.forEach((category, types) {
      for (final type in types) {
        expect(
          FoodIcons.forType(category: category, type: type),
          isNot(FoodIcons.fallback),
          reason: '$category / $type',
        );
      }
    });
  });

  test('the sample food uses real seeded types', () {
    for (final item in sampleFood(DateTime(2026, 11, 9))) {
      expect(
        seeded[item.productCategory],
        contains(item.productType),
        reason: item.name,
      );
    }
  });

  group('picks', () {
    for (final (category, type, icon) in [
      ('Dairy & Eggs', 'Milk (plain or flavored)', LucideIcons.milk),
      ('Dairy & Eggs', 'Eggs (in shell)', LucideIcons.egg),
      ('Fruit', 'Strawberries', LucideIcons.cherry),
      ('Fruit', 'Bananas', LucideIcons.banana),
      (
        'Vegetables',
        'Bagged greens (leaf, spinach, lettuce, etc.)',
        LucideIcons.leafyGreen,
      ),
      ('Pantry', 'Tuna (canned)', LucideIcons.fish),
      ('Pantry', 'Peanut butter (commercial)', LucideIcons.nut),
      ('Frozen', 'Ice cream', LucideIcons.iceCreamCone),
      // Rules that must not fire on a word inside another word, or on foods
      // a name only mentions.
      ('Vegetables', 'Eggplant', LucideIcons.carrot),
      ('Drinks', 'Eggnog (commercial)', LucideIcons.cupSoda),
      ('Meat', 'Goat (ground)', LucideIcons.beef),
      ('Meat', 'Beef (stew, cubes)', LucideIcons.beef),
      ('Grains, Beans & Pasta', 'Pasta (dry, without eggs)', LucideIcons.wheat),
      ('Pantry', 'Grapeseed oil', LucideIcons.droplet),
      (
        'Sauces & Condiments',
        'Chicken broth/stock/consommé (commercially produced)',
        LucideIcons.soup,
      ),
      (
        'Sauces & Condiments',
        'Tomato sauce (spaghetti, pizza)',
        LucideIcons.cookingPot,
      ),
      (
        'Deli & Leftovers',
        'Leftovers (with meat, fish, poultry, or egg)',
        LucideIcons.sandwich,
      ),
      ('My own category', 'Something new', FoodIcons.fallback),
    ]) {
      test('$type → ${icon.codePoint}', () {
        expect(FoodIcons.forType(category: category, type: type), icon);
      });
    }
  });
}
