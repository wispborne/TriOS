// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../trios/settings/settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsImpl _$$SettingsImplFromJson(Map<String, dynamic> json) =>
    _$SettingsImpl(
      gameDir: json['gameDir'] as String?,
      modsDir: json['modsDir'] as String?,
      hasCustomModsDir: json['hasCustomModsDir'] as bool? ?? false,
      enabledModIds: (json['enabledModIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      shouldAutoUpdateOnLaunch:
          json['shouldAutoUpdateOnLaunch'] as bool? ?? false,
      isRulesHotReloadEnabled:
          json['isRulesHotReloadEnabled'] as bool? ?? false,
      windowXPos: (json['windowXPos'] as num?)?.toDouble(),
      windowYPos: (json['windowYPos'] as num?)?.toDouble(),
      windowWidth: (json['windowWidth'] as num?)?.toDouble(),
      windowHeight: (json['windowHeight'] as num?)?.toDouble(),
      isMaximized: json['isMaximized'] as bool?,
      isMinimized: json['isMinimized'] as bool?,
      defaultTool:
          $enumDecodeNullable(_$TriOSToolsEnumMap, json['defaultTool']),
    );

Map<String, dynamic> _$$SettingsImplToJson(_$SettingsImpl instance) =>
    <String, dynamic>{
      'gameDir': instance.gameDir,
      'modsDir': instance.modsDir,
      'hasCustomModsDir': instance.hasCustomModsDir,
      'enabledModIds': instance.enabledModIds,
      'shouldAutoUpdateOnLaunch': instance.shouldAutoUpdateOnLaunch,
      'isRulesHotReloadEnabled': instance.isRulesHotReloadEnabled,
      'windowXPos': instance.windowXPos,
      'windowYPos': instance.windowYPos,
      'windowWidth': instance.windowWidth,
      'windowHeight': instance.windowHeight,
      'isMaximized': instance.isMaximized,
      'isMinimized': instance.isMinimized,
      'defaultTool': _$TriOSToolsEnumMap[instance.defaultTool],
    };

const _$TriOSToolsEnumMap = {
  TriOSTools.vramEstimator: 'vramEstimator',
  TriOSTools.chipper: 'chipper',
};
