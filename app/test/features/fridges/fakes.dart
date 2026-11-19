import 'package:app/core/api/api_client.dart';
import 'package:app/features/food/data/expiry_defaults_controller.dart';
import 'package:app/features/food/domain/expiry_defaults.dart';
import 'package:app/features/fridges/data/fridges_api.dart';
import 'package:app/features/fridges/data/fridges_cache.dart';
import 'package:app/features/fridges/domain/fridge.dart';

import '../auth/fakes.dart';

const ben = FridgeMember(
  userId: 'ben',
  displayName: 'Ben Okafor',
  isOwner: false,
  canPut: true,
  canUse: false,
);

FridgeMember annaMember({bool owner = true}) => FridgeMember(
  userId: anna.id,
  displayName: 'Anna Berg',
  isOwner: owner,
  canPut: true,
  canUse: true,
);

Fridge fridge({
  String id = 'home',
  String name = 'Home fridge',
  int members = 2,
  bool owner = true,
}) => Fridge(
  id: id,
  name: name,
  memberCount: members,
  maxMembers: 15,
  isOwner: owner,
  canPut: true,
  canUse: true,
  inviteCode: owner ? 'ABCD2345' : null,
);

/// The backend, in memory. Every call is recorded in [calls].
class FakeFridgesApi implements FridgesApi {
  FakeFridgesApi({
    List<Fridge>? fridges,
    Map<String, List<FridgeMember>>? crews,
  }) : fridges = fridges ?? [fridge()],
       crews =
           crews ??
           {
             'home': [annaMember(), ben],
           };

  List<Fridge> fridges;

  /// Each fridge's members, by fridge id.
  Map<String, List<FridgeMember>> crews;
  final alerts = <String, AlertSettings>{};
  final activityLog = <String, List<ActivityEntry>>{};
  final calls = <String>[];

  /// When true, every call fails as if there were no connection.
  bool offline = false;

  Future<T> _answer<T>(String call, T Function() answer) async {
    if (offline) throw ApiException("Can't reach the server.");
    calls.add(call);
    return answer();
  }

  /// Like the backend, a fridge that isn't there is a 404.
  Fridge _find(String id) => fridges.firstWhere(
    (f) => f.id == id,
    orElse: () => throw ApiException('Fridge not found.', statusCode: 404),
  );

  @override
  Future<List<Fridge>> mine() => _answer('mine', () => [...fridges]);

  @override
  Future<Fridge> create(String name) => _answer('create $name', () {
    final created = fridge(id: 'new', name: name, members: 1);
    fridges = [...fridges, created];
    return created;
  });

  @override
  Future<Fridge> join(String inviteCode) => _answer(
    'join $inviteCode',
    () =>
        throw ApiException('No fridge has this invite code.', statusCode: 404),
  );

  @override
  Future<Fridge> rename(String id, String name) =>
      _answer('rename $id $name', () {
        final renamed = _find(id).copyWith(name: name);
        fridges = [for (final f in fridges) f.id == id ? renamed : f];
        return renamed;
      });

  @override
  Future<void> delete(String id) => _answer('delete $id', () {
    fridges = [
      for (final f in fridges)
        if (f.id != id) f,
    ];
  });

  @override
  Future<Fridge> regenerateInviteCode(String id) =>
      _answer('reset code $id', () {
        final updated = _find(id).copyWith(inviteCode: 'NEWC0DE9');
        fridges = [for (final f in fridges) f.id == id ? updated : f];
        return updated;
      });

  @override
  Future<List<FridgeMember>> members(String id) =>
      _answer('members $id', () => [...?crews[id]]);

  @override
  Future<FridgeMember> updateMember(
    String fridgeId,
    String userId, {
    required bool canPut,
    required bool canUse,
    required DateTime? accessExpiresAt,
  }) => _answer('rights $userId put=$canPut use=$canUse', () {
    final updated = crews[fridgeId]!
        .firstWhere((m) => m.userId == userId)
        .withRights(
          canPut: canPut,
          canUse: canUse,
          accessExpiresAt: accessExpiresAt,
        );
    crews[fridgeId] = [
      for (final m in crews[fridgeId]!) m.userId == userId ? updated : m,
    ];
    return updated;
  });

  @override
  Future<void> removeMember(String fridgeId, String userId) =>
      _answer('remove $userId', () {
        crews[fridgeId] = [
          for (final m in crews[fridgeId]!)
            if (m.userId != userId) m,
        ];
      });

  @override
  Future<AlertSettings> alertSettings(String fridgeId) => _answer(
    'alerts $fridgeId',
    () => alerts[fridgeId] ?? const AlertSettings(),
  );

  @override
  Future<AlertSettings> saveAlertSettings(
    String fridgeId,
    AlertSettings settings,
  ) => _answer('save alerts $fridgeId', () => alerts[fridgeId] = settings);

  @override
  Future<List<ActivityEntry>> activity(String fridgeId) =>
      _answer('activity $fridgeId', () => [...?activityLog[fridgeId]]);
}

/// [FridgesCache] in memory.
class FakeFridgesCache implements FridgesCache {
  final lists = <String, List<Fridge>>{};
  String? current;
  final memberLists = <String, List<FridgeMember>>{};
  final alertSettings = <String, AlertSettings>{};
  final activityLogs = <String, List<ActivityEntry>>{};
  Map<String, PendingFridgeChange> pendingChanges = {};

  @override
  Future<List<Fridge>?> fridges(String owner) async => lists[owner];

  @override
  Future<void> saveFridges(String owner, List<Fridge> fridges) async =>
      lists[owner] = fridges;

  @override
  Future<String?> currentId() async => current;

  @override
  Future<void> saveCurrentId(String id) async => current = id;

  @override
  Future<List<FridgeMember>?> members(String fridgeId) async =>
      memberLists[fridgeId];

  @override
  Future<void> saveMembers(String fridgeId, List<FridgeMember> members) async =>
      memberLists[fridgeId] = members;

  @override
  Future<AlertSettings?> alerts(String fridgeId) async =>
      alertSettings[fridgeId];

  @override
  Future<void> saveAlerts(String fridgeId, AlertSettings settings) async =>
      alertSettings[fridgeId] = settings;

  @override
  Future<List<ActivityEntry>?> activity(String fridgeId) async =>
      activityLogs[fridgeId];

  @override
  Future<void> saveActivity(
    String fridgeId,
    List<ActivityEntry> entries,
  ) async => activityLogs[fridgeId] = entries;

  @override
  Future<Map<String, PendingFridgeChange>> pending() async => {
    for (final MapEntry(:key, :value) in pendingChanges.entries)
      if (!value.isEmpty) key: value,
  };

  @override
  Future<void> savePending(Map<String, PendingFridgeChange> pending) async =>
      pendingChanges = {...pending};

  @override
  Future<void> clear() async {
    lists.clear();
    current = null;
    memberLists.clear();
    alertSettings.clear();
    activityLogs.clear();
    pendingChanges = {};
  }
}

class FakeExpiryDefaultsStorage implements ExpiryDefaultsStorage {
  FakeExpiryDefaultsStorage([this.defaults = ExpiryDefaults.none]);

  ExpiryDefaults defaults;

  @override
  Future<ExpiryDefaults> read() async => defaults;

  @override
  Future<void> save(ExpiryDefaults defaults) async => this.defaults = defaults;
}
