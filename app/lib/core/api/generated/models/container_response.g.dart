// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'container_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContainerResponse _$ContainerResponseFromJson(Map<String, dynamic> json) =>
    ContainerResponse(
      id: json['id'] as String?,
      fridgeId: json['fridgeId'] as String?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ContainerResponseToJson(ContainerResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fridgeId': instance.fridgeId,
      'name': instance.name,
      'type': instance.type,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
