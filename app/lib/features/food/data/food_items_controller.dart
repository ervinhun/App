import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/food/data/sample_food.dart';
import 'package:app/features/food/domain/food_item.dart';

/// The food in the current fridge, as the user changes it.
///
/// Changes are kept in memory only, until the backend has an items endpoint.
/// Each change returns what it replaced, so the screen can offer Undo.
class FoodItemsController extends Notifier<List<FoodItem>> {
  @override
  List<FoodItem> build() => ref.watch(initialFoodProvider);

  void add(FoodItem item) => state = [...state, item];

  /// Marks the item opened today, and returns it as it was before.
  FoodItem markOpened(String id, DateTime today) {
    final before = state.firstWhere((item) => item.id == id);
    replace(before.opened(today));
    return before;
  }

  /// Puts [item] in place of the item with the same id.
  void replace(FoodItem item) => state = [
    for (final existing in state) existing.id == item.id ? item : existing,
  ];

  /// Takes the item out, and returns it with where it was, for [restore].
  (FoodItem, int) remove(String id) {
    final index = state.indexWhere((item) => item.id == id);
    final item = state[index];
    state = [...state]..removeAt(index);
    return (item, index);
  }

  void restore(FoodItem item, int index) =>
      state = [...state]..insert(index.clamp(0, state.length), item);
}

final foodItemsProvider = NotifierProvider<FoodItemsController, List<FoodItem>>(
  FoodItemsController.new,
);
