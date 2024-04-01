// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../jre_manager/jre_23.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$Jre23VersionCheckerImpl _$$Jre23VersionCheckerImplFromJson(
        Map<String, dynamic> json) =>
    _$Jre23VersionCheckerImpl(
      masterVersionFile: json['masterVersionFile'] as String,
      modName: json['modName'] as String,
      modThreadId: json['modThreadId'] as int?,
      modVersion: const JsonConverterVersion().fromJson(json['modVersion']),
      starsectorVersion: json['starsectorVersion'] as String,
      windowsJDKDownload: json['windowsJDKDownload'] as String?,
      windowsConfigDownload: json['windowsConfigDownload'] as String?,
      linuxJDKDownload: json['linuxJDKDownload'] as String?,
      linuxConfigDownload: json['linuxConfigDownload'] as String?,
    );

Map<String, dynamic> _$$Jre23VersionCheckerImplToJson(
        _$Jre23VersionCheckerImpl instance) =>
    <String, dynamic>{
      'masterVersionFile': instance.masterVersionFile,
      'modName': instance.modName,
      'modThreadId': instance.modThreadId,
      'modVersion': const JsonConverterVersion().toJson(instance.modVersion),
      'starsectorVersion': instance.starsectorVersion,
      'windowsJDKDownload': instance.windowsJDKDownload,
      'windowsConfigDownload': instance.windowsConfigDownload,
      'linuxJDKDownload': instance.linuxJDKDownload,
      'linuxConfigDownload': instance.linuxConfigDownload,
    };
