import 'package:flutter/foundation.dart';

import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/food/domain/product_type.dart';

/// How long something keeps, in days, as the user set it; null to go by
/// what it would otherwise be.
@immutable
class ExpiryRule {
  const ExpiryRule({this.unopened, this.opened});

  final int? unopened;
  final int? opened;

  bool get isEmpty => unopened == null && opened == null;

  factory ExpiryRule.fromJson(Map<String, dynamic> json) => ExpiryRule(
    unopened: json['unopened'] as int?,
    opened: json['opened'] as int?,
  );

  Map<String, dynamic> toJson() => {'unopened': unopened, 'opened': opened};

  @override
  bool operator ==(Object other) =>
      other is ExpiryRule &&
      other.unopened == unopened &&
      other.opened == opened;

  @override
  int get hashCode => Object.hash(unopened, opened);

  @override
  String toString() => 'ExpiryRule(unopened: $unopened, opened: $opened)';
}

/// The user's Expiry Defaults: how long food keeps in each storage, by
/// product category and, more specifically, by product type. Saved on the
/// phone (the backend has no place for them) and used when food is added or
/// opened here.
///
/// A type's own rule wins over its category's, which wins over the
/// catalogue's per-storage times (unopened) or [suggestedOpenedDays]
/// (opened).
@immutable
class ExpiryDefaults {
  const ExpiryDefaults([this.rules = const {}]);

  static const none = ExpiryDefaults();

  /// By [key].
  final Map<String, ExpiryRule> rules;

  /// How many days food keeps once opened, by food group, unless the user
  /// set otherwise.
  static const suggestedOpenedDays = {
    FoodCategory.meat: 2,
    FoodCategory.fish: 1,
    FoodCategory.dairy: 4,
    FoodCategory.veg: 3,
    FoodCategory.eggs: 7,
    FoodCategory.other: 5,
  };

  /// "fridge/Dairy & Eggs" for a category's rule, and
  /// "fridge/Dairy & Eggs/Milk (plain or flavored)" for a type's: food items
  /// keep their category and type by name.
  static String key(StorageLocation storage, String category, [String? type]) =>
      [storage.name, category, ?type].join('/');

  ExpiryRule rule(StorageLocation storage, String category, [String? type]) =>
      rules[key(storage, category, type)] ?? const ExpiryRule();

  /// How long [type] keeps unopened in [storage]; null when it isn't kept
  /// there.
  int? unopenedDays(ProductType type, StorageLocation storage) =>
      rule(storage, type.category, type.name).unopened ??
      rule(storage, type.category).unopened ??
      type.expiryDaysIn(storage);

  /// How long food keeps once opened, in [storage].
  int openedDays(
    StorageLocation storage, {
    required String category,
    required String type,
  }) =>
      rule(storage, category, type).opened ??
      rule(storage, category).opened ??
      suggestedOpenedDays[FoodCategory.fromProduct(category, type)]!;

  /// [type] with the user's unopened times in place of the catalogue's, so
  /// whatever reads them (the type picker, Add food) uses them.
  ProductType applyTo(ProductType type) {
    final changed = StorageLocation.values.any(
      (s) =>
          rule(s, type.category, type.name).unopened != null ||
          rule(s, type.category).unopened != null,
    );
    if (!changed) return type;
    return ProductType(
      id: type.id,
      name: type.name,
      category: type.category,
      defaultExpiryDays: type.defaultExpiryDays,
      pantryExpiryDays: unopenedDays(type, StorageLocation.pantry),
      fridgeExpiryDays: unopenedDays(type, StorageLocation.fridge),
      freezerExpiryDays: unopenedDays(type, StorageLocation.freezer),
    );
  }

  /// These defaults with [rule] for [key]; an empty rule removes it.
  ExpiryDefaults withRule(String key, ExpiryRule rule) =>
      ExpiryDefaults({...rules, key: rule}..removeWhere((_, r) => r.isEmpty));

  factory ExpiryDefaults.fromJson(Map<String, dynamic> json) => ExpiryDefaults({
    for (final MapEntry(:key, :value) in json.entries)
      key: ExpiryRule.fromJson(value as Map<String, dynamic>),
  });

  Map<String, dynamic> toJson() => {
    for (final MapEntry(:key, :value) in rules.entries) key: value.toJson(),
  };
}
