// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../mod_profiles/models/mod_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ModProfilesImpl _$$ModProfilesImplFromJson(Map<String, dynamic> json) =>
    _$ModProfilesImpl(
      modProfiles: (json['modProfiles'] as List<dynamic>)
          .map((e) => ModProfile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ModProfilesImplToJson(_$ModProfilesImpl instance) =>
    <String, dynamic>{
      'modProfiles': instance.modProfiles,
    };

_$ShallowModVariantImpl _$$ShallowModVariantImplFromJson(
        Map<String, dynamic> json) =>
    _$ShallowModVariantImpl(
      modId: json['modId'] as String,
      modName: json['modName'] as String?,
      smolVariantId: json['smolVariantId'] as String,
      version: const JsonConverterVersionNullable().fromJson(json['version']),
    );

Map<String, dynamic> _$$ShallowModVariantImplToJson(
        _$ShallowModVariantImpl instance) =>
    <String, dynamic>{
      'modId': instance.modId,
      'modName': instance.modName,
      'smolVariantId': instance.smolVariantId,
      'version': const JsonConverterVersionNullable().toJson(instance.version),
    };

_$ModProfileImpl _$$ModProfileImplFromJson(Map<String, dynamic> json) =>
    _$ModProfileImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
      enabledModVariants: (json['enabledModVariants'] as List<dynamic>)
          .map((e) => ShallowModVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
      dateCreated: json['dateCreated'] == null
          ? null
          : DateTime.parse(json['dateCreated'] as String),
      dateModified: json['dateModified'] == null
          ? null
          : DateTime.parse(json['dateModified'] as String),
    );

Map<String, dynamic> _$$ModProfileImplToJson(_$ModProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'sortOrder': instance.sortOrder,
      'enabledModVariants': instance.enabledModVariants,
      'dateCreated': instance.dateCreated?.toIso8601String(),
      'dateModified': instance.dateModified?.toIso8601String(),
    };
