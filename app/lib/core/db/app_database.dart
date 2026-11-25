import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/utils/ids.dart';
import 'package:app/features/food/domain/food_item.dart';

part 'app_database.g.dart';

/// The food on this device: what the dashboard shows, online or not.
@DataClassName('FoodItemRow')
class FoodItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get amount => text()();
  TextColumn get category => textEnum<FoodCategory>()();
  TextColumn get productCategory => text()();
  TextColumn get productType => text()();
  TextColumn get storage => textEnum<StorageLocation>()();
  DateTimeColumn get bestBefore => dateTime()();
  DateTimeColumn get openedOn => dateTime().nullable()();
  DateTimeColumn get openedExpiresOn => dateTime().nullable()();

  /// Whether the backend has this item, so removing it needs a request.
  BoolColumn get onServer => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

enum ChangeKind { save, delete }

/// Local changes the backend hasn't got yet, oldest first. At most one per
/// item: a later change to the same item replaces it, as only the item's
/// latest state matters.
class PendingChanges extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get itemId => text().unique()();
  TextColumn get kind => textEnum<ChangeKind>()();

  /// When the user made the change, which decides who wins when someone else
  /// changed the same item meanwhile.
  DateTimeColumn get changedAt => dateTime()();
}

/// Small facts about this device's data, such as whether it was seeded.
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [FoodItems, PendingChanges, AppMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'fridgefriend'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (_, from, _) async {
      if (from < 2) await _giveSampleFoodUuids();
    },
  );

  /// Version 1's sample food had ids such as "milk", which the backend can't
  /// store once the user changes it.
  Future<void> _giveSampleFoodUuids() async {
    final shown = <String, String>{};
    for (final row in await select(foodItems).get()) {
      await (update(foodItems)..where((t) => t.id.equals(row.id))).write(
        FoodItemsCompanion(id: Value(_uuidFor(row.id, shown))),
      );
    }
    for (final change in await select(pendingChanges).get()) {
      await (update(
        pendingChanges,
      )..where((t) => t.seq.equals(change.seq))).write(
        PendingChangesCompanion(itemId: Value(_uuidFor(change.itemId, shown))),
      );
    }
    for (final meta in await select(appMeta).get()) {
      final renamed = switch (meta.value) {
        // The items on the phone at sign-out, see FoodStore.
        final value when value.startsWith('[') => [
          for (final id in jsonDecode(value) as List<dynamic>)
            _uuidFor(id as String, shown),
        ],
        // Food kept out of view, each with ids of its own: it may be another
        // account's.
        final value when value.startsWith('{') => _renameKept(
          jsonDecode(value) as Map<String, dynamic>,
        ),
        _ => null,
      };
      if (renamed == null) continue;
      await into(appMeta)
          .insertOnConflictUpdate(meta.copyWith(value: jsonEncode(renamed)));
    }
  }

  static Map<String, dynamic> _renameKept(Map<String, dynamic> kept) {
    final ids = <String, String>{};
    List<Map<String, dynamic>> rename(Object? rows, String key) => [
      for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>())
        {...row, key: _uuidFor(row[key] as String, ids)},
    ];
    return {
      'items': rename(kept['items'], 'id'),
      'changes': rename(kept['changes'], 'itemId'),
    };
  }

  static String _uuidFor(String id, Map<String, String> ids) =>
      _uuid.hasMatch(id) ? id : ids.putIfAbsent(id, newId);

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
