import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/sync/connectivity.dart';
import 'package:app/features/fridges/data/fridges_api.dart';
import 'package:app/features/fridges/data/fridges_cache.dart';
import 'package:app/features/fridges/data/fridges_controller.dart';
import 'package:app/features/fridges/domain/fridge.dart';

/// Loads what's saved on the phone for one fridge first, then the backend's
/// copy, which is saved for next time; and again when the connection comes
/// back. A guest's fridge ([Fridge.localId]) only has the phone's copy.
///
/// Only fails when nothing is saved and the backend can't be reached.
abstract class _FridgeDetail<T> extends StreamNotifier<T> {
  _FridgeDetail(this.fridgeId);

  final String fridgeId;

  FridgesApi get api => ref.read(fridgesApiProvider);
  FridgesCache get cache => ref.read(fridgesCacheProvider);

  /// What a guest's fridge has.
  T get local;

  Future<T?> readSaved();
  Future<void> save(T value);
  Future<T> fetch();

  /// When true, the saved copy is shown and the backend's isn't loaded: it
  /// has changes the backend hasn't got yet.
  Future<bool> keepSaved() async => false;

  @override
  Stream<T> build() async* {
    ref.listen(networkAvailableProvider, (previous, next) {
      if (next.value == true && previous?.value == false) ref.invalidateSelf();
    });
    final saved = await readSaved();
    if (fridgeId == Fridge.localId) {
      yield saved ?? local;
      return;
    }
    if (saved != null) yield saved;
    if (saved != null && await keepSaved()) return;
    try {
      final fresh = await fetch();
      await save(fresh);
      yield fresh;
    } on ApiException catch (e) {
      if (saved == null) rethrow;
      debugPrint('Could not refresh $runtimeType: $e');
    }
  }

  /// Shows and saves [value].
  Future<void> set(T value) async {
    if (ref.mounted) state = AsyncData(value);
    await save(value);
  }
}

/// The people in a fridge.
class FridgeMembersController extends _FridgeDetail<List<FridgeMember>> {
  FridgeMembersController(super.fridgeId);

  @override
  List<FridgeMember> get local => const [
    FridgeMember(
      userId: Fridge.localId,
      displayName: 'You',
      isOwner: true,
      canPut: true,
      canUse: true,
    ),
  ];

  @override
  Future<List<FridgeMember>?> readSaved() => cache.members(fridgeId);

  @override
  Future<void> save(List<FridgeMember> value) =>
      cache.saveMembers(fridgeId, value);

  @override
  Future<List<FridgeMember>> fetch() => api.members(fridgeId);

  List<FridgeMember> get _members => state.value ?? const [];

  /// Changes what [member] may do, which only the owner can.
  Future<void> updateRights(
    FridgeMember member, {
    required bool canPut,
    required bool canUse,
    required DateTime? accessExpiresAt,
  }) async {
    final updated = await api.updateMember(
      fridgeId,
      member.userId,
      canPut: canPut,
      canUse: canUse,
      accessExpiresAt: accessExpiresAt,
    );
    await set([
      for (final m in _members) m.userId == updated.userId ? updated : m,
    ]);
  }

  /// Removes [member] from the fridge, which only the owner can.
  Future<void> remove(FridgeMember member) async {
    await api.removeMember(fridgeId, member.userId);
    await set([
      for (final m in _members)
        if (m.userId != member.userId) m,
    ]);
    // Its member count changed.
    ref.read(fridgesProvider.notifier).reload();
  }
}

final fridgeMembersProvider =
    StreamNotifierProvider.family<
      FridgeMembersController,
      List<FridgeMember>,
      String
    >(FridgeMembersController.new, retry: (_, _) => null);

/// When a fridge's expiry alerts go out, and to whom.
class AlertSettingsController extends _FridgeDetail<AlertSettings> {
  AlertSettingsController(super.fridgeId);

  @override
  AlertSettings get local => const AlertSettings();

  Future<AlertSettings?> _pending() async =>
      (await cache.pending())[fridgeId]?.alerts;

  @override
  Future<AlertSettings?> readSaved() async =>
      await _pending() ?? await cache.alerts(fridgeId);

  @override
  Future<bool> keepSaved() async => await _pending() != null;

  @override
  Future<void> save(AlertSettings value) => cache.saveAlerts(fridgeId, value);

  @override
  Future<AlertSettings> fetch() => api.alertSettings(fridgeId);

  /// Saves [settings], which only the owner can. Offline, that only works in
  /// a fridge nobody else uses: see [FridgesController.saveOrQueue].
  Future<SaveOutcome> change(Fridge fridge, AlertSettings settings) async {
    final outcome = await ref
        .read(fridgesProvider.notifier)
        .saveOrQueue(
          fridge,
          upload: () async =>
              set(await api.saveAlertSettings(fridgeId, settings)),
          queue: (pending) => pending.withAlerts(settings),
        );
    if (outcome == SaveOutcome.queued) await set(settings);
    return outcome;
  }
}

final alertSettingsProvider =
    StreamNotifierProvider.family<
      AlertSettingsController,
      AlertSettings,
      String
    >(AlertSettingsController.new, retry: (_, _) => null);

/// What was added to a fridge, newest first, and what's gone since.
class ActivityLogController extends _FridgeDetail<List<ActivityEntry>> {
  ActivityLogController(super.fridgeId);

  @override
  List<ActivityEntry> get local => const [];

  @override
  Future<List<ActivityEntry>?> readSaved() => cache.activity(fridgeId);

  @override
  Future<void> save(List<ActivityEntry> value) =>
      cache.saveActivity(fridgeId, value);

  @override
  Future<List<ActivityEntry>> fetch() => api.activity(fridgeId);
}

final activityLogProvider =
    StreamNotifierProvider.family<
      ActivityLogController,
      List<ActivityEntry>,
      String
    >(ActivityLogController.new, retry: (_, _) => null);
