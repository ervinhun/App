import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/sync/connectivity.dart';
import 'package:app/features/auth/data/guest_mode.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/fridges/data/fridge_details.dart';
import 'package:app/features/fridges/data/fridges_api.dart';
import 'package:app/features/fridges/data/fridges_cache.dart';
import 'package:app/features/fridges/domain/fridge.dart';

@immutable
class FridgesState {
  const FridgesState({
    required this.fridges,
    this.currentId,
    this.reachable = true,
  });

  final List<Fridge> fridges;
  final String? currentId;

  /// False when the backend couldn't be reached on the last try.
  final bool reachable;

  /// The fridge being managed: the one the user picked, else their first.
  Fridge? get current {
    for (final fridge in fridges) {
      if (fridge.id == currentId) return fridge;
    }
    return fridges.firstOrNull;
  }

  /// The user's fridges other than [current].
  List<Fridge> get others => [
    for (final fridge in fridges)
      if (fridge.id != current?.id) fridge,
  ];

  FridgesState copyWith({
    List<Fridge>? fridges,
    String? currentId,
    bool? reachable,
  }) => FridgesState(
    fridges: fridges ?? this.fridges,
    currentId: currentId ?? this.currentId,
    reachable: reachable ?? this.reachable,
  );
}

/// How a change was saved.
enum SaveOutcome {
  /// The backend has it.
  saved,

  /// Kept on this phone until the backend can be reached: the fridge is the
  /// user's alone, so it can't clash with anyone else's change.
  queued,
}

/// The user's fridges: the copy saved on the phone first, then the
/// backend's. A guest has one, [Fridge.local], kept on the phone only.
///
/// Offline, a fridge can only be changed when nobody else uses it
/// ([Fridge.isSolo]); those changes are uploaded when the connection is back.
/// A shared fridge waits for the connection, so two people's changes can't
/// silently overwrite each other.
///
/// Changes throw [ApiException] with a message for the user.
class FridgesController extends StreamNotifier<FridgesState> {
  FridgesApi get _api => ref.read(fridgesApiProvider);
  FridgesCache get _cache => ref.read(fridgesCacheProvider);

  /// Whose fridges these are: the user's id, or [Fridge.localId] for a guest.
  String? _owner;

  /// Serialises the read-change-write of the pending changes.
  Future<void> _pendingLock = Future.value();

  @override
  Stream<FridgesState> build() async* {
    final userId = ref.watch(authControllerProvider.select((a) => a.value?.id));
    final guest = ref.watch(guestModeProvider.select((g) => g.value ?? false));
    ref.listen(networkAvailableProvider, (previous, next) {
      // Back online: upload what changed meanwhile, and catch up.
      if (next.value == true && previous?.value == false) ref.invalidateSelf();
    });

    final owner = _owner = userId ?? (guest ? Fridge.localId : null);
    if (owner == null) {
      yield const FridgesState(fridges: []);
      return;
    }
    final currentId = await _cache.currentId();
    final saved = await _cache.fridges(owner);
    if (owner == Fridge.localId) {
      yield FridgesState(fridges: saved ?? const [Fridge.local]);
      return;
    }
    if (saved != null) yield FridgesState(fridges: saved, currentId: currentId);

    await _pushPending();
    try {
      final fresh = await _api.mine();
      // A change that couldn't be uploaded yet still shows.
      final pending = await _cache.pending();
      final fridges = [
        for (final fridge in fresh)
          switch (pending[fridge.id]?.name) {
            final name? => fridge.copyWith(name: name),
            null => fridge,
          },
      ];
      await _cache.saveFridges(owner, fridges);
      yield FridgesState(fridges: fridges, currentId: currentId);
    } on ApiException catch (e) {
      if (saved == null) rethrow;
      debugPrint('Could not refresh the fridges: $e');
      yield FridgesState(
        fridges: saved,
        currentId: currentId,
        reachable: !e.isOffline,
      );
    }
  }

  FridgesState get _state => state.value ?? const FridgesState(fridges: []);

  /// Whether the backend can be reached, as far as the app knows.
  bool get _online =>
      (ref.read(networkAvailableProvider).value ?? true) && _state.reachable;

  Future<void> select(String id) async {
    state = AsyncData(_state.copyWith(currentId: id));
    await _cache.saveCurrentId(id);
  }

  Future<Fridge> create(String name) async {
    final fridge = await _api.create(name.trim());
    await _put(fridge);
    await select(fridge.id);
    return fridge;
  }

  Future<Fridge> join(String inviteCode) async {
    final fridge = await _api.join(inviteCode.trim());
    await _put(fridge);
    await select(fridge.id);
    return fridge;
  }

  Future<SaveOutcome> rename(Fridge fridge, String name) async {
    final renamed = fridge.copyWith(name: name.trim());
    final outcome = await saveOrQueue(
      fridge,
      upload: () async => _put(await _api.rename(fridge.id, renamed.name)),
      queue: (pending) => pending.withName(renamed.name),
    );
    if (outcome == SaveOutcome.queued) await _put(renamed);
    return outcome;
  }

