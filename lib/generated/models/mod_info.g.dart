// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../models/mod_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ModInfoImpl _$$ModInfoImplFromJson(Map<String, dynamic> json) =>
    _$ModInfoImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      version: const JsonConverterVersion().fromJson(json['version']),
      description: json['description'] as String?,
      gameVersion: json['gameVersion'] as String?,
      author: json['author'] as String?,
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => Dependency.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ModInfoImplToJson(_$ModInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': const JsonConverterVersion().toJson(instance.version),
      'description': instance.description,
      'gameVersion': instance.gameVersion,
      'author': instance.author,
      'dependencies': instance.dependencies,
    };
