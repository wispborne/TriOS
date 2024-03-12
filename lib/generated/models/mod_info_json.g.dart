// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../models/mod_info_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EnabledModsJsonModeImpl _$$EnabledModsJsonModeImplFromJson(
        Map<String, dynamic> json) =>
    _$EnabledModsJsonModeImpl(
      (json['enabledMods'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$EnabledModsJsonModeImplToJson(
        _$EnabledModsJsonModeImpl instance) =>
    <String, dynamic>{
      'enabledMods': instance.enabledMods,
    };

_$ModInfoJsonModel_091aImpl _$$ModInfoJsonModel_091aImplFromJson(
        Map<String, dynamic> json) =>
    _$ModInfoJsonModel_091aImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      version: const VersionJsonConverter().fromJson(json['version']),
      gameVersion: json['gameVersion'] as String?,
    );

Map<String, dynamic> _$$ModInfoJsonModel_091aImplToJson(
        _$ModInfoJsonModel_091aImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': const VersionJsonConverter().toJson(instance.version),
      'gameVersion': instance.gameVersion,
    };

_$ModInfoJsonModel_095aImpl _$$ModInfoJsonModel_095aImplFromJson(
        Map<String, dynamic> json) =>
    _$ModInfoJsonModel_095aImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      version: const VersionJsonConverter().fromJson(json['version']),
      gameVersion: json['gameVersion'] as String?,
    );

Map<String, dynamic> _$$ModInfoJsonModel_095aImplToJson(
        _$ModInfoJsonModel_095aImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': const VersionJsonConverter().toJson(instance.version),
      'gameVersion': instance.gameVersion,
    };

_$ModInfoJsonImpl _$$ModInfoJsonImplFromJson(Map<String, dynamic> json) =>
    _$ModInfoJsonImpl(
      json['id'] as String,
      json['name'] as String,
      const VersionJsonConverter().fromJson(json['version']),
      json['gameVersion'] as String?,
    );

Map<String, dynamic> _$$ModInfoJsonImplToJson(_$ModInfoJsonImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': const VersionJsonConverter().toJson(instance.version),
      'gameVersion': instance.gameVersion,
    };

_$Version_095aImpl _$$Version_095aImplFromJson(Map<String, dynamic> json) =>
    _$Version_095aImpl(
      json['major'],
      json['minor'],
      json['patch'],
    );

Map<String, dynamic> _$$Version_095aImplToJson(_$Version_095aImpl instance) =>
    <String, dynamic>{
      'major': instance.major,
      'minor': instance.minor,
      'patch': instance.patch,
    };
