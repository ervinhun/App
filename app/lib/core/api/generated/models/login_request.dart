// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'login_request.g.dart';

@JsonSerializable()
class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    this.phoneModel,
    this.platform,
  });

  factory LoginRequest.fromJson(Map<String, Object?> json) =>
      _$LoginRequestFromJson(json);

  final String email;
  final String password;
  final String? phoneModel;
  final String? platform;

  Map<String, Object?> toJson() => _$LoginRequestToJson(this);
}
