import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/features/fridges/domain/fridge.dart';

/// The fridges, members, alert settings and activity last loaded from the
/// backend, so management works offline; and the changes made offline to a
/// fridge nobody else uses, until they're uploaded.
///
/// Reads give null when nothing is saved, or what's saved can't be read.
class FridgesCache {
  FridgesCache([SharedPreferencesAsync? prefs]) : _prefs = prefs;

  static const _prefix = 'fridges.';
  static const _currentKey = '${_prefix}current';
  static const _pendingKey = '${_prefix}pending';

  SharedPreferencesAsync? _prefs;
  SharedPreferencesAsync get _store => _prefs ??= SharedPreferencesAsync();

  /// [owner] is the user id, or [Fridge.localId] for a guest: the list is
  /// only ever shown to whoever it was loaded for.
  Future<List<Fridge>?> fridges(String owner) => _read(
    '${_prefix}list.$owner',
    (json) => [
      for (final f in json as List<dynamic>)
        Fridge.fromJson(f as Map<String, dynamic>),
    ],
  );

  Future<void> saveFridges(String owner, List<Fridge> fridges) =>
      _write('${_prefix}list.$owner', [for (final f in fridges) f.toJson()]);

  /// The fridge the user last picked.
  Future<String?> currentId() => _read(_currentKey, (json) => json as String);

  Future<void> saveCurrentId(String id) => _write(_currentKey, id);

  Future<List<FridgeMember>?> members(String fridgeId) => _read(
    '${_prefix}members.$fridgeId',
    (json) => [
      for (final m in json as List<dynamic>)
        FridgeMember.fromJson(m as Map<String, dynamic>),
    ],
  );

  Future<void> saveMembers(String fridgeId, List<FridgeMember> members) =>
      _write('${_prefix}members.$fridgeId', [
        for (final m in members) m.toJson(),
      ]);

  Future<AlertSettings?> alerts(String fridgeId) => _read(
    '${_prefix}alerts.$fridgeId',
    (json) => AlertSettings.fromJson(json as Map<String, dynamic>),
  );

  Future<void> saveAlerts(String fridgeId, AlertSettings settings) =>
      _write('${_prefix}alerts.$fridgeId', settings.toJson());

  Future<List<ActivityEntry>?> activity(String fridgeId) => _read(
    '${_prefix}activity.$fridgeId',
    (json) => [
      for (final e in json as List<dynamic>)
        ActivityEntry.fromJson(e as Map<String, dynamic>),
    ],
  );

  Future<void> saveActivity(String fridgeId, List<ActivityEntry> entries) =>
      _write('${_prefix}activity.$fridgeId', [
        for (final e in entries) e.toJson(),
      ]);

  /// Changes made offline, by fridge id.
  Future<Map<String, PendingFridgeChange>> pending() async =>
      await _read(
        _pendingKey,
        (json) => {
          for (final MapEntry(:key, :value)
              in (json as Map<String, dynamic>).entries)
            key: PendingFridgeChange.fromJson(value as Map<String, dynamic>),
        },
      ) ??
      {};

  Future<void> savePending(Map<String, PendingFridgeChange> pending) =>
      _write(_pendingKey, {
        for (final MapEntry(:key, :value) in pending.entries)
          if (!value.isEmpty) key: value.toJson(),
      });

  /// Forgets everything, so the next person to use the phone doesn't see it.
  Future<void> clear() async {
    try {
      final keys = await _store.getKeys();
      for (final key in keys.where((k) => k.startsWith(_prefix))) {
        await _store.remove(key);
      }
    } catch (e) {
      debugPrint('Could not clear the saved fridges: $e');
    }
  }

  Future<T?> _read<T>(String key, T Function(Object? json) parse) async {
    try {
      final json = await _store.getString(key);
      return json == null ? null : parse(jsonDecode(json));
    } catch (e) {
      debugPrint('Could not read $key: $e');
      return null;
    }
  }

  Future<void> _write(String key, Object? value) async {
    try {
      await _store.setString(key, jsonEncode(value));
    } catch (e) {
      debugPrint('Could not save $key: $e');
    }
  }
}

final fridgesCacheProvider = Provider<FridgesCache>((ref) => FridgesCache());

/// Forgets everything in [cache] but [fridge]'s name and alert settings,
/// which become the guest's fridge's, for when the user signs out and the
/// food stays on the phone. Alerts go to the guest alone, as nobody else is
/// left. Changes not uploaded yet are kept too, for the user's next sign-in.
Future<void> keepFridgeForGuest(FridgesCache cache, Fridge? fridge) async {
  final pending = await cache.pending();
  final alerts = fridge == null
      ? null
      : pending[fridge.id]?.alerts ?? await cache.alerts(fridge.id);
  await cache.clear();
  await cache.savePending(pending);
  if (fridge == null) return;
  await cache.saveFridges(Fridge.localId, [
    Fridge.local.copyWith(name: fridge.name),
  ]);
  if (alerts != null) {
    await cache.saveAlerts(
      Fridge.localId,
      alerts.copyWith(
        scope: RecipientsScope.allMembers,
        recipientUserIds: const {},
      ),
    );
  }
}

/// What was changed offline in a fridge only the user uses. Only the latest
/// of each matters.
@immutable
class PendingFridgeChange {
  const PendingFridgeChange({this.name, this.alerts});

  final String? name;
  final AlertSettings? alerts;

  bool get isEmpty => name == null && alerts == null;

  PendingFridgeChange withName(String? name) =>
      PendingFridgeChange(name: name, alerts: alerts);

  PendingFridgeChange withAlerts(AlertSettings? alerts) =>
      PendingFridgeChange(name: name, alerts: alerts);

  factory PendingFridgeChange.fromJson(Map<String, dynamic> json) =>
      PendingFridgeChange(
        name: json['name'] as String?,
        alerts: switch (json['alerts']) {
          final Map<String, dynamic> alerts => AlertSettings.fromJson(alerts),
          _ => null,
        },
      );

  Map<String, dynamic> toJson() => {'name': name, 'alerts': alerts?.toJson()};
}
