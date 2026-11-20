import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/fridges/data/fridges_api.dart';
import 'package:app/features/fridges/domain/fridge_space.dart';

/// The user's fridge spaces, oldest first, and the one the Dashboard shows.
class FridgeSpaces {
  FridgeSpaces(Iterable<FridgeSpace> spaces, this.currentId)
    : all = [...spaces]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final List<FridgeSpace> all;
  final String? currentId;

  /// The last one picked, else the first. Null if the user has none.
  FridgeSpace? get current =>
      all.where((s) => s.id == currentId).firstOrNull ?? all.firstOrNull;
}

class FridgeSpacesController extends AsyncNotifier<FridgeSpaces> {
  @override
  Future<FridgeSpaces> build() async {
    ref.watch(authControllerProvider.select((auth) => auth.value?.id));
    final all = await ref.watch(fridgesApiProvider).mine();
    return FridgeSpaces(all, await ref.watch(lastFridgeSpaceProvider).read());
  }

  void select(String id) {
    state = AsyncData(FridgeSpaces(state.requireValue.all, id));
    ref.read(lastFridgeSpaceProvider).write(id);
  }

  Future<FridgeSpace> create(String name, List<StorageLocation> storages) =>
      _add(ref.read(fridgesApiProvider).create(name, storages));

  Future<FridgeSpace> join(String code) =>
      _add(ref.read(fridgesApiProvider).join(code));

  Future<FridgeSpace> newInviteCode(String id) =>
      _add(ref.read(fridgesApiProvider).newInviteCode(id));

  Future<FridgeSpace> _add(Future<FridgeSpace> request) async {
    final space = await request;
    final others = state.value?.all.where((s) => s.id != space.id) ?? [];
    state = AsyncData(FridgeSpaces([...others, space], space.id));
    ref.read(lastFridgeSpaceProvider).write(space.id);
    return space;
  }
}

final fridgeSpacesProvider =
    AsyncNotifierProvider<FridgeSpacesController, FridgeSpaces>(
      FridgeSpacesController.new,
      retry: (_, _) => null, // The screen offers Try again instead.
    );

/// The space's expiry notification settings, or the defaults if they can't be
/// loaded: they only group and colour the food.
final expiryThresholdsProvider =
    FutureProvider.family<ExpiryThresholds, String>(
      (ref, id) => ref
          .watch(fridgesApiProvider)
          .expiryThresholds(id)
          .catchError((_) => defaultThresholds),
    );

/// Remembers the last fridge space, so the app opens on it.
class LastFridgeSpace {
  late final _prefs = SharedPreferencesAsync();

  Future<String?> read() =>
      _prefs.getString('fridge_space').catchError((_) => null);

  Future<void> write(String id) =>
      _prefs.setString('fridge_space', id).catchError((_) {});
}

final lastFridgeSpaceProvider = Provider((ref) => LastFridgeSpace());
