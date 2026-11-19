import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/generated/export.dart';
import 'package:app/features/fridges/domain/fridge.dart';

/// The backend's fridges, their members, notification settings and items.
/// Throws [ApiException] on failure.
///
/// Fridges and members go through the generated [FridgesClient]; the
/// notification settings and items endpoints aren't in it yet, so those use
/// Dio directly, like `ProductCatalogApi`.
class FridgesApi {
  FridgesApi(this._dio) : _client = FridgesClient(_dio);

  final Dio _dio;
  final FridgesClient _client;

  Future<List<Fridge>> mine() async => [
    for (final f in await apiCall(_client.getMine()))
      Fridge.fromJson(f.toJson()),
  ];

  Future<Fridge> create(String name) async => Fridge.fromJson(
    (await apiCall(_client.create(body: SaveFridgeRequest(name: name))))
        .toJson(),
  );

  Future<Fridge> join(String inviteCode) async => Fridge.fromJson(
    (await apiCall(
      _client.join(body: JoinFridgeRequest(inviteCode: inviteCode)),
    )).toJson(),
  );

  Future<Fridge> rename(String id, String name) async => Fridge.fromJson(
    (await apiCall(
      _client.update(
        id: id,
        body: SaveFridgeRequest(name: name),
      ),
    )).toJson(),
  );

  Future<void> delete(String id) => apiCall(_client.delete(id: id));

  Future<Fridge> regenerateInviteCode(String id) async => Fridge.fromJson(
    (await apiCall(_client.regenerateInviteCode(id: id))).toJson(),
  );

  Future<List<FridgeMember>> members(String id) async => [
    for (final m in await apiCall(_client.getMembers(id: id)))
      FridgeMember.fromJson(m.toJson()),
  ];

  Future<FridgeMember> updateMember(
    String fridgeId,
    String userId, {
    required bool canPut,
    required bool canUse,
    required DateTime? accessExpiresAt,
  }) async => FridgeMember.fromJson(
    (await apiCall(
      _client.updateMemberRights(
        id: fridgeId,
        userId: userId,
        body: UpdateMemberRightsRequest(
          canPut: canPut,
          canUse: canUse,
          accessExpiresAt: accessExpiresAt?.toUtc(),
        ),
      ),
    )).toJson(),
  );

  /// Removes someone else, or the user themselves (leaving the fridge).
  Future<void> removeMember(String fridgeId, String userId) =>
      apiCall(_client.removeMember(id: fridgeId, userId: userId));

  Future<AlertSettings> alertSettings(String fridgeId) async {
    final response = await _request(
      _dio.get<Map<String, dynamic>>(_alertsPath(fridgeId)),
    );
    return AlertSettings.fromJson(response.data!);
  }

  Future<AlertSettings> saveAlertSettings(
    String fridgeId,
    AlertSettings settings,
  ) async {
    final response = await _request(
      _dio.put<Map<String, dynamic>>(
        _alertsPath(fridgeId),
        data: settings.toJson(),
      ),
    );
    return AlertSettings.fromJson(response.data!);
  }

  /// Every item the fridge has had, newest first: the ones still there and
  /// the ones used up, thrown out or removed.
  Future<List<ActivityEntry>> activity(String fridgeId) async {
    final [categories, ...byStatus] = await Future.wait([
      _request(_dio.get<List<dynamic>>('/api/product-categories')),
      for (final status in ItemStatus.values)
        _request(
          _dio.get<List<dynamic>>(
            '/api/fridges/$fridgeId/items',
            queryParameters: {'status': status.name},
          ),
        ),
    ]);
    final categoryNames = {
      for (final c in categories.data!.cast<Map<String, dynamic>>())
        c['id'] as String: c['name'] as String,
    };
    return [
      for (final response in byStatus)
        for (final item in response.data!.cast<Map<String, dynamic>>())
          ActivityEntry(
            itemId: item['id'] as String,
            name: item['name'] as String,
            category: categoryNames[item['categoryId']] ?? '',
            amount: [
              item['amount'],
              item['unit'],
            ].whereType<String>().where((s) => s.isNotEmpty).join(' '),
            addedByUserId: item['addedByUserId'] as String,
            addedAt: DateTime.parse(item['createdAt'] as String),
            status: ItemStatus.values.byName(item['status'] as String),
          ),
    ]..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  static String _alertsPath(String fridgeId) =>
      '/api/fridges/$fridgeId/notification-settings';

  static Future<Response<T>> _request<T>(Future<Response<T>> request) async {
    try {
      return await request;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final fridgesApiProvider = Provider<FridgesApi>(
  (ref) => FridgesApi(ref.watch(dioProvider)),
);
