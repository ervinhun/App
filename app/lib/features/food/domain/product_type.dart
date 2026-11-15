import 'package:flutter/widgets.dart';

import 'package:app/features/food/domain/food_icons.dart';
import 'package:app/features/food/domain/food_item.dart';

/// A kind of food from the backend's catalogue, e.g. "Milk" in "Dairy & Eggs".
class ProductType {
  const ProductType({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultExpiryDays,
    this.pantryExpiryDays,
    this.fridgeExpiryDays,
    this.freezerExpiryDays,
  });

  final String id;
  final String name;

  /// The category's name, or empty for a type without one.
  final String category;

  /// How long it usually keeps, unopened, where nothing more specific is known.
  final int defaultExpiryDays;

  /// How long it keeps in each storage (USDA FoodKeeper); null where there's
  /// no recommendation for that storage.
  final int? pantryExpiryDays;
  final int? fridgeExpiryDays;
  final int? freezerExpiryDays;

  factory ProductType.fromJson(Map<String, dynamic> json) => ProductType(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    defaultExpiryDays: json['defaultExpiryDays'] as int,
    pantryExpiryDays: json['pantryExpiryDays'] as int?,
    fridgeExpiryDays: json['fridgeExpiryDays'] as int?,
    freezerExpiryDays: json['freezerExpiryDays'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'defaultExpiryDays': defaultExpiryDays,
    'pantryExpiryDays': pantryExpiryDays,
    'fridgeExpiryDays': fridgeExpiryDays,
    'freezerExpiryDays': freezerExpiryDays,
  };

  /// How long it keeps in [storage], unopened; null when it isn't kept there.
  /// A type without per-storage times, e.g. one a user made, keeps its default
  /// anywhere.
  int? expiryDaysIn(StorageLocation storage) {
    if (pantryExpiryDays == null &&
        fridgeExpiryDays == null &&
        freezerExpiryDays == null) {
      return defaultExpiryDays;
    }
    return switch (storage) {
      StorageLocation.pantry => pantryExpiryDays,
      StorageLocation.fridge => fridgeExpiryDays,
      StorageLocation.freezer => freezerExpiryDays,
    };
  }

  bool keepsIn(StorageLocation storage) => expiryDaysIn(storage) != null;

  IconData get icon => FoodIcons.forType(category: category, type: name);

  FoodCategory get group => FoodCategory.fromProduct(category, name);
}
