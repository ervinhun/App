import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/db/app_database.dart';
import 'package:app/features/food/domain/food_item.dart';

typedef _Food = ({List<FoodItemRow> rows, List<PendingChange> changes});

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

  /// Food a guest added and chose to keep on the phone rather than add to the
  /// account signing in ([claimFor]).
  static const _keptByGuestKey = 'food_kept_by_guest';

  /// The items on the phone when the account signed out ([markSignedOut]).
  static const _signedOutItemsKey = 'food_signed_out_items';

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

  /// Notes which food the signed-in account leaves on the phone as it signs
  /// out, so what a guest adds after can be told apart from it.
  Future<void> markSignedOut() => _db.transaction(() async {
    if (await _meta(_ownerKey) == null) return;
    if (await _meta(_signedOutItemsKey) != null) return;
    final rows = await _db.select(_db.foodItems).get();
    await _setMeta(
      _signedOutItemsKey,
      jsonEncode([for (final row in rows) row.id]),
    );
  });

  /// How many items a guest added on this phone, which signing in as
  /// [userId] can add to that account. None when [userId] is still signed in,
  /// e.g. when the app starts again.
  Future<int> guestFoodFor(String userId) => _db.transaction(() async {
    final owner = await _meta(_ownerKey);
    if (await _stillSignedIn(owner, userId)) return 0;
    final kept = await _kept(_keptByGuestKey);
    return (await _guestItemIds(owner)).length + (kept?.rows.length ?? 0);
  });

  /// Makes this device's food belong to [userId], and says whether that
  /// changed it.
  ///
  /// Each account keeps its own food on the phone, changes not uploaded yet
  /// included, so signing in as someone else never sends one account's food
  /// to another:
  /// * Food the account last signed in left is set aside for when it signs in
  ///   again. It stays on show after signing out, for using the app as a
  ///   guest; what the guest changes in it is that account's too.
  /// * Food [userId] had set aside comes back, and the next sync uploads its
  ///   changes and fetches the rest.
  /// * Food a guest added ([guestFoodFor]) goes to [userId] with
  ///   [addGuestFood], and is uploaded by the next sync. Without, it's kept
  ///   on the phone, out of view, and offered again at the next sign-in.
  Future<bool> claimFor(String userId, {bool addGuestFood = true}) =>
      _db.transaction(() async {
        final owner = await _meta(_ownerKey);
        if (await _stillSignedIn(owner, userId)) return false;
        final switching = owner != null && owner != userId;
        var changed = switching;
        final guestIds = await _guestItemIds(owner);
        final guestFood = guestIds.isEmpty ? null : await _take(guestIds);
        if (guestFood != null && !addGuestFood) {
          await _keep(_keptByGuestKey, guestFood);
          changed = true;
        }
        if (switching) await _keep(_setAsideKey(owner), await _take());
        await _deleteMeta(_signedOutItemsKey);
        await _setMeta(_ownerKey, userId);
        if (switching && await _bringBack(_setAsideKey(userId))) changed = true;
        if (addGuestFood) {
          if (guestFood != null) await _put(guestFood);
          if (await _bringBack(_keptByGuestKey)) changed = true;
        }
        return changed;
      });

  /// Whether [userId] owns the food and hasn't signed out since: nothing to
  /// decide.
  Future<bool> _stillSignedIn(String? owner, String userId) async =>
      owner == userId && await _meta(_signedOutItemsKey) == null;

  /// The items a guest added: new or changed since [owner] signed out, or
  /// since the app was installed. Sample food the guest never changed isn't
  /// theirs: it's never uploaded.
  Future<Set<String>> _guestItemIds(String? owner) async {
    final signedOut = await _meta(_signedOutItemsKey);
    // Not signed out on this phone: it's all the account's.
    if (owner != null && signedOut == null) return const {};
    final accounts = signedOut == null
        ? const <String>{}
        : {...(jsonDecode(signedOut) as List<dynamic>).cast<String>()};
    final present = {
      for (final row in await _db.select(_db.foodItems).get()) row.id,
    };
    final saves = await (_db.select(
      _db.pendingChanges,
    )..where((t) => t.kind.equalsValue(ChangeKind.save))).get();
    return {
      for (final change in saves)
        if (present.contains(change.itemId) &&
            !accounts.contains(change.itemId))
          change.itemId,
    };
  }

  /// Keeps [food] out of view under [key], after what's already there.
  Future<void> _keep(String key, _Food food) async {
    final kept = await _kept(key);
    final rows = [...?kept?.rows, ...food.rows];
    final changes = [...?kept?.changes, ...food.changes];
    await _setMeta(
      key,
      jsonEncode({
        'items': [for (final row in rows) row.toJson()],
        'changes': [for (final change in changes) change.toJson()],
      }),
    );
  }

  Future<_Food?> _kept(String key) async {
    final json = await _meta(key);
    if (json == null) return null;
    final kept = jsonDecode(json) as Map<String, dynamic>;
    return (
      rows: [
        for (final row in kept['items'] as List<dynamic>)
          FoodItemRow.fromJson(row as Map<String, dynamic>),
      ],
      changes: [
        for (final change in kept['changes'] as List<dynamic>)
          PendingChange.fromJson(change as Map<String, dynamic>),
      ],
    );
  }

  /// Brings back the food kept under [key], if any, and says whether there
  /// was some.
  Future<bool> _bringBack(String key) async {
    final kept = await _kept(key);
    if (kept == null) return false;
    await _deleteMeta(key);
    await _put(kept);
    return true;
  }

  /// Removes the items with [ids], or all, with their queued changes, and
  /// returns them, changes oldest first.
  Future<_Food> _take([Set<String>? ids]) async {
    final rows = _db.select(_db.foodItems);
    final changes = _db.select(_db.pendingChanges)
      ..orderBy([(t) => OrderingTerm(expression: t.seq)]);
    final deleteRows = _db.delete(_db.foodItems);
    final deleteChanges = _db.delete(_db.pendingChanges);
    if (ids != null) {
      rows.where((t) => t.id.isIn(ids));
      changes.where((t) => t.itemId.isIn(ids));
      deleteRows.where((t) => t.id.isIn(ids));
      deleteChanges.where((t) => t.itemId.isIn(ids));
    }
    final food = (rows: await rows.get(), changes: await changes.get());
    await deleteRows.go();
    await deleteChanges.go();
    return food;
  }

  Future<void> _put(_Food food) async {
    for (final row in food.rows) {
      await _db.into(_db.foodItems).insertOnConflictUpdate(row);
    }
    // In the order given, so they keep their order in the queue.
    for (final change in food.changes) {
      await _queue(change.itemId, change.kind, change.changedAt);
    }
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
