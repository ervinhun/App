import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/sync/sync_controller.dart';
import 'package:app/core/utils/ids.dart';
import 'package:app/features/food/data/food_store.dart';
import 'package:app/features/food/data/sample_food.dart';
import 'package:app/features/food/domain/food_item.dart';

/// The food in the current fridge, as the user changes it: loading until the
/// device's copy has been read.
///
/// Changes show at once and are saved on the device ([FoodStore]), so they
/// work offline; the sync controller sends them to the backend when it can.
/// Each change returns what it replaced, so the screen can offer Undo.
class FoodItemsController extends AsyncNotifier<List<FoodItem>> {
  FoodStore get _store => ref.read(foodStoreProvider);

  @override
  Future<List<FoodItem>> build() async {
    await _store.seedOnce(ref.watch(initialFoodProvider));
    return _store.items();
  }

  /// The food as shown; empty while it loads.
  List<FoodItem> get _items => state.value ?? const [];

  set _items(List<FoodItem> items) => state = AsyncData(items);

  /// Shows what the device has, after the sync controller changed it.
  Future<void> reload() async {
    final items = await _store.items();
    if (ref.mounted) _items = items;
  }

  void add(FoodItem item) {
    _items = [..._items, item];
    _save(item);
  }

  /// Marks the item opened today, and returns it as it was before.
  FoodItem markOpened(String id, DateTime today) {
    final before = _items.firstWhere((item) => item.id == id);
    replace(before.opened(today));
    return before;
  }

  /// Puts [item] in place of the item with the same id.
  void replace(FoodItem item) {
    _items = [
      for (final existing in _items) existing.id == item.id ? item : existing,
    ];
    _save(item);
  }

  /// Takes the item out, and returns it with where it was, for [restore].
  (FoodItem, int) remove(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    final item = _items[index];
    _items = [..._items]..removeAt(index);
    _persist(_store.delete(id, DateTime.now()));
    return (item, index);
  }

  /// Puts a removed item back. It comes back under a new id: the removal may
  /// already have reached the backend, where removal wins over a change.
  void restore(FoodItem item, int index) {
    final copy = item.withId(newId());
    _items = [..._items]..insert(index.clamp(0, _items.length), copy);
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

final foodItemsProvider =
    AsyncNotifierProvider<FoodItemsController, List<FoodItem>>(
      FoodItemsController.new,
    );
