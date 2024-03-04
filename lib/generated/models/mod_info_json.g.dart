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
      version: json['version'] as String,
    );

Map<String, dynamic> _$$ModInfoJsonModel_091aImplToJson(
        _$ModInfoJsonModel_091aImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': instance.version,
    };

_$ModInfoJsonModel_095aImpl _$$ModInfoJsonModel_095aImplFromJson(
        Map<String, dynamic> json) =>
    _$ModInfoJsonModel_095aImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      version: Version_095a.fromJson(json['version'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ModInfoJsonModel_095aImplToJson(
        _$ModInfoJsonModel_095aImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': instance.version,
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
