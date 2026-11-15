import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/food/domain/food_item.dart';

/// The backend's copy of the current fridge's food (US-30).
///
/// Failures throw `ApiException`: no status code means the backend couldn't
/// be reached. The backend applies these rules for changes made offline:
///
/// * Each item is decided on its own: the change with the later `changedAt`
///   wins, so an older offline edit doesn't undo a newer one.
/// * Removal wins over a change: saving an item someone removed fails with
///   `410 Gone` (or `404`), and doesn't bring it back.
/// * A member without the right to add or use food, or whose access ended,
///   gets `403`.
abstract interface class ItemsRemote {
  /// Creates the item with its id, or updates it. Returns the item as the
  /// backend now has it: someone else's version when theirs is newer.
  Future<FoodItem> save(FoodItem item, {required DateTime changedAt});

  /// Removes the item. Removing one that is already gone succeeds.
  Future<void> delete(String id, {required DateTime changedAt});

  Future<List<FoodItem>> fetchAll();
}

/// Null until the backend has items endpoints: changes then stay queued on
/// the device, and are sent once an implementation is provided here.
final itemsRemoteProvider = Provider<ItemsRemote?>((ref) => null);
