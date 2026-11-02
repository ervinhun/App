// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fridge_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FridgeResponse _$FridgeResponseFromJson(Map<String, dynamic> json) =>
    FridgeResponse(
      id: json['id'] as String?,
      name: json['name'] as String?,
      inviteCode: json['inviteCode'] as String?,
      maxMembers: json['maxMembers'],
      maxContainers: json['maxContainers'],
      memberCount: json['memberCount'],
      isOwner: json['isOwner'] as bool?,
      canPut: json['canPut'] as bool?,
      canUse: json['canUse'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FridgeResponseToJson(FridgeResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'inviteCode': instance.inviteCode,
      'maxMembers': instance.maxMembers,
      'maxContainers': instance.maxContainers,
      'memberCount': instance.memberCount,
      'isOwner': instance.isOwner,
      'canPut': instance.canPut,
      'canUse': instance.canUse,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
