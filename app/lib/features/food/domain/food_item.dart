import 'package:flutter/widgets.dart';

import 'package:app/features/food/domain/food_icons.dart';

enum StorageLocation { fridge, freezer, pantry }

/// The app's own food groups, for the filter chips and card colours.
enum FoodCategory {
  meat,
  fish,
  dairy,
  veg,
  eggs,
  other;

  /// The group for a backend product category and type, e.g. "Dairy & Eggs" /
  /// "Eggs (in shell)" is eggs.
  static FoodCategory fromProduct(String category, String type) {
    bool matches(String text, String words) =>
        RegExp('\\b($words)\\b', caseSensitive: false).hasMatch(text);

    if (matches(type, 'eggs?')) return eggs;
    if (matches(category, 'seafood') ||
        matches(type, 'fish|salmon|tuna|cod|shrimp|shellfish|prawns?')) {
      return fish;
    }
    if (matches(category, 'meat|poultry')) return meat;
    if (matches(category, 'dairy')) return dairy;
    if (matches(category, 'vegetables?|fruits?')) return veg;
    return other;
  }
}

/// How soon something needs eating, which colours its card.
enum ExpiryUrgency { soon, upcoming, later }

/// One thing in a fridge, freezer or pantry.
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.productCategory,
    required this.productType,
    required this.storage,
    required this.bestBefore,
    this.openedOn,
    this.openedExpiresOn,
  });

  final String id;
  final String name;

  /// What's there, as shown to the user: "500 g", "6 eggs".
  final String amount;

  /// The app's own grouping, for the filter chips and card colours.
  final FoodCategory category;

  /// The backend's product category and type, as seeded by its DbInitializer:
  /// "Dairy & Eggs" / "Milk (plain or flavored)".
  final String productCategory;
  final String productType;
  final StorageLocation storage;

  /// The date printed on the pack.
  final DateTime bestBefore;
  final DateTime? openedOn;

  /// The earlier date it must be eaten by once opened.
  final DateTime? openedExpiresOn;

  IconData get icon =>
      FoodIcons.forType(category: productCategory, type: productType);

  bool get isOpened => openedOn != null;

  DateTime get expiresOn => openedExpiresOn ?? bestBefore;

  /// Whole days from [today] until [expiresOn]: 0 on the day, negative after.
  int daysLeft(DateTime today) =>
      _dateOnly(expiresOn).difference(_dateOnly(today)).inDays;

  /// This item, opened [today]: it now has to be eaten within its category's
  /// shelf life once open, or by its printed date if that comes first.
  FoodItem opened(DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    final eatBy = day.add(Duration(days: _openedShelfLifeDays[category]!));
    return FoodItem(
      id: id,
      name: name,
      amount: amount,
      category: category,
      productCategory: productCategory,
      productType: productType,
      storage: storage,
      bestBefore: bestBefore,
      openedOn: day,
      openedExpiresOn: eatBy.isBefore(bestBefore) ? eatBy : bestBefore,
    );
  }

  // TODO: replace with the user's Expiry Defaults (Figma node 117:194) once
  // that screen exists.
  static const _openedShelfLifeDays = {
    FoodCategory.meat: 2,
    FoodCategory.fish: 1,
    FoodCategory.dairy: 4,
    FoodCategory.veg: 3,
    FoodCategory.eggs: 7,
    FoodCategory.other: 5,
  };

  ExpiryUrgency urgency(DateTime today) => switch (daysLeft(today)) {
    <= 2 => ExpiryUrgency.soon,
    <= 5 => ExpiryUrgency.upcoming,
    _ => ExpiryUrgency.later,
  };

  // UTC, so a daylight saving change can't make a day 23 hours long.
  static DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
}
