// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fridge_member_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FridgeMemberResponse _$FridgeMemberResponseFromJson(
  Map<String, dynamic> json,
) => FridgeMemberResponse(
  userId: json['userId'] as String?,
  displayName: json['displayName'] as String?,
  isOwner: json['isOwner'] as bool?,
  canPut: json['canPut'] as bool?,
  canUse: json['canUse'] as bool?,
  accessExpiresAt: json['accessExpiresAt'] == null
      ? null
      : DateTime.parse(json['accessExpiresAt'] as String),
  joinedAt: json['joinedAt'] == null
      ? null
      : DateTime.parse(json['joinedAt'] as String),
);

Map<String, dynamic> _$FridgeMemberResponseToJson(
  FridgeMemberResponse instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'displayName': instance.displayName,
  'isOwner': instance.isOwner,
  'canPut': instance.canPut,
  'canUse': instance.canUse,
  'accessExpiresAt': instance.accessExpiresAt?.toIso8601String(),
  'joinedAt': instance.joinedAt?.toIso8601String(),
};
