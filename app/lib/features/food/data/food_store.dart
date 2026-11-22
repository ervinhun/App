import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/db/app_database.dart';
import 'package:app/features/food/domain/food_item.dart';

/// The food kept on this device, and the changes the backend hasn't got yet.
///
/// Every change is saved here first, so the app works the same offline. The
/// sync controller then sends the queued changes, oldest first, and folds the
/// backend's answers back in.
class FoodStore {
  FoodStore(this._db);

  final AppDatabase _db;

  static const _seededKey = 'food_seeded';
  static const _ownerKey = 'food_owner';

  /// Each account's food while another account is signed in ([claimFor]).
  static String _setAsideKey(String userId) => 'food_set_aside:$userId';

  Future<List<FoodItem>> items() async => [
    for (final row in await _db.select(_db.foodItems).get()) _toItem(row),
  ];

  Future<FoodItem?> item(String id) async {
    final row = await (_db.select(
      _db.foodItems,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toItem(row);
  }

  /// Fills an empty store with [items] the first time the app runs, without
  /// queueing them for the backend.
  Future<void> seedOnce(List<FoodItem> items) => _db.transaction(() async {
    if (await _meta(_seededKey) != null) return;
    for (final item in items) {
      await _db.into(_db.foodItems).insertOnConflictUpdate(_toRow(item));
    }
    await _setMeta(_seededKey, 'true');
  });

  /// Saves [item] and queues it for the backend.
  Future<void> save(FoodItem item, DateTime changedAt) =>
      _db.transaction(() async {
        // Leaves onServer as it was.
        await _db.into(_db.foodItems).insertOnConflictUpdate(_toRow(item));
        await _queue(item.id, ChangeKind.save, changedAt);
      });

  /// Removes the item, and queues the removal if the backend has it or may
  /// be getting it: a queued save may already be on its way, and would bring
  /// the item back if its removal weren't sent after it. Removing an item the
  /// backend never got succeeds, so the removal is harmless otherwise.
  Future<void> delete(String id, DateTime changedAt) =>
      _db.transaction(() async {
        final row = await (_db.select(
          _db.foodItems,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        final queued = await (_db.select(
          _db.pendingChanges,
        )..where((t) => t.itemId.equals(id))).getSingleOrNull();
        await (_db.delete(_db.foodItems)..where((t) => t.id.equals(id))).go();
        // Otherwise it never reached the backend: nothing to tell it.
        if ((row?.onServer ?? false) || queued != null) {
          await _queue(id, ChangeKind.delete, changedAt);
        }
      });

  Future<void> _queue(String itemId, ChangeKind kind, DateTime changedAt) => _db
      .into(_db.pendingChanges)
      .insert(
        PendingChangesCompanion.insert(
          itemId: itemId,
          kind: kind,
          changedAt: changedAt,
        ),
        // Keeps its place in the queue, with the latest state.
        onConflict: DoUpdate(
          (_) => PendingChangesCompanion(
            kind: Value(kind),
            changedAt: Value(changedAt),
          ),
          target: [_db.pendingChanges.itemId],
        ),
      );

  /// The oldest change still to send.
  Future<PendingChange?> nextChange() =>
      (_db.select(_db.pendingChanges)
            ..orderBy([(t) => OrderingTerm(expression: t.seq)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> pendingCount() async {
    final count = _db.pendingChanges.seq.count();
    final row = await (_db.selectOnly(
      _db.pendingChanges,
    )..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  /// The backend accepted [sent]. A save also returns the item as the backend
  /// now has it, which may be someone else's later change: that wins, unless
  /// the user changed the item again meanwhile.
  Future<void> completeChange(PendingChange sent, {FoodItem? serverItem}) =>
      _db.transaction(() async {
        final unchanged = await _removeIfUnchanged(sent);
        if (sent.kind == ChangeKind.delete) return;
        if (unchanged && serverItem != null) {
          await _db
              .into(_db.foodItems)
              .insertOnConflictUpdate(_toRow(serverItem, onServer: true));
        } else {
          await (_db.update(_db.foodItems)
                ..where((t) => t.id.equals(sent.itemId)))
              .write(const FoodItemsCompanion(onServer: Value(true)));
        }
      });

  /// The backend refused [sent] for good, so it's no longer sent. The next
  /// [applyServerItems] then puts back the backend's copy of the item, or
  /// removes it if the backend has none.
  Future<void> dropChange(PendingChange sent) => _removeIfUnchanged(sent);

  /// Removes [sent] from the queue unless the user changed the item again
  /// while it was on its way, and says whether it did.
  Future<bool> _removeIfUnchanged(PendingChange sent) async {
    final removed =
        await (_db.delete(_db.pendingChanges)..where(
              (t) =>
                  t.itemId.equals(sent.itemId) &
                  t.kind.equalsValue(sent.kind) &
                  t.changedAt.equals(sent.changedAt),
            ))
            .go();
    return removed > 0;
  }

  /// Takes the backend's list as the truth for every item without a change
  /// still waiting to be sent, including removing those it no longer has.
  Future<void> applyServerItems(List<FoodItem> serverItems) =>
      _db.transaction(() async {
        final pending = {
          for (final change in await _db.select(_db.pendingChanges).get())
            change.itemId,
        };
        final serverIds = {for (final item in serverItems) item.id};
        await (_db.delete(
          _db.foodItems,
        )..where((t) => t.id.isNotIn(serverIds) & t.id.isNotIn(pending))).go();
        for (final item in serverItems) {
          if (pending.contains(item.id)) continue;
          await _db
              .into(_db.foodItems)
              .insertOnConflictUpdate(_toRow(item, onServer: true));
        }
      });

  /// Makes this device's food belong to [userId], and says whether that
  /// changed it.
  ///
  /// Each account keeps its own food on the phone, changes not uploaded yet
  /// included, so signing in as someone else never sends one account's food
  /// to another:
  /// * Food the account last signed in left is set aside for when it signs in
  ///   again. It stays on show after signing out, for using the app as a
  ///   guest; what the guest changes then is that account's too.
  /// * Food [userId] had set aside comes back, and the next sync uploads its
  ///   changes and fetches the rest.
  /// * A guest's food, from before any account signed in, is kept, and
  ///   uploaded by the next sync.
  Future<bool> claimFor(String userId) => _db.transaction(() async {
    final owner = await _meta(_ownerKey);
    if (owner == userId) return false;
    if (owner != null) await _setAside(owner);
    await _setMeta(_ownerKey, userId);
    final restored = await _restore(userId);
    return owner != null || restored;
  });

  /// Moves the food and its queued changes out of view, for [userId].
  Future<void> _setAside(String userId) async {
    final rows = await _db.select(_db.foodItems).get();
    final changes = await (_db.select(
      _db.pendingChanges,
    )..orderBy([(t) => OrderingTerm(expression: t.seq)])).get();
    await _setMeta(
      _setAsideKey(userId),
      jsonEncode({
        'items': [for (final row in rows) row.toJson()],
        'changes': [for (final change in changes) change.toJson()],
      }),
    );
    await _clearFood();
  }

  /// Brings back the food set aside for [userId], if any, and says whether
  /// there was some.
  Future<bool> _restore(String userId) async {
    final json = await _meta(_setAsideKey(userId));
    if (json == null) return false;
    await _deleteMeta(_setAsideKey(userId));
    final saved = jsonDecode(json) as Map<String, dynamic>;
    for (final row in saved['items'] as List<dynamic>) {
      await _db
          .into(_db.foodItems)
          .insertOnConflictUpdate(
            FoodItemRow.fromJson(row as Map<String, dynamic>),
          );
    }
    // Oldest first, so they keep their order in the queue.
    for (final change in saved['changes'] as List<dynamic>) {
      final c = PendingChange.fromJson(change as Map<String, dynamic>);
      await _queue(c.itemId, c.kind, c.changedAt);
    }
    return true;
  }

  Future<void> _clearFood() async {
    await _db.delete(_db.foodItems).go();
    await _db.delete(_db.pendingChanges).go();
  }

  Future<String?> _meta(String key) async => (await (_db.select(
    _db.appMeta,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _deleteMeta(String key) =>
      (_db.delete(_db.appMeta)..where((t) => t.key.equals(key))).go();

  Future<void> _setMeta(String key, String value) => _db
      .into(_db.appMeta)
      .insertOnConflictUpdate(AppMetaCompanion.insert(key: key, value: value));

  static FoodItem _toItem(FoodItemRow row) => FoodItem(
    id: row.id,
    name: row.name,
    amount: row.amount,
    category: row.category,
    productCategory: row.productCategory,
    productType: row.productType,
    storage: row.storage,
    bestBefore: row.bestBefore,
    openedOn: row.openedOn,
    openedExpiresOn: row.openedExpiresOn,
  );

  static FoodItemsCompanion _toRow(FoodItem item, {bool? onServer}) =>
      FoodItemsCompanion.insert(
        id: item.id,
        name: item.name,
        amount: item.amount,
        category: item.category,
        productCategory: item.productCategory,
        productType: item.productType,
        storage: item.storage,
        bestBefore: item.bestBefore,
        openedOn: Value(item.openedOn),
        openedExpiresOn: Value(item.openedExpiresOn),
        onServer: onServer == null ? const Value.absent() : Value(onServer),
      );
}

final foodStoreProvider = Provider<FoodStore>(
  (ref) => FoodStore(ref.watch(appDatabaseProvider)),
);
