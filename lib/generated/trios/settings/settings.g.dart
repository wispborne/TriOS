// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../trios/settings/settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsImpl _$$SettingsImplFromJson(Map<String, dynamic> json) =>
    _$SettingsImpl(
      gameDir: json['gameDir'] as String?,
      gameCoreDir: json['gameCoreDir'] as String?,
      modsDir: json['modsDir'] as String?,
      hasCustomModsDir: json['hasCustomModsDir'] as bool? ?? false,
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
      jre23VmparamsFilename: json['jre23VmparamsFilename'] as String?,
      useJre23: json['useJre23'] as bool? ?? true,
      launchSettings: json['launchSettings'] == null
          ? const LaunchSettings()
          : LaunchSettings.fromJson(
              json['launchSettings'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$SettingsImplToJson(_$SettingsImpl instance) =>
    <String, dynamic>{
      'gameDir': instance.gameDir,
      'gameCoreDir': instance.gameCoreDir,
      'modsDir': instance.modsDir,
      'hasCustomModsDir': instance.hasCustomModsDir,
      'shouldAutoUpdateOnLaunch': instance.shouldAutoUpdateOnLaunch,
      'isRulesHotReloadEnabled': instance.isRulesHotReloadEnabled,
      'windowXPos': instance.windowXPos,
      'windowYPos': instance.windowYPos,
      'windowWidth': instance.windowWidth,
      'windowHeight': instance.windowHeight,
      'isMaximized': instance.isMaximized,
      'isMinimized': instance.isMinimized,
      'defaultTool': _$TriOSToolsEnumMap[instance.defaultTool],
      'jre23VmparamsFilename': instance.jre23VmparamsFilename,
      'useJre23': instance.useJre23,
      'launchSettings': instance.launchSettings,
    };

const _$TriOSToolsEnumMap = {
  TriOSTools.dashboard: 'dashboard',
  TriOSTools.vramEstimator: 'vramEstimator',
  TriOSTools.chipper: 'chipper',
  TriOSTools.jreManager: 'jreManager',
};
