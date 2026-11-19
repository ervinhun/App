import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/features/food/data/product_catalog_api.dart';
import 'package:app/features/food/domain/expiry_defaults.dart';
import 'package:app/features/food/domain/product_type.dart';

/// Keeps the user's [ExpiryDefaults] on the phone.
class ExpiryDefaultsStorage {
  ExpiryDefaultsStorage([SharedPreferencesAsync? prefs]) : _prefs = prefs;

  static const _key = 'expiry_defaults';

  SharedPreferencesAsync? _prefs;
  SharedPreferencesAsync get _store => _prefs ??= SharedPreferencesAsync();

  /// [ExpiryDefaults.none] when nothing is saved, or it can't be read.
  Future<ExpiryDefaults> read() async {
    try {
      final json = await _store.getString(_key);
      if (json == null) return ExpiryDefaults.none;
      return ExpiryDefaults.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Could not read the expiry defaults: $e');
      return ExpiryDefaults.none;
    }
  }

  Future<void> save(ExpiryDefaults defaults) async {
    try {
      await _store.setString(_key, jsonEncode(defaults.toJson()));
    } catch (e) {
      debugPrint('Could not save the expiry defaults: $e');
    }
  }
}

final expiryDefaultsStorageProvider = Provider<ExpiryDefaultsStorage>(
  (ref) => ExpiryDefaultsStorage(),
);

class ExpiryDefaultsController extends AsyncNotifier<ExpiryDefaults> {
  ExpiryDefaultsStorage get _storage => ref.read(expiryDefaultsStorageProvider);

  @override
  Future<ExpiryDefaults> build() => _storage.read();

  Future<void> change(ExpiryDefaults defaults) async {
    state = AsyncData(defaults);
    await _storage.save(defaults);
  }
}

final expiryDefaultsProvider =
    AsyncNotifierProvider<ExpiryDefaultsController, ExpiryDefaults>(
      ExpiryDefaultsController.new,
    );

/// The catalogue's product types, with the user's [ExpiryDefaults] applied.
final adjustedProductTypesProvider = Provider<AsyncValue<List<ProductType>>>((
  ref,
) {
  final defaults = ref.watch(expiryDefaultsProvider).value;
  final types = ref.watch(productTypesProvider);
  if (defaults == null) return types;
  return types.whenData((all) => [for (final t in all) defaults.applyTo(t)]);
});
