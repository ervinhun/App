import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which one-time tips the user has already seen.
class HintStorage {
  HintStorage([SharedPreferencesAsync? prefs]) : _prefs = prefs;

  static const _swipeHintKey = 'swipe_hint_done';

  SharedPreferencesAsync? _prefs;
  SharedPreferencesAsync get _store => _prefs ??= SharedPreferencesAsync();

  /// Whether the user has swiped a food card, or closed the tip about it.
  ///
  /// If preferences can't be read, says yes: better to skip a tip than to
  /// show it on every launch.
  Future<bool> swipeHintDone() async {
    try {
      return await _store.getBool(_swipeHintKey) ?? false;
    } catch (e) {
      debugPrint('Could not read the swipe hint flag: $e');
      return true;
    }
  }

  Future<void> markSwipeHintDone() async {
    try {
      await _store.setBool(_swipeHintKey, true);
    } catch (e) {
      debugPrint('Could not save the swipe hint flag: $e');
    }
  }
}

final hintStorageProvider = Provider<HintStorage>((ref) => HintStorage());
