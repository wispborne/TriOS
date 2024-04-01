// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../models/version_checker_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VersionCheckerInfoImpl _$$VersionCheckerInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$VersionCheckerInfoImpl(
      masterVersionFile: json['masterVersionFile'] as String?,
      modNexusId: const JsonConverterToString().fromJson(json['modNexusId']),
      modThreadId: const JsonConverterToString().fromJson(json['modThreadId']),
      modVersion: json['modVersion'] == null
          ? null
          : VersionObject.fromJson(json['modVersion'] as Map<String, dynamic>),
      directDownloadURL: json['directDownloadURL'] as String?,
      changelogUrl: json['changelogUrl'] as String?,
    );

Map<String, dynamic> _$$VersionCheckerInfoImplToJson(
        _$VersionCheckerInfoImpl instance) =>
    <String, dynamic>{
      'masterVersionFile': instance.masterVersionFile,
      'modNexusId': _$JsonConverterToJson<dynamic, String>(
          instance.modNexusId, const JsonConverterToString().toJson),
      'modThreadId': _$JsonConverterToJson<dynamic, String>(
          instance.modThreadId, const JsonConverterToString().toJson),
      'modVersion': instance.modVersion,
      'directDownloadURL': instance.directDownloadURL,
      'changelogUrl': instance.changelogUrl,
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
