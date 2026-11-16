import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/generated/export.dart';
import 'package:app/features/notifications/data/reminders_storage.dart';
import 'package:app/features/notifications/domain/fridge_reminders.dart';
import 'package:app/features/notifications/domain/notification_settings.dart';

/// The backend's notification endpoints. Throws [ApiException] on failure.
class NotificationApi {
  NotificationApi(this._dio);

  final Dio _dio;

  /// Each of the user's fridges that notifies them, with its settings and the
  /// items they are to hear about.
  Future<List<FridgeReminders>> fetchReminders() => apiCall(_fetch());

  Future<List<FridgeReminders>> _fetch() async {
    final userId = (await AuthClient(_dio).me()).id;
    final fridges = await FridgesClient(_dio).getMine();
    final all = await Future.wait([
      for (final f in fridges) _forFridge(f, userId),
    ]);
    return [for (final r in all) ?r];
  }

  /// Null if [userId] isn't a recipient: `custom` lists only some members, and
  /// `adder_and_owners` gives non-owners just the items they added.
  Future<FridgeReminders?> _forFridge(
    FridgeResponse fridge,
    String userId,
  ) async {
    final id = fridge.id!;
    final (settings, items) = await (
      _dio.get<Map<String, dynamic>>('/api/fridges/$id/notification-settings'),
      _dio.get<List<dynamic>>('/api/fridges/$id/items'),
    ).wait;
    final data = settings.data!;
    final scope = data['recipientsScope'];
    final picked =
        (data['recipientUserIds'] as List?)?.contains(userId) ?? false;
    if (scope == 'custom' && !picked) return null;
    final onlyOwn = scope == 'adder_and_owners' && fridge.isOwner != true;
    return FridgeReminders(
      fridgeId: id,
      settings: NotificationSettings.fromJson(data),
      items: [
        for (final item in items.data!.cast<Map<String, dynamic>>())
          if (!onlyOwn || item['addedByUserId'] == userId)
            if (DateTime.tryParse(item['expiryDate'] as String? ?? '')
                case final expires?)
              ReminderItem(id: item['id'] as String, expiresOn: expires),
      ],
    );
  }

  /// Reports a delivered reminder for the backend's `notification_dispatches`:
  /// a warning is stage `warning`, a danger notice `expiry`.
  Future<void> reportDispatch(PendingDispatch dispatch) => apiCall(
    _dio.post<void>(
      '/api/fridges/${dispatch.fridgeId}/notification-dispatches',
      data: {
        'sentAt': dispatch.at.toUtc().toIso8601String(),
        'items': [
          for (final id in dispatch.warningIds)
            {'itemId': id, 'stage': 'warning'},
          for (final id in dispatch.dangerIds)
            {'itemId': id, 'stage': 'expiry'},
        ],
      },
    ),
  );
}

final notificationApiProvider = Provider<NotificationApi>(
  (ref) => NotificationApi(ref.watch(dioProvider)),
);
