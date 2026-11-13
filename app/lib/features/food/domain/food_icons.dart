import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Picks an icon for a food from its product category and type, as seeded by
/// the backend (USDA FoodKeeper types in 16 categories: DataAccess/Seed/foodkeeper.json).
///
/// Keyword rules on the type name come first, so common foods get their own
/// icon ("Strawberries" → cherry); otherwise the category decides.
abstract final class FoodIcons {
  static const fallback = LucideIcons.utensils;

  static IconData forType({required String category, required String type}) {
    for (final (pattern, icon) in _typeRules) {
      if (pattern.hasMatch(type)) return icon ?? _categoryIcon(category);
    }
    return _categoryIcon(category);
  }

  static IconData _categoryIcon(String category) =>
      categoryIcons[category] ?? fallback;

  /// One per seeded category (db/migrations/V15, DataAccess/Seed/foodkeeper.json);
  /// [fallback] for any other, e.g. user-made, one.
  static const categoryIcons = {
    'Baby Food': LucideIcons.baby,
    'Bakery': LucideIcons.croissant,
    'Baking & Cooking': LucideIcons.chefHat,
    // Lucide has no cheese, so cheese and butter get the milk carton too.
    'Dairy & Eggs': LucideIcons.milk,
    'Deli & Leftovers': LucideIcons.sandwich,
    'Drinks': LucideIcons.cupSoda,
    'Fish & Seafood': LucideIcons.fish,
    'Frozen': LucideIcons.snowflake,
    'Fruit': LucideIcons.apple,
    'Grains, Beans & Pasta': LucideIcons.wheat,
    'Meat': LucideIcons.beef,
    'Pantry': LucideIcons.package,
    'Plant Proteins': LucideIcons.bean,
    'Poultry': LucideIcons.drumstick,
    'Sauces & Condiments': LucideIcons.cookingPot,
    'Vegetables': LucideIcons.carrot,
  };

  /// First match wins, so the more specific rules come first: "Chicken broth"
  /// is soup, not chicken; "Peanut oil" is oil, not a nut. A null icon means
  /// the category's own icon, for names that list foods they aren't
  /// ("Tomato sauce (spaghetti, pizza)", "Leftovers (with meat, fish, …)").
  static final _typeRules = <(RegExp, IconData?)>[
    for (final (words, icon) in <(String, IconData?)>[
      ('oils?|fat|grease|lard|shortening', LucideIcons.droplet),
      ('sauces?|dressings?|gravy|leftovers|canned goods', null),
      ('soups?|broth|stock|consommé|chowder', LucideIcons.soup),
      // Before eggs: "Pasta (dry, without eggs)".
      ('pasta|noodles?|macaroni', LucideIcons.wheat),
      ('eggs?', LucideIcons.egg),
      // Before fruit: "Fruit pies (apple, peach, …)".
      ('cakes?|cheesecake|cupcakes?|muffins?|pies?', LucideIcons.cakeSlice),
      ('cookies?|biscuits?|crackers?', LucideIcons.cookie),
      ('donuts?|doughnuts?', LucideIcons.donut),
      ('pizza', LucideIcons.pizza),
      ('ice cream|frozen yogurt|sherbet|sorbet', LucideIcons.iceCreamCone),
      ('bananas?|plantains?', LucideIcons.banana),
      (
        'berry|berries|strawberries|blueberries|raspberries|cherry|cherries',
        LucideIcons.cherry,
      ),
      ('grapes?|raisins?', LucideIcons.grape),
      (
        'oranges?|lemons?|limes?|grapefruits?|citrus|tangerines?',
        LucideIcons.citrus,
      ),
      ('lettuce|greens|spinach|kale|cabbage|arugula', LucideIcons.leafyGreen),
      ('salads?', LucideIcons.salad),
      ('coffee|tea', LucideIcons.coffee),
      ('wine', LucideIcons.wine),
      ('beer|ale', LucideIcons.beer),
      ('water', LucideIcons.glassWater),
      (
        'nuts?|peanuts?|almonds?|walnuts?|pecans?|cashews?|pistachios?',
        LucideIcons.nut,
      ),
      ('beans?|lentils?|peas|chickpeas|tofu|tempeh|legumes', LucideIcons.bean),
      ('candy|candies|chocolate|caramels?', LucideIcons.candy),
      ('popcorn', LucideIcons.popcorn),
      (
        'shrimp|crabs?|lobsters?|clams?|oysters?|mussels?|scallops?|shellfish',
        LucideIcons.shrimp,
      ),
      ('fish|salmon|tuna|cod|sardines?|anchov(y|ies)', LucideIcons.fish),
      ('chicken|turkey|duck(ling)?|poultry', LucideIcons.drumstick),
      ('bacon|ham|sausages?|hot dogs?|salami|pepperoni|jerky', LucideIcons.ham),
    ])
      (RegExp('\\b($words)\\b', caseSensitive: false), icon),
  ];
}
