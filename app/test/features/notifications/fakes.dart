import 'package:dio/dio.dart';

import 'package:app/features/notifications/data/background_refresh.dart';
import 'package:app/features/notifications/data/notification_api.dart';
import 'package:app/features/notifications/data/notification_service.dart';
import 'package:app/features/notifications/data/reminders_storage.dart';
import 'package:app/features/notifications/domain/expiry_digest.dart';
import 'package:app/features/notifications/domain/fridge_reminders.dart';

class FakeNotificationService extends NotificationService {
  FakeNotificationService({this.allowed = true, this.grantOnRequest = false});

  bool allowed;
  bool grantOnRequest;
  int requests = 0;
  bool openedSettings = false;
  List<FridgeReminders>? scheduledFor;
  String? shown;

  @override
  Future<void> init() async {}

  @override
  Stream<String?> get taps => const Stream.empty();

  @override
  Future<bool> launchedByReminder() async => false;

  @override
  Future<bool> isAllowed() async => allowed;

  @override
  Future<bool> requestPermission() async {
    requests++;
    return allowed = grantOnRequest;
  }

  @override
  Future<void> openSettings() async => openedSettings = true;

  @override
  Future<List<ExpiryDigest>> schedule(
    List<FridgeReminders> fridges, {
    Set<String> notified = const {},
  }) async {
    scheduledFor = fridges;
    return [
      for (final f in fridges)
        ...expiryDigests(f, DateTime.now(), notified: notified),
    ];
  }

  @override
  Future<void> showNow(String body) async => shown = body;
}

class FakeRemindersStorage extends RemindersStorage {
  List<FridgeReminders>? reminders;
  List<PendingDispatch> pending = [];
  Set<String> notified = {};

  @override
  Future<List<FridgeReminders>?> readReminders() async => reminders;

  @override
  Future<void> saveReminders(List<FridgeReminders> r) async => reminders = r;

  @override
  Future<Set<String>> readNotified() async => notified;

  @override
  Future<void> saveNotified(Set<String> n) async => notified = n;

  @override
  Future<List<PendingDispatch>> readPending() async => pending;

  @override
  Future<void> savePending(List<PendingDispatch> p) async => pending = p;
}

class FakeNotificationApi extends NotificationApi {
  FakeNotificationApi({this.remote = const [], this.fails = false})
    : super(Dio());

  List<FridgeReminders> remote;
  bool fails;
  bool reportFails = false;
  final reported = <PendingDispatch>[];

  @override
  Future<List<FridgeReminders>> fetchReminders() async {
    if (fails) throw Exception('offline');
    return remote;
  }

  @override
  Future<void> reportDispatch(PendingDispatch dispatch) async {
    if (reportFails) throw Exception('offline');
    reported.add(dispatch);
  }
}

class FakeBackgroundRefresh extends BackgroundRefresh {
  int scheduled = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> schedule(List<FridgeReminders> fridges) async => scheduled++;
}
