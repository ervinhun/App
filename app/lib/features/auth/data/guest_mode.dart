import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that the user chose to use the app without an account.
class GuestStorage {
  GuestStorage([SharedPreferencesAsync? prefs]) : _prefs = prefs;

  static const _guestKey = 'guest_mode';

  SharedPreferencesAsync? _prefs;
  SharedPreferencesAsync get _store => _prefs ??= SharedPreferencesAsync();

  /// If preferences can't be read, says no: the login screen is the safe start.
  Future<bool> isGuest() async {
    try {
      return await _store.getBool(_guestKey) ?? false;
    } catch (e) {
      debugPrint('Could not read the guest flag: $e');
      return false;
    }
  }

  Future<void> setGuest(bool guest) async {
    try {
      await _store.setBool(_guestKey, guest);
    } catch (e) {
      debugPrint('Could not save the guest flag: $e');
    }
  }
}

final guestStorageProvider = Provider<GuestStorage>((ref) => GuestStorage());

/// Whether the app is used as a guest: without an account, with the food kept
/// on this device only. Signing in later keeps that food and uploads it; after
/// a sign-out, it's the food of the account that signed out (see
/// `FoodStore.claimFor`).
class GuestModeController extends AsyncNotifier<bool> {
  GuestStorage get _storage => ref.read(guestStorageProvider);

  @override
  Future<bool> build() => _storage.isGuest();

  Future<void> enter() async {
    state = const AsyncData(true);
    await _storage.setGuest(true);
  }

  /// To sign in, or because the user did.
  Future<void> leave() async {
    if (state.value == false) return;
    state = const AsyncData(false);
    await _storage.setGuest(false);
  }
}

final guestModeProvider = AsyncNotifierProvider<GuestModeController, bool>(
  GuestModeController.new,
);
