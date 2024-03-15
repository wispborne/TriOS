// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../models/version_checker_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VersionCheckerInfoImpl _$$VersionCheckerInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$VersionCheckerInfoImpl(
      masterVersionFile: json['masterVersionFile'] as String?,
      modNexusId: json['modNexusId'] as String?,
      modThreadId: json['modThreadId'] as String?,
      modVersion:
          const VersionJsonConverterNullable().fromJson(json['modVersion']),
      directDownloadUrl: json['directDownloadUrl'] as String?,
      changelogUrl: json['changelogUrl'] as String?,
    );

Map<String, dynamic> _$$VersionCheckerInfoImplToJson(
        _$VersionCheckerInfoImpl instance) =>
    <String, dynamic>{
      'masterVersionFile': instance.masterVersionFile,
      'modNexusId': instance.modNexusId,
      'modThreadId': instance.modThreadId,
      'modVersion':
          const VersionJsonConverterNullable().toJson(instance.modVersion),
      'directDownloadUrl': instance.directDownloadUrl,
      'changelogUrl': instance.changelogUrl,
    };
