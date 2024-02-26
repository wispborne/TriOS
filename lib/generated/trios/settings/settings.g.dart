// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../trios/settings/settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsImpl _$$SettingsImplFromJson(Map<String, dynamic> json) =>
    _$SettingsImpl(
      gameDir: json['gameDir'] as String?,
      modsDir: json['modsDir'] as String?,
      enabledModIds: (json['enabledModIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      shouldAutoUpdateOnLaunch:
          json['shouldAutoUpdateOnLaunch'] as bool? ?? false,
      isRulesHotReloadEnabled:
          json['isRulesHotReloadEnabled'] as bool? ?? false,
    );

Map<String, dynamic> _$$SettingsImplToJson(_$SettingsImpl instance) =>
    <String, dynamic>{
      'gameDir': instance.gameDir,
      'modsDir': instance.modsDir,
      'enabledModIds': instance.enabledModIds,
      'shouldAutoUpdateOnLaunch': instance.shouldAutoUpdateOnLaunch,
      'isRulesHotReloadEnabled': instance.isRulesHotReloadEnabled,
    };
