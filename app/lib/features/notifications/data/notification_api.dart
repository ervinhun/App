import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/generated/export.dart';
import 'package:app/features/notifications/data/reminders_storage.dart';
import 'package:app/features/notifications/domain/fridge_reminders.dart';

/// The backend's notification endpoints. Throws [ApiException] on failure.
class NotificationApi {
  NotificationApi(this._dio);

  final Dio _dio;

  /// Each of the user's fridges, with its settings and the items they are to
  /// hear about. The backend has already applied the fridge's recipient rules,
  /// so a fridge they aren't a recipient of comes back without items.
  Future<List<FridgeReminders>> fetchReminders() => apiCall(_fetch());

  Future<List<FridgeReminders>> _fetch() async {
    final fridges = await FridgesClient(_dio).getMine();
    return Future.wait([for (final f in fridges) _forFridge(f.id!)]);
  }

  Future<FridgeReminders> _forFridge(String id) async {
    final response = await NotificationItemsClient(_dio)
        .getNotificationItems(fridgeId: id);
    return FridgeReminders.fromResponse(id, response);
  }

  /// Reports a delivered reminder for the backend's `notification_dispatches`:
  /// a warning is stage `warning`, a danger notice `expiry`.
  Future<void> reportDispatch(PendingDispatch dispatch) => apiCall(
    NotificationDispatchesClient(_dio).reportDispatches(
      fridgeId: dispatch.fridgeId,
      body: ReportDispatchesRequest(
        sentAt: dispatch.at.toUtc(),
        items: [
          for (final id in dispatch.warningIds)
            DispatchedItem(itemId: id, stage: 'warning'),
          for (final id in dispatch.dangerIds)
            DispatchedItem(itemId: id, stage: 'expiry'),
        ],
      ),
    ),
  );
}

final notificationApiProvider = Provider<NotificationApi>(
  (ref) => NotificationApi(ref.watch(dioProvider)),
);
