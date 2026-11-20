import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/fridges/domain/fridge_space.dart';

/// The backend's `/api/fridges`, with each fridge's containers and expiry
/// notification settings. Throws [ApiException] on failure.
class FridgesApi {
  FridgesApi(this._dio);

  final Dio _dio;

  Future<List<FridgeSpace>> mine() => _call(() async {
    final fridges = await _dio.get<List<dynamic>>('/api/fridges');
    return Future.wait(fridges.data!.map((f) => _withContainers(f as Map)));
  });

  /// The backend creates a fridge empty, so its containers are added after.
  Future<FridgeSpace> create(String name, List<StorageLocation> storages) =>
      _call(() async {
        final fridge = (await _dio.post<Map>(
          '/api/fridges',
          data: {'name': name},
        )).data!;
        for (final s in storages) {
          await _dio.post<void>(
            '/api/fridges/${fridge['id']}/containers',
            data: {'name': s.label, 'type': s.name},
          );
        }
        return _withContainers(fridge);
      });

  Future<FridgeSpace> join(String inviteCode) => _call(() async {
    final fridge = await _dio.post<Map>(
      '/api/fridges/Join',
      data: {'inviteCode': inviteCode},
    );
    return _withContainers(fridge.data!);
  });

  /// Owner only. The old code stops working; members stay.
  Future<FridgeSpace> newInviteCode(String fridgeId) => _call(() async {
    final fridge = await _dio.post<Map>(
      '/api/fridges/$fridgeId/RegenerateInviteCode',
    );
    return _withContainers(fridge.data!);
  });

  Future<ExpiryThresholds> expiryThresholds(String fridgeId) => _call(() async {
    final settings = (await _dio.get<Map>(
      '/api/fridges/$fridgeId/notification-settings',
    )).data!;
    return (
      dangerDays: settings['dangerDaysBefore'] as int,
      warningDays: settings['warningDaysBefore'] as int,
    );
  });

  Future<FridgeSpace> _withContainers(Map fridge) async {
    final containers = await _dio.get<List<dynamic>>(
      '/api/fridges/${fridge['id']}/containers',
    );
    final types = StorageLocation.values.asNameMap();
    return FridgeSpace(
      id: fridge['id'] as String,
      name: fridge['name'] as String,
      inviteCode: fridge['inviteCode'] as String?,
      isOwner: fridge['isOwner'] as bool,
      canPut: fridge['canPut'] as bool,
      createdAt: DateTime.parse(fridge['createdAt'] as String),
      containers: [
        for (final c in containers.data!.cast<Map>())
          if (types[c['type']] case final type?) (type, c['name'] as String),
      ],
    );
  }

  static Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final fridgesApiProvider = Provider<FridgesApi>(
  (ref) => FridgesApi(ref.watch(dioProvider)),
);
