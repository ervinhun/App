import 'package:app/core/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart';

/// An empty in-memory database for each test, in place of the app's file.
Override inMemoryDatabase() {
  // Each test opens its own, which drift would otherwise warn about.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return appDatabaseProvider.overrideWith((ref) {
    final db = AppDatabase(NativeDatabase.memory());
    ref.onDispose(db.close);
    return db;
  });
}
