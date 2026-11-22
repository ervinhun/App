import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/features/notifications/domain/expiry_digest.dart';
import 'package:app/features/notifications/domain/fridge_reminders.dart';

/// A scheduled reminder, to report to the backend once it has been delivered.
class PendingDispatch {
  const PendingDispatch({
    required this.fridgeId,
    required this.at,
    required this.warningIds,
    required this.dangerIds,
  });

  factory PendingDispatch.of(ExpiryDigest d) => PendingDispatch(
    fridgeId: d.fridgeId,
    at: d.at,
    warningIds: d.warningIds,
    dangerIds: d.dangerIds,
  );

  factory PendingDispatch.fromJson(Map<String, dynamic> json) =>
      PendingDispatch(
        fridgeId: json['fridgeId'] as String,
        at: DateTime.parse(json['at'] as String),
        warningIds: List<String>.from(json['warningIds'] as List),
        dangerIds: List<String>.from(json['dangerIds'] as List),
      );

  final String fridgeId;
  final DateTime at;
  final List<String> warningIds;
  final List<String> dangerIds;

  Map<String, dynamic> toJson() => {
    'fridgeId': fridgeId,
    'at': at.toIso8601String(),
    'warningIds': warningIds,
    'dangerIds': dangerIds,
  };
}

/// The reminders' data as last seen on this device, for offline and background use.
class RemindersStorage {
  RemindersStorage([SharedPreferencesAsync? prefs]) : _prefs = prefs;

  static const _remindersKey = 'notification_fridge_reminders';
  static const _notifiedKey = 'notification_notified_stages';
  static const _pendingKey = 'notification_pending_dispatches';

  SharedPreferencesAsync? _prefs;
  SharedPreferencesAsync get _store => _prefs ??= SharedPreferencesAsync();

  /// Null until reminders have been saved once.
  Future<List<FridgeReminders>?> readReminders() =>
      _read(_remindersKey, FridgeReminders.fromJson);

  Future<void> saveReminders(List<FridgeReminders> reminders) =>
      _write(_remindersKey, [for (final r in reminders) r.toJson()]);

  Future<List<PendingDispatch>> readPending() async =>
      await _read(_pendingKey, PendingDispatch.fromJson) ?? [];

  Future<void> savePending(List<PendingDispatch> pending) =>
      _write(_pendingKey, [for (final p in pending) p.toJson()]);

  /// The item stages already reported, as [notifiedKey]s.
  Future<Set<String>> readNotified() async {
    try {
      return (await _store.getStringList(_notifiedKey))?.toSet() ?? {};
    } catch (e) {
      debugPrint('Could not read $_notifiedKey: $e');
      return {};
    }
  }

  Future<void> saveNotified(Set<String> notified) async {
    try {
      await _store.setStringList(_notifiedKey, notified.toList());
    } catch (e) {
      debugPrint('Could not save $_notifiedKey: $e');
    }
  }

  Future<List<T>?> _read<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final saved = await _store.getString(key);
      if (saved == null) return null;
      return [
        for (final e in jsonDecode(saved) as List)
          fromJson(e as Map<String, dynamic>),
      ];
    } catch (e) {
      debugPrint('Could not read $key: $e');
      return null;
    }
  }

  Future<void> _write(String key, List<Map<String, dynamic>> value) async {
    try {
      await _store.setString(key, jsonEncode(value));
    } catch (e) {
      debugPrint('Could not save $key: $e');
    }
  }
}

final remindersStorageProvider = Provider<RemindersStorage>(
  (ref) => RemindersStorage(),
);
