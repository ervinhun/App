import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A shared fridge (the backend's sharing unit): the user's own, or one they
/// joined with an invite code.
@immutable
class Fridge {
  const Fridge({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.maxMembers,
    required this.isOwner,
    required this.canPut,
    required this.canUse,
    this.inviteCode,
  });

  /// The id of a guest's fridge, which lives on this phone only.
  static const localId = 'local';

  /// A guest's fridge: theirs alone, and never on the backend.
  static const local = Fridge(
    id: localId,
    name: 'Home',
    memberCount: 1,
    maxMembers: 1,
    isOwner: true,
    canPut: true,
    canUse: true,
  );

  final String id;
  final String name;
  final int memberCount;
  final int maxMembers;
  final bool isOwner;

  /// Whether the user may add food.
  final bool canPut;

  /// Whether the user may use up or remove food.
  final bool canUse;

  /// Only the owner gets it: anyone who has it can join.
  final String? inviteCode;

  bool get isLocal => id == localId;

  /// Nobody else uses it, so changing it offline can't clash with anyone.
  bool get isSolo => memberCount <= 1;

  bool get isFull => memberCount >= maxMembers;

  Fridge copyWith({String? name, String? inviteCode, int? memberCount}) =>
      Fridge(
        id: id,
        name: name ?? this.name,
        memberCount: memberCount ?? this.memberCount,
        maxMembers: maxMembers,
        isOwner: isOwner,
        canPut: canPut,
        canUse: canUse,
        inviteCode: inviteCode ?? this.inviteCode,
      );

  factory Fridge.fromJson(Map<String, dynamic> json) => Fridge(
    id: json['id'] as String,
    name: json['name'] as String,
    memberCount: _int(json['memberCount']),
    maxMembers: _int(json['maxMembers']),
    isOwner: json['isOwner'] as bool? ?? false,
    canPut: json['canPut'] as bool? ?? false,
    canUse: json['canUse'] as bool? ?? false,
    inviteCode: json['inviteCode'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'memberCount': memberCount,
    'maxMembers': maxMembers,
    'isOwner': isOwner,
    'canPut': canPut,
    'canUse': canUse,
    'inviteCode': inviteCode,
  };
}

/// Someone in a fridge, with what they may do there.
@immutable
class FridgeMember {
  const FridgeMember({
    required this.userId,
    required this.displayName,
    required this.isOwner,
    required this.canPut,
    required this.canUse,
    this.accessExpiresAt,
  });

  final String userId;
  final String displayName;
  final bool isOwner;
  final bool canPut;
  final bool canUse;

  /// When their access ends; null for access that never does.
  final DateTime? accessExpiresAt;

  bool get isTemporary => accessExpiresAt != null;

  /// Up to two letters for the avatar: "Maya Patel" is MP.
  String get initials {
    final words = displayName.trim().split(RegExp(r'\s+'));
    return words
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w.characters.first.toUpperCase())
        .join();
  }

  /// What they may do with the food, as the design words it.
  String get rightsLabel {
    if (isOwner) return 'Add, remove & manage';
    return switch ((canPut, canUse)) {
      (true, true) => 'Add & remove',
      (true, false) => 'Add only',
      (false, true) => 'Remove only',
      (false, false) => 'View only',
    };
  }

  FridgeMember withRights({
    required bool canPut,
    required bool canUse,
    required DateTime? accessExpiresAt,
  }) => FridgeMember(
    userId: userId,
    displayName: displayName,
    isOwner: isOwner,
    canPut: canPut,
    canUse: canUse,
    accessExpiresAt: accessExpiresAt,
  );

  factory FridgeMember.fromJson(Map<String, dynamic> json) => FridgeMember(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String? ?? '',
    isOwner: json['isOwner'] as bool? ?? false,
    canPut: json['canPut'] as bool? ?? false,
    canUse: json['canUse'] as bool? ?? false,
    accessExpiresAt: switch (json['accessExpiresAt']) {
      final String at => DateTime.parse(at),
      _ => null,
    },
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'isOwner': isOwner,
    'canPut': canPut,
    'canUse': canUse,
    'accessExpiresAt': accessExpiresAt?.toUtc().toIso8601String(),
  };
}

/// Who gets a fridge's expiry alerts, as the backend names them.
enum RecipientsScope {
  allMembers('all_members'),
  adderAndOwners('adder_and_owners'),
  custom('custom');

  const RecipientsScope(this.wireName);

  final String wireName;

  static RecipientsScope fromWire(String? name) => values.firstWhere(
    (scope) => scope.wireName == name,
    orElse: () => allMembers,
  );
}

/// When a fridge's expiry alerts go out, and to whom. Every member can see
/// them; only the owner can change them.
@immutable
class AlertSettings {
  const AlertSettings({
    this.warningDaysBefore = 7,
    this.dangerDaysBefore = 2,
    this.notificationHour = 16,
    this.notificationMinute = 0,
    this.scope = RecipientsScope.allMembers,
    this.recipientUserIds = const {},
  });

  /// The backend's limits for both reminders.
  static const maxDays = 365;

  /// The heads-up: days before the expiry date.
  final int warningDaysBefore;

  /// The last call, which must come after the heads-up; 0 is on the day.
  final int dangerDaysBefore;

  /// The time of day the reminders show, in the phone's own time zone.
  final int notificationHour;
  final int notificationMinute;

  final RecipientsScope scope;

  /// Who to notify when [scope] is custom; empty otherwise.
  final Set<String> recipientUserIds;

  AlertSettings copyWith({
    int? warningDaysBefore,
    int? dangerDaysBefore,
    int? notificationHour,
    int? notificationMinute,
    RecipientsScope? scope,
    Set<String>? recipientUserIds,
  }) => AlertSettings(
    warningDaysBefore: warningDaysBefore ?? this.warningDaysBefore,
    dangerDaysBefore: dangerDaysBefore ?? this.dangerDaysBefore,
    notificationHour: notificationHour ?? this.notificationHour,
    notificationMinute: notificationMinute ?? this.notificationMinute,
    scope: scope ?? this.scope,
    recipientUserIds: recipientUserIds ?? this.recipientUserIds,
  );

  /// Whether [member] gets the alerts. With [RecipientsScope.adderAndOwners]
  /// everyone else gets those for the food they added.
  bool notifies(FridgeMember member) => switch (scope) {
    RecipientsScope.allMembers => true,
    RecipientsScope.adderAndOwners => member.isOwner,
    RecipientsScope.custom => recipientUserIds.contains(member.userId),
  };

  /// "16:00".
  String get timeLabel =>
      '${notificationHour.toString().padLeft(2, '0')}:'
      '${notificationMinute.toString().padLeft(2, '0')}';

  factory AlertSettings.fromJson(Map<String, dynamic> json) {
    final [hour, minute, ...] = '${json['notificationTime'] ?? '16:00'}'
        .split(':')
        .map(int.parse)
        .toList();
    return AlertSettings(
      warningDaysBefore: _int(json['warningDaysBefore']),
      dangerDaysBefore: _int(json['dangerDaysBefore']),
      notificationHour: hour,
      notificationMinute: minute,
      scope: RecipientsScope.fromWire(json['recipientsScope'] as String?),
      recipientUserIds: {
        for (final id in json['recipientUserIds'] as List<dynamic>? ?? [])
          id as String,
      },
    );
  }

  /// The backend's SaveNotificationSettingsRequest, which is also how it's
  /// saved on the phone.
  Map<String, dynamic> toJson() => {
    'warningDaysBefore': warningDaysBefore,
    'dangerDaysBefore': dangerDaysBefore,
    'notificationTime': '$timeLabel:00',
    'recipientsScope': scope.wireName,
    'recipientUserIds': scope == RecipientsScope.custom
        ? recipientUserIds.toList()
        : <String>[],
  };

  @override
  bool operator ==(Object other) =>
      other is AlertSettings &&
      other.warningDaysBefore == warningDaysBefore &&
      other.dangerDaysBefore == dangerDaysBefore &&
      other.notificationHour == notificationHour &&
      other.notificationMinute == notificationMinute &&
      other.scope == scope &&
      setEquals(other.recipientUserIds, recipientUserIds);

  @override
  int get hashCode => Object.hash(
    warningDaysBefore,
    dangerDaysBefore,
    notificationHour,
    notificationMinute,
    scope,
    Object.hashAllUnordered(recipientUserIds),
  );
}

/// What happened to one item, for the activity log. The backend records who
/// added each item and when, and whether it's still there, but not who took
/// it out or when.
@immutable
class ActivityEntry {
  const ActivityEntry({
    required this.itemId,
    required this.name,
    required this.category,
    required this.amount,
    required this.addedByUserId,
    required this.addedAt,
    required this.status,
  });

  final String itemId;
  final String name;

  /// The product category's name, or empty.
  final String category;

  /// "400 g", or empty.
  final String amount;
  final String addedByUserId;
  final DateTime addedAt;
  final ItemStatus status;

  bool get isGone => status != ItemStatus.active;

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
    itemId: json['itemId'] as String,
    name: json['name'] as String,
    category: json['category'] as String? ?? '',
    amount: json['amount'] as String? ?? '',
    addedByUserId: json['addedByUserId'] as String,
    addedAt: DateTime.parse(json['addedAt'] as String),
    status: ItemStatus.values.byName(json['status'] as String),
  );

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'name': name,
    'category': category,
    'amount': amount,
    'addedByUserId': addedByUserId,
    'addedAt': addedAt.toUtc().toIso8601String(),
    'status': status.name,
  };
}

/// An item's status on the backend: still there, or gone and why.
enum ItemStatus { active, consumed, expired, removed }

/// The backend sends some integers as strings (its OpenAPI allows both).
int _int(Object? value) => switch (value) {
  final int n => n,
  final String s => int.parse(s),
  _ => 0,
};
