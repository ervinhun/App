import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/api/api_client.dart';
import 'package:app/features/food/data/items_remote.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/food/domain/product_type.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'food_store_test.dart' show food;

/// Answers each "METHOD /path" with what's in [answers], and 404 otherwise.
class _FakeBackend implements HttpClientAdapter {
  final answers = <String, Object?>{};
  final sent = <String, Object?>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final call = '${options.method} ${options.path}';
    sent[call] = options.data;
    final answer = answers[call];
    return ResponseBody.fromString(
      jsonEncode(answer is int ? null : answer),
      answer is int
          ? answer
          : answer == null
          ? 404
          : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _fridge(
  String id, {
  bool isOwner = false,
  bool canPut = true,
  int day = 1,
}) => {
  'id': id,
  'isOwner': isOwner,
  'canPut': canPut,
  'createdAt': DateTime.utc(2026, 1, day).toIso8601String(),
};

void main() {
  late _FakeBackend backend;
  late BackendItemsRemote remote;

  const milk = ProductType(
    id: 'type-milk',
    name: 'Milk (plain or flavored)',
    category: 'Dairy & Eggs',
    defaultExpiryDays: 7,
  );
  const item = {
    'id': 'a',
    'containerId': 'c-freezer',
    'productTypeId': 'type-milk',
    'name': 'Milk',
    'amount': '1 l',
    'addedAt': '2026-11-15',
    'expiryDate': '2026-11-20',
  };

  setUp(() {
    backend = _FakeBackend()
      ..answers.addAll({
        'GET /api/fridges': [_fridge('f', isOwner: true)],
        'GET /api/fridges/f/containers': [
          {'id': 'c-fridge', 'type': 'fridge'},
          {'id': 'c-freezer', 'type': 'freezer'},
        ],
        'PUT /api/fridges/f/items/a/sync': item,
      });
    final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = backend;
    remote = BackendItemsRemote(dio, () async => [milk]);
  });

  Map<String, dynamic> saved() =>
      backend.sent['PUT /api/fridges/f/items/a/sync']! as Map<String, dynamic>;

  test('saves an item with dates only, and when it was changed', () async {
    await remote.open();

    await remote.save(food('a'), changedAt: DateTime.utc(2026, 11, 15, 10));

    expect(saved(), {
      'storage': 'fridge',
      'name': 'Milk',
      'productTypeId': 'type-milk',
      'amount': '1 l',
      'expiryDate': '2026-11-20',
      'bestBefore': null,
      'openedOn': null,
      'changedAt': '2026-11-15T10:00:00.000Z',
    });
  });

  test('an opened item expires earlier and keeps its printed date', () async {
    await remote.open();

    await remote.save(
      food('a').opened(DateTime(2026, 11, 15)),
      changedAt: DateTime.utc(2026, 11, 15),
    );

    expect(saved()['openedOn'], '2026-11-15');
    expect(saved()['expiryDate'], '2026-11-19');
    expect(saved()['bestBefore'], '2026-11-20');
  });

  test('text the backend would refuse is cut to fit', () async {
    await remote.open();

    await remote.save(
      food('a', name: 'x' * 300),
      changedAt: DateTime.utc(2026, 11, 15),
    );

    expect(saved()['name'], hasLength(200));
  });

  test("reads the backend's items", () async {
    backend.answers['GET /api/fridges/f/items'] = [
      item,
      {
        ...item,
        'id': 'b',
        'productTypeId': null,
        'amount': '500',
        'unit': 'g',
        'openedOn': '2026-11-16',
        'bestBefore': '2026-12-01',
      },
    ];
    await remote.open();

    final [a, b] = await remote.fetchAll();

    expect(a.storage, StorageLocation.freezer);
    expect(
      (a.productCategory, a.productType, a.category),
      ('Dairy & Eggs', 'Milk (plain or flavored)', FoodCategory.dairy),
    );
    expect((a.bestBefore, a.isOpened), (DateTime(2026, 11, 20), false));
    expect(b.amount, '500 g');
    expect(b.category, FoodCategory.other);
    expect(b.bestBefore, DateTime(2026, 12));
    expect(b.openedOn, DateTime(2026, 11, 16));
    expect(b.expiresOn, DateTime(2026, 11, 20));
  });

  test('a type the backend lost stays as it was on the phone', () async {
    backend.answers['PUT /api/fridges/f/items/a/sync'] = {
      ...item,
      'productTypeId': null,
    };
    await remote.open();

    final answer = await remote.save(
      food('a'),
      changedAt: DateTime.utc(2026, 11, 15),
    );

    expect(answer.productType, 'Milk (plain or flavored)');
    expect(answer.category, FoodCategory.dairy);
  });

  group('the fridge', () {
    Future<String> chosen(List<Object> fridges) async {
      backend.answers['GET /api/fridges'] = fridges;
      for (final id in ['a', 'b', 'c', 'new']) {
        backend.answers['GET /api/fridges/$id/containers'] = <Object>[];
        backend.answers['GET /api/fridges/$id/items'] = <Object>[];
      }
      await remote.open();
      backend.sent.clear();
      await remote.fetchAll();
      return backend.sent.keys.single.split('/')[3];
    }

    test("is the user's oldest own", () async {
      expect(
        await chosen([
          _fridge('a'),
          _fridge('b', isOwner: true, day: 5),
          _fridge('c', isOwner: true, day: 3),
        ]),
        'c',
      );
    });

    test('is else one they may add food to', () async {
      expect(
        await chosen([_fridge('a', canPut: false), _fridge('b', day: 5)]),
        'b',
      );
    });

    test('is made if they have none', () async {
      backend.answers['POST /api/fridges'] = _fridge('new', isOwner: true);

      expect(await chosen([]), 'new');
    });
  });

  group('removing an item', () {
    const call = 'PUT /api/fridges/f/items/a/status';

    test('marks it removed', () async {
      backend.answers[call] = item;
      await remote.open();

      await remote.delete('a', changedAt: DateTime.utc(2026, 11, 15));

      expect(backend.sent[call], {'status': 'removed'});
    });

    test("succeeds if it's already gone", () async {
      await remote.open();

      await remote.delete('a', changedAt: DateTime.utc(2026, 11, 15));
    });

    test('is refused without the right to', () async {
      backend.answers[call] = 403;
      await remote.open();

      await expectLater(
        remote.delete('a', changedAt: DateTime.utc(2026, 11, 15)),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });
}
