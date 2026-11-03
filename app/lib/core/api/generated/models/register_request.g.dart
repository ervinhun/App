// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      displayName: json['displayName'] as String,
      locale: json['locale'] as String?,
      phoneModel: json['phoneModel'] as String?,
      platform: json['platform'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'displayName': instance.displayName,
      'locale': instance.locale,
      'phoneModel': instance.phoneModel,
      'platform': instance.platform,
    };
