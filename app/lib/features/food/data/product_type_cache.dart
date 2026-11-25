import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/features/food/domain/product_type.dart';

/// The product types last loaded from the backend, so the type picker works
/// offline and while the backend doesn't answer.
class ProductTypeCache {
  ProductTypeCache([SharedPreferencesAsync? prefs]) : _prefs = prefs;

  static const _typesKey = 'product_types';

  SharedPreferencesAsync? _prefs;
  SharedPreferencesAsync get _store => _prefs ??= SharedPreferencesAsync();

  /// Null when nothing is saved yet, or what's saved can't be read.
  Future<List<ProductType>?> read() async {
    try {
      final json = await _store.getString(_typesKey);
      if (json == null) return null;
      return [
        for (final type in (jsonDecode(json) as List<dynamic>))
          ProductType.fromJson(type as Map<String, dynamic>),
      ];
    } catch (e) {
      debugPrint('Could not read the saved product types: $e');
      return null;
    }
  }

  Future<void> save(List<ProductType> types) async {
    try {
      await _store.setString(
        _typesKey,
        jsonEncode([for (final type in types) type.toJson()]),
      );
    } catch (e) {
      debugPrint('Could not save the product types: $e');
    }
  }
}

final productTypeCacheProvider = Provider<ProductTypeCache>(
  (ref) => ProductTypeCache(),
);
