import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/features/food/data/product_type_cache.dart';
import 'package:app/features/food/domain/product_type.dart';

/// The backend's product catalogue: `/api/product-categories` and
/// `/api/product-types`. Throws [ApiException] on failure.
class ProductCatalogApi {
  ProductCatalogApi(this._dio);

  final Dio _dio;

  /// Every product type with its category's name, sorted by category, then
  /// name.
  Future<List<ProductType>> productTypes() async {
    try {
      final [categories, types] = await Future.wait([
        _dio.get<List<dynamic>>('/api/product-categories'),
        _dio.get<List<dynamic>>('/api/product-types'),
      ]);
      final categoryNames = {
        for (final c in categories.data!.cast<Map<String, dynamic>>())
          c['id'] as String: c['name'] as String,
      };
      return [
        for (final t in types.data!.cast<Map<String, dynamic>>())
          ProductType(
            id: t['id'] as String,
            name: t['name'] as String,
            category: categoryNames[t['categoryId']] ?? '',
            defaultExpiryDays: t['defaultExpiryDays'] as int,
            pantryExpiryDays: t['pantryExpiryDays'] as int?,
            fridgeExpiryDays: t['fridgeExpiryDays'] as int?,
            freezerExpiryDays: t['freezerExpiryDays'] as int?,
          ),
      ]..sort(
        (a, b) => a.category != b.category
            ? a.category.compareTo(b.category)
            : a.name.compareTo(b.name),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final productCatalogApiProvider = Provider<ProductCatalogApi>(
  (ref) => ProductCatalogApi(ref.watch(dioProvider)),
);

/// The catalogue: the copy saved on this device first, then the backend's,
/// which is saved for next time. Loaded on every launch, see `main.dart`.
///
/// Only fails when nothing is saved yet and the backend can't be reached.
final productTypesProvider = StreamProvider<List<ProductType>>((ref) async* {
  final cache = ref.watch(productTypeCacheProvider);
  final api = ref.watch(productCatalogApiProvider);

  final saved = await cache.read();
  if (saved != null) yield saved;

  final List<ProductType> fresh;
  try {
    fresh = await api.productTypes();
  } catch (e) {
    if (saved == null) rethrow;
    debugPrint('Could not refresh the product types: $e');
    return;
  }
  await cache.save(fresh);
  yield fresh;
});
