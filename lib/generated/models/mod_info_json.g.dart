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

_$ModInfoJsonImpl _$$ModInfoJsonImplFromJson(Map<String, dynamic> json) =>
    _$ModInfoJsonImpl(
      json['id'] as String,
      name: json['name'] as String? ?? "",
      version: const JsonConverterVersion().fromJson(json['version']),
      author: json['author'] as String?,
      gameVersion: json['gameVersion'] as String?,
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => Dependency.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$ModInfoJsonImplToJson(_$ModInfoJsonImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': const JsonConverterVersion().toJson(instance.version),
      'author': instance.author,
      'gameVersion': instance.gameVersion,
      'dependencies': instance.dependencies,
      'description': instance.description,
    };

_$DependencyImpl _$$DependencyImplFromJson(Map<String, dynamic> json) =>
    _$DependencyImpl(
      id: json['id'] as String?,
      name: json['name'] as String?,
      version: const JsonConverterVersionNullable().fromJson(json['version']),
    );

Map<String, dynamic> _$$DependencyImplToJson(_$DependencyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': const JsonConverterVersionNullable().toJson(instance.version),
    };

_$VersionObjectImpl _$$VersionObjectImplFromJson(Map<String, dynamic> json) =>
    _$VersionObjectImpl(
      json['major'],
      json['minor'],
      json['patch'],
    );

Map<String, dynamic> _$$VersionObjectImplToJson(_$VersionObjectImpl instance) =>
    <String, dynamic>{
      'major': instance.major,
      'minor': instance.minor,
      'patch': instance.patch,
    };
