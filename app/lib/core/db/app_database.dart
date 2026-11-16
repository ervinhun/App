import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  int get schemaVersion => 1;
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
