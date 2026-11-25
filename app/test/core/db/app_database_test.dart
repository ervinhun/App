import 'dart:io';

import 'package:app/core/db/app_database.dart';
import 'package:app/features/food/data/food_store.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/food/food_store_test.dart' show food;

void main() {
  final uuid = RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$');
  const kept = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';

  test("version 1's sample food gets ids the backend can store", () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final folder = await Directory.systemTemp.createTemp('fridgefriend');
    addTearDown(() => folder.delete(recursive: true));
    AppDatabase open() =>
        AppDatabase(NativeDatabase(File('${folder.path}/db')));

    final v1 = open();
    final before = FoodStore(v1);
    final at = DateTime(2026, 11, 15);
    // Account A's food, changed and set aside, then B's.
    await before.claimFor('A');
    await before.save(food('milk', name: "A's"), at);
    await before.claimFor('B');
    await before.seedOnce([food('eggs', name: 'milk')]);
    await before.save(food('milk', name: "B's"), at);
    await before.save(food(kept), at);
    await before.markSignedOut();
    await v1.customStatement('PRAGMA user_version = 1');
    await v1.close();

    final v2 = open();
    final store = FoodStore(v2);
    final items = {for (final item in await store.items()) item.name: item.id};
    expect(items.keys, {'milk', "B's", 'Milk'});
    expect(items.values, everyElement(matches(uuid)));
    expect(items['Milk'], kept);
    final changes = await v2.select(v2.pendingChanges).get();
    expect([for (final c in changes) c.itemId], [items["B's"], kept]);
    // Still known as B's, not a guest's.
    expect(await store.guestFoodFor('B'), 0);

    await store.claimFor('A');
    final own = (await store.items()).single;
    expect(own.name, "A's");
    expect(own.id, matches(uuid));
    expect(own.id, isNot(items["B's"]));
    expect((await store.nextChange())!.itemId, own.id);
    await v2.close();
  });
}
