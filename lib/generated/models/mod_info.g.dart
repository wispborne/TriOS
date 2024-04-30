// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../models/mod_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ModInfoImpl _$$ModInfoImplFromJson(Map<String, dynamic> json) =>
    _$ModInfoImpl(
      id: json['id'] as String,
      name: json['name'] as String?,
      version: const JsonConverterVersionNullable().fromJson(json['version']),
      description: json['description'] as String?,
      gameVersion: json['gameVersion'] as String?,
      author: json['author'] as String?,
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => Dependency.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      originalGameVersion: json['originalGameVersion'] as String?,
      isUtility: json['isUtility'] == null
          ? false
          : const JsonConverterBool().fromJson(json['isUtility']),
      isTotalConversion: json['isTotalConversion'] == null
          ? false
          : const JsonConverterBool().fromJson(json['isTotalConversion']),
    );

Map<String, dynamic> _$$ModInfoImplToJson(_$ModInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': const JsonConverterVersionNullable().toJson(instance.version),
      'description': instance.description,
      'gameVersion': instance.gameVersion,
      'author': instance.author,
      'dependencies': instance.dependencies,
      'originalGameVersion': instance.originalGameVersion,
      'isUtility': const JsonConverterBool().toJson(instance.isUtility),
      'isTotalConversion':
          const JsonConverterBool().toJson(instance.isTotalConversion),
    };
