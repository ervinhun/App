import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/generated/export.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/features/auth/data/guest_mode.dart';
import 'package:app/features/food/data/food_items_controller.dart';
import 'package:app/features/food/data/food_store.dart';
import 'package:app/features/fridges/data/fridges_cache.dart';
import 'package:app/features/fridges/data/fridges_controller.dart';

/// Who is signed in: `null` when signed out, loading while a stored token is
/// checked on startup.
///
/// Offline, a stored session counts as signed in, as the user it was for: the
/// app works offline, and the backend checks the token again on the next
/// request that reaches it.
///
/// Sign-in methods throw [ApiException] (or a Google SDK error) on failure and
/// leave the state unchanged, so screens can show the error themselves.
class AuthController extends AsyncNotifier<UserDto?> {
  TokenStorage get _tokens => ref.read(tokenStorageProvider);
  AuthClient get _api => ref.read(authClientProvider);
  AuthClient get _signIn => ref.read(signInClientProvider);

  /// Sent with every sign-in and stored on the backend's session.
  String get _platform => defaultTargetPlatform.name.toLowerCase();

  @override
  Future<UserDto?> build() async {
    if (await _tokens.read() == null) return null;
    try {
      final user = await apiCall(_api.me());
      await _tokens.writeUser(user);
      return user;
    } on ApiException catch (e) {
      // The session ended, or the account was deleted.
      if (e.isUnauthorized) {
        await _tokens.clear();
        return null;
      }
      if (e.isOffline) {
        if (await _tokens.readUser() case final user?) return user;
      }
      rethrow;
    }
  }

  Future<void> signInWithPassword(String email, String password) async =>
      _start(
        await apiCall(
          _signIn.login(
            body: LoginRequest(
              email: email.trim(),
              password: password,
              platform: _platform,
            ),
          ),
        ),
      );

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async => _start(
    await apiCall(
      _signIn.register(
        body: RegisterRequest(
          email: email.trim(),
          password: password,
          displayName: displayName.trim(),
          platform: _platform,
        ),
      ),
    ),
  );

  /// Returns false if the user closed Google's account picker.
  Future<bool> signInWithGoogle() async {
    final credential = await ref.read(googleAuthProvider).signIn();
    if (credential == null) return false;
    await _start(
      await apiCall(
        _signIn.externalLogin(
          body: ExternalLoginRequest(
            provider: 'google',
            idToken: credential.idToken,
            displayName: credential.displayName,
            platform: _platform,
          ),
        ),
      ),
    );
    return true;
  }

  /// Ends the backend session too, then signs out here even if that failed.
  Future<void> signOut() async {
    if (await _tokens.read() != null) {
      try {
        await apiCall(_api.logout());
      } on ApiException {
        // Offline or already signed out: the local sign-out below still happens.
      }
    }
    await endSession();
  }

  /// Signs out on this device only, for when the backend already ended the
  /// session. Unlike [signOut] it sends no request, so `AuthInterceptor` can
  /// call it while a refresh is in flight.
  Future<void> endSession() async {
    final google = ref.read(googleAuthProvider);
    await _tidyUp();
    await _tokens.clear();
    state = const AsyncData(null);
    // Cancels a startup check still running, whose late result would undo this.
    ref.invalidateSelf();
    await google.signOut();
  }

  /// Keeps the food from the user's own fridge on the phone, for using the
  /// app offline as a guest; it's theirs again when they sign back in. Food
  /// from someone else's fridge, or when it isn't known whose it is, is
  /// forgotten with the fridges, so the next person to use the phone doesn't
  /// see it.
  Future<void> _tidyUp() async {
    final cache = ref.read(fridgesCacheProvider);
    // The fridges as saved on the phone: the fridges controller depends on
    // this one, so it can't be read here.
    final userId = state.value?.id ?? (await _tokens.readUser())?.id;
    final saved = userId == null ? null : await cache.fridges(userId);
    final fridge = saved == null
        ? null
        : FridgesState(
            fridges: saved,
            currentId: await cache.currentId(),
          ).current;
    if (saved != null && (fridge == null || fridge.isOwner)) {
      await keepFridgeForGuest(cache, fridge);
    } else {
      await ref.read(foodStoreProvider).clear();
      await cache.clear();
      ref.invalidate(foodItemsProvider);
    }
  }

  Future<void> _start(AuthResponse session) async {
    await _tokens.write(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await _tokens.writeUser(session.user);
    await ref.read(guestModeProvider.notifier).leave();
    state = AsyncData(session.user);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, UserDto?>(
  AuthController.new,
);
