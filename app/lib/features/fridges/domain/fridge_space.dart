import 'package:app/features/food/domain/food_item.dart';

/// A shared space for food: a home, an office, a flat-share. The backend calls
/// it a "fridge"; its [containers] are the actual fridges, freezers, pantries.
class FridgeSpace {
  const FridgeSpace({
    required this.id,
    required this.name,
    required this.isOwner,
    required this.canPut,
    required this.createdAt,
    required this.containers,
    this.inviteCode,
  });

  final String id;
  final String name;

  /// What others join with. Only owners get to see it.
  final String? inviteCode;
  final bool isOwner;
  final bool canPut;
  final DateTime createdAt;

  /// Container type and name, e.g. (fridge, "Kitchen fridge").
  final List<(StorageLocation, String)> containers;

  /// The kinds of storage this space has, in tab order.
  List<StorageLocation> get storages => [
    for (final s in StorageLocation.values)
      if (containers.any((c) => c.$1 == s)) s,
  ];

  /// The container's own name if it's the only one of its kind.
  String labelFor(StorageLocation storage) {
    final names = [
      for (final (type, name) in containers)
        if (type == storage) name,
    ];
    return names.length == 1 ? names.single : storage.label;
  }
}

extension StorageLocationLabel on StorageLocation {
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
}
