import 'package:app/core/db/app_database.dart';
import 'package:app/features/food/data/food_items_controller.dart';
import 'package:app/features/food/data/food_store.dart';
import 'package:app/features/food/data/sample_food.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'food_store_test.dart' show food;

/// A store whose saves fail, as when the phone is out of space.
class _FailingStore extends FoodStore {
  _FailingStore(super.db);

  bool failSaves = false;

  @override
  Future<void> save(FoodItem item, DateTime changedAt) async {
    if (failSaves) throw StateError('disk full');
    return super.save(item, changedAt);
  }
}

void main() {
  late AppDatabase db;
  late _FailingStore store;
  late ProviderContainer c;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    store = _FailingStore(db);
    c = ProviderContainer.test(
      overrides: [
        foodStoreProvider.overrideWithValue(store),
        initialFoodProvider.overrideWithValue([food('milk')]),
      ],
    );
    addTearDown(db.close);
    c.listen(foodItemsProvider, (_, _) {});
    await c.read(foodItemsProvider.future);
  });

  Set<String> shown() => {
    for (final item in c.read(foodItemsProvider).requireValue) item.id,
  };

  Future<void> settle() async {
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('a change shows at once and is saved', () async {
    c.read(foodItemsProvider.notifier).add(food('eggs'));
    expect(shown(), {'milk', 'eggs'});

    await settle();
    expect((await store.items()).map((i) => i.id), contains('eggs'));
  });

  test('a change that fails to save goes, to match the phone', () async {
    store.failSaves = true;

    c.read(foodItemsProvider.notifier).add(food('eggs'));
    expect(shown(), {'milk', 'eggs'});

    await settle();
    expect(shown(), {'milk'});
  });
}
