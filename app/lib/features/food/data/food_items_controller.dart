import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/food/data/sample_food.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/fridges/data/fridge_spaces_controller.dart';

/// The food in one fridge space, as the user changes it.
///
/// Changes are kept in memory only, until the backend has an items endpoint.
/// Each change returns what it replaced, so the screen can offer Undo.
class FoodItemsController extends Notifier<List<FoodItem>> {
  FoodItemsController(this.spaceId);

  final String spaceId;

  // Sample food in the user's first (oldest) fridge space only. Read, not
  // watched, so adding a space doesn't reset it.
  @override
  List<FoodItem> build() =>
      ref.read(fridgeSpacesProvider).value?.all.firstOrNull?.id == spaceId
      ? ref.watch(initialFoodProvider)
      : const [];

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

  /// Takes out what [test] matches, and returns the food before, for [undoTo].
  List<FoodItem> removeWhere(bool Function(FoodItem) test) {
    final before = state;
    state = [...state.where((item) => !test(item))];
    return before;
  }

  void undoTo(List<FoodItem> before) => state = before;
}

/// The food in the fridge space with this id. Kept while the user switches
/// between spaces, so each one keeps its own changes.
final spaceFoodProvider =
    NotifierProvider.family<FoodItemsController, List<FoodItem>, String>(
      FoodItemsController.new,
    );

/// The food in the current fridge space, read-only (e.g. for notifications).
final foodItemsProvider = Provider<List<FoodItem>>((ref) {
  final id = ref.watch(fridgeSpacesProvider).value?.current?.id;
  return id == null ? const [] : ref.watch(spaceFoodProvider(id));
});