  Future<Fridge> regenerateInviteCode(Fridge fridge) async {
    final updated = await _api.regenerateInviteCode(fridge.id);
    await _put(updated);
    return updated;
  }

  /// Deletes the fridge, which only its owner can.
  Future<void> delete(Fridge fridge) async {
    await _api.delete(fridge.id);
    await _drop(fridge.id);
  }

  /// Leaves a fridge someone else owns.
  Future<void> leave(Fridge fridge) async {
    await _api.removeMember(fridge.id, ref.read(currentUserIdProvider));
    await _drop(fridge.id);
  }

  /// Reloads after something that changes a fridge's member count.
  void reload() => ref.invalidateSelf();

  /// Runs [upload], or, offline in a fridge nobody else uses, keeps the
  /// change on the phone with [queue] for later. A guest's fridge only ever
  /// lives on the phone: their changes need neither.
  Future<SaveOutcome> saveOrQueue(
    Fridge fridge, {
    required Future<void> Function() upload,
    required PendingFridgeChange Function(PendingFridgeChange) queue,
  }) async {
    if (fridge.isLocal) return SaveOutcome.queued;
    if (_online) {
      try {
        await upload();
        return SaveOutcome.saved;
      } on ApiException catch (e) {
        if (!e.isOffline || !fridge.isSolo) rethrow;
      }
    } else if (!fridge.isSolo) {
      throw ApiException(sharedOfflineMessage);
    }
    await _locked(() async {
      final pending = await _cache.pending();
      pending[fridge.id] = queue(
        pending[fridge.id] ?? const PendingFridgeChange(),
      );
      await _cache.savePending(pending);
    });
    if (ref.mounted) state = AsyncData(_state.copyWith(reachable: false));
    return SaveOutcome.queued;
  }

  static const sharedOfflineMessage =
      "You're offline. Others use this fridge too, so changes wait until "
      "you're back online.";

  /// Uploads the changes made offline. One the backend refuses for good,
  /// e.g. because the fridge was deleted, is dropped.
  Future<void> _pushPending() => _locked(() async {
    final pending = await _cache.pending();
    final uploaded = <String>[];
    for (final MapEntry(key: id, value: change) in [...pending.entries]) {
      try {
        if (change.name case final name?) await _api.rename(id, name);
        if (change.alerts case final alerts?) {
          await _api.saveAlertSettings(id, alerts);
        }
        uploaded.add(id);
      } on ApiException catch (e) {
        if (_isTemporary(e)) break;
        debugPrint('The backend refused an offline fridge change: $e');
      }
      pending.remove(id);
      await _cache.savePending(pending);
    }
    for (final id in uploaded) {
      if (ref.mounted) ref.invalidate(alertSettingsProvider(id));
    }
  });

  /// Adds [fridge] to the list, or puts it in place of the old copy.
  Future<void> _put(Fridge fridge) async {
    final fridges = [..._state.fridges];
    final index = fridges.indexWhere((f) => f.id == fridge.id);
    index < 0 ? fridges.add(fridge) : fridges[index] = fridge;
    await _save(fridges);
  }

  Future<void> _drop(String id) async {
    await _save([
      for (final f in _state.fridges)
        if (f.id != id) f,
    ]);
  }

  Future<void> _save(List<Fridge> fridges) async {
    if (ref.mounted) state = AsyncData(_state.copyWith(fridges: fridges));
    if (_owner case final owner?) await _cache.saveFridges(owner, fridges);
  }

  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _pendingLock.then((_) => action());
    _pendingLock = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Worth trying again later, as in `SyncController`.
  static bool _isTemporary(ApiException e) => switch (e.statusCode) {
    null || 401 || 408 || 429 => true,
    final status => status >= 500,
  };
}

final fridgesProvider = StreamNotifierProvider<FridgesController, FridgesState>(
  FridgesController.new,
  // Offline is handled above, and the connection coming back reloads.
  retry: (_, _) => null,
);

/// The signed-in user's id, or [Fridge.localId] for a guest.
final currentUserIdProvider = Provider<String>(
  (ref) =>
      ref.watch(authControllerProvider.select((a) => a.value?.id)) ??
      Fridge.localId,
);

/// Whether [fridge] can be changed right now: online, or offline when nobody
/// else uses it.
bool canChangeFridge(Fridge fridge, {required bool online}) =>
    online || fridge.isLocal || fridge.isSolo;

/// Whether the backend can be reached, as far as the app knows: there's a
/// network, and the last try to load the fridges worked.
final isOnlineProvider = Provider<bool>(
  (ref) =>
      (ref.watch(networkAvailableProvider).value ?? true) &&
      (ref.watch(fridgesProvider.select((s) => s.value?.reachable)) ?? true),
);
