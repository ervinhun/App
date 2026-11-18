// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_dispatches_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportDispatchesRequest _$ReportDispatchesRequestFromJson(
  Map<String, dynamic> json,
) => ReportDispatchesRequest(
  sentAt: json['sentAt'] == null
      ? null
      : DateTime.parse(json['sentAt'] as String),
  items: (json['items'] as List<dynamic>)
      .map((e) => DispatchedItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ReportDispatchesRequestToJson(
  ReportDispatchesRequest instance,
) => <String, dynamic>{
  'sentAt': instance.sentAt?.toIso8601String(),
  'items': instance.items,
};
