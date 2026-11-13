// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'external_login_request.g.dart';

@JsonSerializable()
class ExternalLoginRequest {
  const ExternalLoginRequest({
    required this.provider,
    required this.idToken,
    this.displayName,
    this.locale,
    this.phoneModel,
    this.platform,
  });

  factory ExternalLoginRequest.fromJson(Map<String, Object?> json) =>
      _$ExternalLoginRequestFromJson(json);

  final String provider;
  final String idToken;
  final String? displayName;
  final String? locale;
  final String? phoneModel;
  final String? platform;

  Map<String, Object?> toJson() => _$ExternalLoginRequestToJson(this);
}
