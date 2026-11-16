import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/sync/sync_controller.dart';
import 'package:app/core/utils/ids.dart';
import 'package:app/features/food/data/food_store.dart';
import 'package:app/features/food/data/sample_food.dart';
import 'package:app/features/food/domain/food_item.dart';

/// The food in the current fridge, as the user changes it.
///
/// Changes show at once and are saved on the device ([FoodStore]), so they
/// work offline; the sync controller sends them to the backend when it can.
/// Each change returns what it replaced, so the screen can offer Undo.
class FoodItemsController extends Notifier<List<FoodItem>> {
  FoodStore get _store => ref.read(foodStoreProvider);

  @override
  List<FoodItem> build() {
    unawaited(_load(ref.watch(initialFoodProvider)));
    return const [];
  }

  Future<void> _load(List<FoodItem> seed) async {
    await _store.seedOnce(seed);
    await reload();
  }

  /// Shows what the device has, after the sync controller changed it.
  Future<void> reload() async {
    final items = await _store.items();
    if (ref.mounted) state = items;
  }

  void add(FoodItem item) {
    state = [...state, item];
    _save(item);
  }

  /// Marks the item opened today, and returns it as it was before.
  FoodItem markOpened(String id, DateTime today) {
    final before = state.firstWhere((item) => item.id == id);
    replace(before.opened(today));
    return before;
  }

  /// Puts [item] in place of the item with the same id.
  void replace(FoodItem item) {
    state = [
      for (final existing in state) existing.id == item.id ? item : existing,
    ];
    _save(item);
  }

  /// Takes the item out, and returns it with where it was, for [restore].
  (FoodItem, int) remove(String id) {
    final index = state.indexWhere((item) => item.id == id);
    final item = state[index];
    state = [...state]..removeAt(index);
    _persist(_store.delete(id, DateTime.now()));
    return (item, index);
  }

  /// Puts a removed item back. It comes back under a new id: the removal may
  /// already have reached the backend, where removal wins over a change.
  void restore(FoodItem item, int index) {
    final copy = item.withId(newId());
    state = [...state]..insert(index.clamp(0, state.length), copy);
    _save(copy);
  }

  void _save(FoodItem item) => _persist(_store.save(item, DateTime.now()));

  void _persist(Future<void> write) => unawaited(
    write.then(
      (_) {
        if (ref.mounted) ref.read(syncControllerProvider.notifier).changed();
      },
      onError: (Object e, StackTrace stackTrace) =>
          debugPrint('Could not save a food change: $e\n$stackTrace'),
    ),
  );
}

final foodItemsProvider = NotifierProvider<FoodItemsController, List<FoodItem>>(
  FoodItemsController.new,
);
