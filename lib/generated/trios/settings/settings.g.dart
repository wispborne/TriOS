// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../trios/settings/settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsImpl _$$SettingsImplFromJson(Map<String, dynamic> json) =>
    _$SettingsImpl(
      gameDir:
          const JsonDirectoryConverter().fromJson(json['gameDir'] as String?),
      gameCoreDir: const JsonDirectoryConverter()
          .fromJson(json['gameCoreDir'] as String?),
      modsDir:
          const JsonDirectoryConverter().fromJson(json['modsDir'] as String?),
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
      useJre23: json['useJre23'] as bool?,
      launchSettings: json['launchSettings'] == null
          ? const LaunchSettings()
          : LaunchSettings.fromJson(
              json['launchSettings'] as Map<String, dynamic>),
      lastStarsectorVersion: json['lastStarsectorVersion'] as String?,
      secondsBetweenModFolderChecks:
          (json['secondsBetweenModFolderChecks'] as num?)?.toInt() ?? 5,
      isUpdatesFieldShown: json['isUpdatesFieldShown'] as bool? ?? true,
      modsGridState: json['modsGridState'] == null
          ? null
          : ModsGridState.fromJson(
              json['modsGridState'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$SettingsImplToJson(_$SettingsImpl instance) =>
    <String, dynamic>{
      'gameDir': const JsonDirectoryConverter().toJson(instance.gameDir),
      'gameCoreDir':
          const JsonDirectoryConverter().toJson(instance.gameCoreDir),
      'modsDir': const JsonDirectoryConverter().toJson(instance.modsDir),
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
      'lastStarsectorVersion': instance.lastStarsectorVersion,
      'secondsBetweenModFolderChecks': instance.secondsBetweenModFolderChecks,
      'isUpdatesFieldShown': instance.isUpdatesFieldShown,
      'modsGridState': instance.modsGridState,
    };

const _$TriOSToolsEnumMap = {
  TriOSTools.dashboard: 'dashboard',
  TriOSTools.modManager: 'modManager',
  TriOSTools.vramEstimator: 'vramEstimator',
  TriOSTools.chipper: 'chipper',
  TriOSTools.jreManager: 'jreManager',
};
