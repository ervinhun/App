import 'package:app/core/api/api_client.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/fridges/data/fridge_spaces_controller.dart';
import 'package:app/features/fridges/data/fridges_api.dart';
import 'package:app/features/fridges/domain/fridge_space.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart';

var _made = 0;

/// Made in the order the test makes them, unless [createdAt] says otherwise.
FridgeSpace fakeSpace({
  String id = 'home',
  String name = 'Home',
  bool isOwner = true,
  bool canPut = true,
  List<StorageLocation> storages = StorageLocation.values,
  Map<StorageLocation, String> names = const {},
  DateTime? createdAt,
  String inviteCode = 'ABCD2345',
}) => FridgeSpace(
  id: id,
  name: name,
  inviteCode: isOwner ? inviteCode : null,
  isOwner: isOwner,
  canPut: canPut,
  createdAt: createdAt ?? DateTime(2026).add(Duration(seconds: _made++)),
  containers: [for (final s in storages) (s, names[s] ?? s.label)],
);

/// The user's fridge spaces, from [api] (by default just "Home").
List<Override> fridgeOverrides([FakeFridgesApi? api, FakeLastSpace? last]) => [
  fridgesApiProvider.overrideWithValue(api ?? FakeFridgesApi()),
  lastFridgeSpaceProvider.overrideWithValue(last ?? FakeLastSpace()),
];

class FakeFridgesApi extends FridgesApi {
  FakeFridgesApi([List<FridgeSpace>? spaces])
    : spaces = spaces ?? [fakeSpace()],
      super(Dio());

  List<FridgeSpace> spaces;
  ApiException? loadError, joinError;
  ExpiryThresholds thresholds = defaultThresholds;
  final created = <(String, List<StorageLocation>)>[];
  final joined = <String>[];

  @override
  Future<List<FridgeSpace>> mine() async =>
      loadError == null ? spaces : throw loadError!;

  @override
  Future<FridgeSpace> create(
    String name,
    List<StorageLocation> storages,
  ) async {
    created.add((name, storages));
    return fakeSpace(id: 'new', name: name, storages: storages);
  }

  @override
  Future<FridgeSpace> join(String inviteCode) async {
    if (joinError != null) throw joinError!;
    joined.add(inviteCode);
    return fakeSpace(id: 'joined', name: 'Office', isOwner: false);
  }

  @override
  Future<FridgeSpace> newInviteCode(String fridgeId) async =>
      fakeSpace(id: fridgeId, inviteCode: 'NEWCODE9');

  @override
  Future<ExpiryThresholds> expiryThresholds(String fridgeId) async =>
      thresholds;
}

class FakeLastSpace extends LastFridgeSpace {
  FakeLastSpace([this.id]);

  String? id;

  @override
  Future<String?> read() async => id;

  @override
  Future<void> write(String id) async => this.id = id;
}
