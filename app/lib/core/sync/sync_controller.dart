import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/db/app_database.dart';
import 'package:app/core/sync/connectivity.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/food/data/food_items_controller.dart';
import 'package:app/features/food/data/food_store.dart';
import 'package:app/features/food/data/guest_food_question.dart';
import 'package:app/features/food/data/items_remote.dart';

@immutable
class SyncStatus {
  const SyncStatus({
    this.pending = 0,
    this.syncing = false,
    this.reachable = true,
    this.rejected = 0,
  });

  /// Changes on this device the backend hasn't got yet.
  final int pending;
  final bool syncing;

  /// False once a sync failed for want of a connection, until one works.
  final bool reachable;

  /// How many changes the backend has refused since the app started, e.g.
  /// because someone else removed the item. Only ever grows, so screens can
  /// tell the user when it does.
  final int rejected;

  SyncStatus copyWith({
    int? pending,
    bool? syncing,
    bool? reachable,
    int? rejected,
  }) => SyncStatus(
    pending: pending ?? this.pending,
    syncing: syncing ?? this.syncing,
    reachable: reachable ?? this.reachable,
    rejected: rejected ?? this.rejected,
  );
}

/// Sends the changes made on this device to the backend, oldest first, then
/// takes the backend's list as the truth for everything else.
///
/// Runs when a change is made, when the user signs in, when the connection
/// comes back, and on a timer after a failure. Only for a signed-in user: a
/// guest's changes stay queued, and are uploaded if they sign in.
class SyncController extends Notifier<SyncStatus> {
  static const _firstRetry = Duration(seconds: 5);
  static const _maxRetry = Duration(minutes: 1);

  Timer? _retryTimer;
  Duration _retryDelay = _firstRetry;
  bool _running = false;
  bool _runAgain = false;

  /// Signing in is deciding whose the food is: nothing is sent meanwhile.
  bool _claiming = false;

  FoodStore get _store => ref.read(foodStoreProvider);

  @override
  SyncStatus build() {
    ref.onDispose(() => _retryTimer?.cancel());
    ref.listen(networkAvailableProvider, (previous, next) {
      if (next.value == true && previous?.value != true) unawaited(syncNow());
    });
    ref.listen(authControllerProvider, (previous, next) {
      final userId = next.value?.id;
      if (userId != null && userId != previous?.value?.id) {
        unawaited(_signedIn(userId));
      }
    }, fireImmediately: true);
    return const SyncStatus();
  }

  /// A change was saved on the device.
  void changed() => unawaited(syncNow());

  /// Makes the food on the phone [userId]'s, asking first whether to add
  /// what a guest added.
  Future<void> _signedIn(String userId) async {
    _claiming = true;
    try {
      final guestFood = await _store.guestFoodFor(userId);
      var add = true;
      if (guestFood > 0) {
        final answer = await ref
            .read(guestFoodQuestionProvider.notifier)
            .ask(guestFood);
        // Signed out, or in as someone else, before answering.
        if (answer == null || !ref.mounted) return;
        add = answer;
      }
      if (await _store.claimFor(userId, addGuestFood: add) && ref.mounted) {
        await ref.read(foodItemsProvider.notifier).reload();
      }
    } finally {
      _claiming = false;
    }
    await syncNow();
  }

  Future<void> syncNow() async {
    if (_claiming) return _updatePending();
    if (_running) {
      _runAgain = true;
      return;
    }
    final remote = ref.read(itemsRemoteProvider);
    final userId = ref.read(authControllerProvider).value?.id;
    if (remote == null || userId == null) return _updatePending();

    _running = true;
    _retryTimer?.cancel();
    state = state.copyWith(syncing: true);
    try {
      do {
        _runAgain = false;
        await _open(remote);
        await _push(remote, userId);
        await _pull(remote, userId);
      } while (_runAgain && ref.mounted);
      _retryDelay = _firstRetry;
      if (ref.mounted) state = state.copyWith(reachable: true);
    } on _UserChanged {
      // Whoever signed in gets a sync of their own.
      _runAgain = true;
    } on _TryLater catch (e) {
      if (ref.mounted) {
        state = state.copyWith(reachable: !e.offline);
        _retryTimer = Timer(_retryDelay, () => unawaited(syncNow()));
        _retryDelay = Duration(
          seconds: min(_retryDelay.inSeconds * 2, _maxRetry.inSeconds),
        );
      }
    } finally {
      _running = false;
      if (ref.mounted) {
        state = state.copyWith(syncing: false);
        await ref.read(foodItemsProvider.notifier).reload();
        await _updatePending();
        // The retry does it if this sync failed.
        if (_runAgain && !(_retryTimer?.isActive ?? false) && ref.mounted) {
          _runAgain = false;
          unawaited(syncNow());
        }
      }
    }
  }

  Future<void> _open(ItemsRemote remote) async {
    try {
      await remote.open();
    } catch (e) {
      debugPrint('Could not open the fridge: $e');
      throw _TryLater(offline: e is ApiException && e.statusCode == null);
    }
  }

  /// Stops a sync that outlived its user: the food on the phone is someone
  /// else's now, or about to be.
  void _checkUser(String userId) {
    if (!ref.mounted ||
        _claiming ||
        ref.read(authControllerProvider).value?.id != userId) {
      throw const _UserChanged();
    }
  }

  Future<void> _push(ItemsRemote remote, String userId) async {
    while (true) {
      final change = await _store.nextChange();
      _checkUser(userId);
      if (change == null) return;
      try {
        switch (change.kind) {
          case ChangeKind.delete:
            await remote.delete(change.itemId, changedAt: change.changedAt);
            _checkUser(userId);
            await _store.completeChange(change);
          case ChangeKind.save:
            final item = await _store.item(change.itemId);
            _checkUser(userId);
            if (item == null) {
              await _store.dropChange(change);
              continue;
            }
            final saved = await remote.save(item, changedAt: change.changedAt);
            _checkUser(userId);
            await _store.completeChange(change, serverItem: saved);
        }
      } on ApiException catch (e) {
        if (_isTemporary(e)) throw _TryLater(offline: e.statusCode == null);
        _checkUser(userId);
        // Refused for good: the item was removed (removal wins over a
        // change), or the user may no longer change it. The pull then shows
        // the backend's copy, or removes the item here too.
        debugPrint('The backend refused a ${change.kind.name}: $e');
        await _store.dropChange(change);
        if (ref.mounted) state = state.copyWith(rejected: state.rejected + 1);
      }
    }
  }

  Future<void> _pull(ItemsRemote remote, String userId) async {
    try {
      final items = await remote.fetchAll();
      _checkUser(userId);
      await _store.applyServerItems(items);
    } on ApiException catch (e) {
      if (_isTemporary(e)) throw _TryLater(offline: e.statusCode == null);
      debugPrint('Could not fetch the food: $e');
    }
  }

  /// Worth trying again later: no connection, the session needs signing in
  /// again, the fridge is gone (the next try opens another), or the backend is
  /// busy or broken.
  static bool _isTemporary(ApiException e) => switch (e.statusCode) {
    null || 401 || 404 || 408 || 429 => true,
    final status => status >= 500,
  };

  Future<void> _updatePending() async {
    final pending = await _store.pendingCount();
    if (ref.mounted) state = state.copyWith(pending: pending);
  }
}

class _TryLater implements Exception {
  const _TryLater({required this.offline});

  final bool offline;
}

/// Another user signed in, or this one out, during their sync.
class _UserChanged implements Exception {
  const _UserChanged();
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);
