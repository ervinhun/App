import 'package:app/core/api/api_client.dart';
import 'package:app/features/food/data/product_catalog_api.dart';
import 'package:app/features/food/data/product_type_cache.dart';
import 'package:app/features/food/domain/product_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const milk = ProductType(
  id: 'milk',
  name: 'Milk',
  category: 'Dairy & Eggs',
  defaultExpiryDays: 7,
  fridgeExpiryDays: 7,
  freezerExpiryDays: 90,
);
const eggs = ProductType(
  id: 'eggs',
  name: 'Eggs (in shell)',
  category: 'Dairy & Eggs',
  defaultExpiryDays: 35,
);

class FakeProductTypeCache implements ProductTypeCache {
  FakeProductTypeCache([this.types]);

  List<ProductType>? types;

  @override
  Future<List<ProductType>?> read() async => types;

  @override
  Future<void> save(List<ProductType> types) async => this.types = types;
}

class FakeProductCatalogApi implements ProductCatalogApi {
  FakeProductCatalogApi([this.types]);

  /// Null when the backend can't be reached.
  List<ProductType>? types;

  @override
  Future<List<ProductType>> productTypes() async =>
      types ?? (throw ApiException("Can't reach the server."));
}

void main() {
  late FakeProductTypeCache cache;
  late FakeProductCatalogApi api;

  /// Every value the provider goes through until it settles.
  Future<List<AsyncValue<List<ProductType>>>> load() async {
    final c = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        productTypeCacheProvider.overrideWithValue(cache),
        productCatalogApiProvider.overrideWithValue(api),
      ],
    );
    final values = <AsyncValue<List<ProductType>>>[];
    c.listen(productTypesProvider, (_, next) => values.add(next));
    await Future<void>.delayed(Duration.zero);
    return values;
  }

  test(
    'first launch: loads the types from the backend and saves them',
    () async {
      cache = FakeProductTypeCache();
      api = FakeProductCatalogApi([milk]);

      final values = await load();

      expect(values.last.value, [milk]);
      expect(cache.types, [milk]);
    },
  );

  test('later launches: shows the saved types, then the backend\'s', () async {
    cache = FakeProductTypeCache([milk]);
    api = FakeProductCatalogApi([milk, eggs]);

    final values = await load();

    expect(
      [
        for (final v in values.whereType<AsyncData<List<ProductType>>>())
          v.value,
      ],
      [
        [milk],
        [milk, eggs],
      ],
    );
    expect(cache.types, [milk, eggs]);
  });

  test('backend unreachable: keeps showing the saved types', () async {
    cache = FakeProductTypeCache([milk]);
    api = FakeProductCatalogApi();

    final values = await load();

    expect(values.last, isA<AsyncData<List<ProductType>>>());
    expect(values.last.value, [milk]);
    expect(cache.types, [milk]);
  });

  test('backend unreachable and nothing saved: fails', () async {
    cache = FakeProductTypeCache();
    api = FakeProductCatalogApi();

    final values = await load();

    expect(values.last, isA<AsyncError<List<ProductType>>>());
  });

  test('a type survives being saved and read back', () {
    expect(ProductType.fromJson(milk.toJson()).toJson(), milk.toJson());
    expect(ProductType.fromJson(eggs.toJson()).toJson(), eggs.toJson());
  });
}
