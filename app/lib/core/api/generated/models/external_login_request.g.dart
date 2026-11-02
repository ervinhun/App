// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'external_login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExternalLoginRequest _$ExternalLoginRequestFromJson(
  Map<String, dynamic> json,
) => ExternalLoginRequest(
  provider: json['provider'] as String,
  idToken: json['idToken'] as String,
  displayName: json['displayName'] as String?,
  locale: json['locale'] as String?,
  phoneModel: json['phoneModel'] as String?,
  platform: json['platform'] as String?,
);

Map<String, dynamic> _$ExternalLoginRequestToJson(
  ExternalLoginRequest instance,
) => <String, dynamic>{
  'provider': instance.provider,
  'idToken': instance.idToken,
  'displayName': instance.displayName,
  'locale': instance.locale,
  'phoneModel': instance.phoneModel,
  'platform': instance.platform,
};
