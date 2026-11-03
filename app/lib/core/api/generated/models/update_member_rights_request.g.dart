// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_member_rights_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateMemberRightsRequest _$UpdateMemberRightsRequestFromJson(
  Map<String, dynamic> json,
) => UpdateMemberRightsRequest(
  canPut: json['canPut'] as bool?,
  canUse: json['canUse'] as bool?,
  accessExpiresAt: json['accessExpiresAt'] == null
      ? null
      : DateTime.parse(json['accessExpiresAt'] as String),
);

Map<String, dynamic> _$UpdateMemberRightsRequestToJson(
  UpdateMemberRightsRequest instance,
) => <String, dynamic>{
  'canPut': instance.canPut,
  'canUse': instance.canUse,
  'accessExpiresAt': instance.accessExpiresAt?.toIso8601String(),
};
