import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/features/food/data/product_catalog_api.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/food/domain/product_type.dart';

/// The backend's copy of the current fridge's food (US-30).
///
/// Failures throw `ApiException`: no status code means the backend couldn't
/// be reached. The backend applies these rules for changes made offline:
///
/// * Each item is decided on its own: the change with the later `changedAt`
///   wins, so an older offline edit doesn't undo a newer one.
/// * Removal wins over a change: saving an item someone removed fails with
///   `410 Gone`, and doesn't bring it back.
/// * A member without the right to add or use food gets `403`.
/// * Once the user's access to the fridge has ended, it's `404`: the next
///   [open] picks another.
abstract interface class ItemsRemote {
  /// Finds the current fridge, and what the other calls need. Called before
  /// each sync: a failure says nothing about the food still to send.
  Future<void> open();

  /// Creates the item with its id, or updates it. Returns the item as the
  /// backend now has it: someone else's version when theirs is newer.
  Future<FoodItem> save(FoodItem item, {required DateTime changedAt});

  /// Removes the item. Removing one that is already gone succeeds.
  Future<void> delete(String id, {required DateTime changedAt});

  Future<List<FoodItem>> fetchAll();
}

/// [ItemsRemote] on the backend's `/api/fridges/{id}/items`.
///
/// Not the generated client: it sends dates with a time, which the backend
/// refuses.
class BackendItemsRemote implements ItemsRemote {
  BackendItemsRemote(this._dio, this._productTypes);

  final Dio _dio;
  final Future<List<ProductType>> Function() _productTypes;

  var _fridge = '';
  var _types = <ProductType>[];

  /// Where each of the fridge's containers is.
  var _storages = <String, StorageLocation>{};

  // The backend's limits.
  static const _maxName = 200;
  static const _maxAmount = 50;

  String get _items => '/api/fridges/$_fridge/items';

  @override
  Future<void> open() async {
    _fridge = await _currentFridge();
    _types = await _productTypes();
    await _loadStorages();
  }

  /// The user's oldest own fridge, else the oldest they may add food to, else
  /// any they can see. Made when they have none, as there's no screen for
  /// that yet.
  Future<String> _currentFridge() async {
    final response = await apiCall(_dio.get<List<dynamic>>('/api/fridges'));
    final fridges = response.data!.cast<Map<String, dynamic>>().toList();
    if (fridges.isEmpty) {
      final made = await apiCall(
        _dio.post<Map<String, dynamic>>('/api/fridges', data: {'name': 'Home'}),
      );
      return made.data!['id'] as String;
    }
    int rank(Map<String, dynamic> fridge) => switch (fridge) {
      {'isOwner': true} => 0,
      {'canPut': true} => 1,
      _ => 2,
    };
    DateTime madeAt(Map<String, dynamic> fridge) =>
        DateTime.parse(fridge['createdAt'] as String);
    fridges.sort(
      (a, b) => rank(a) != rank(b)
          ? rank(a).compareTo(rank(b))
          : madeAt(a).compareTo(madeAt(b)),
    );
    return fridges.first['id'] as String;
  }

  Future<void> _loadStorages() async {
    final response = await apiCall(
      _dio.get<List<dynamic>>('/api/fridges/$_fridge/containers'),
    );
    _storages = {
      for (final c in response.data!.cast<Map<String, dynamic>>())
        c['id'] as String: StorageLocation.values.byName(c['type'] as String),
    };
  }

  @override
  Future<FoodItem> save(FoodItem item, {required DateTime changedAt}) async {
    final response = await apiCall(
      _dio.put<Map<String, dynamic>>(
        '$_items/${item.id}/sync',
        data: {
          'storage': item.storage.name,
          'name': _clip(item.name, _maxName),
          'productTypeId': _typeOf(item)?.id,
          'amount': _clip(item.amount, _maxAmount),
          'expiryDate': _day(item.expiresOn),
          'bestBefore': item.isOpened ? _day(item.bestBefore) : null,
          'openedOn': switch (item.openedOn) {
            final day? => _day(day),
            null => null,
          },
          'changedAt': changedAt.toUtc().toIso8601String(),
        },
      ),
    );
    final saved = response.data!;
    // The backend made a container for it.
    if (!_storages.containsKey(saved['containerId'])) await _loadStorages();
    return _toItem(saved, sent: item);
  }

  @override
  Future<void> delete(String id, {required DateTime changedAt}) async {
    try {
      // Not a DELETE: those who may use the food but not add any can do this.
      await apiCall(
        _dio.put<void>('$_items/$id/status', data: {'status': 'removed'}),
      );
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
    }
  }

  @override
  Future<List<FoodItem>> fetchAll() async {
    final response = await apiCall(_dio.get<List<dynamic>>(_items));
    final items = response.data!.cast<Map<String, dynamic>>();
    if (items.any((item) => !_storages.containsKey(item['containerId']))) {
      await _loadStorages();
    }
    return [for (final item in items) _toItem(item)];
  }

  /// What the backend doesn't know, or the app doesn't yet, such as a new
  /// product type, stays as [sent].
  FoodItem _toItem(Map<String, dynamic> json, {FoodItem? sent}) {
    final type = _types
        .where((type) => type.id == json['productTypeId'])
        .firstOrNull;
    final expiresOn = DateTime.parse(json['expiryDate'] as String);
    final openedOn = _date(json['openedOn']);
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: [
        for (final part in [json['amount'], json['unit']])
          if (part != null) part as String,
      ].join(' '),
      category: type?.group ?? sent?.category ?? FoodCategory.other,
      productCategory: type?.category ?? sent?.productCategory ?? '',
      productType: type?.name ?? sent?.productType ?? '',
      storage:
          _storages[json['containerId']] ??
          sent?.storage ??
          StorageLocation.fridge,
      bestBefore: openedOn == null
          ? expiresOn
          : _date(json['bestBefore']) ?? expiresOn,
      addedOn: _date(json['addedAt']),
      openedOn: openedOn,
      openedExpiresOn: openedOn == null ? null : expiresOn,
    );
  }

  ProductType? _typeOf(FoodItem item) => _types
      .where(
        (type) =>
            type.name == item.productType &&
            type.category == item.productCategory,
      )
      .firstOrNull;

  static DateTime? _date(Object? day) =>
      day == null ? null : DateTime.parse(day as String);

  static String _day(DateTime date) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).toIso8601String().substring(0, 10);

  static String _clip(String text, int max) =>
      text.length <= max ? text : text.substring(0, max);
}

final itemsRemoteProvider = Provider<ItemsRemote?>(
  (ref) => BackendItemsRemote(ref.watch(dioProvider), () async {
    // Listening, as the types aren't loaded while nothing does; through the
    // container, as this provider is only ever read.
    final types = ref.container.listen(productTypesProvider.future, (_, _) {});
    try {
      return await types.read();
    } finally {
      types.close();
    }
  }),
);
