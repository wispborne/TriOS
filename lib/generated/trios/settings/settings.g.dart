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
      showJre23ConsoleWindow: json['showJre23ConsoleWindow'] as bool? ?? true,
      enableDirectLaunch: json['enableDirectLaunch'] as bool? ?? false,
      launchSettings: json['launchSettings'] == null
          ? const LaunchSettings()
          : LaunchSettings.fromJson(
              json['launchSettings'] as Map<String, dynamic>),
      lastStarsectorVersion: json['lastStarsectorVersion'] as String?,
      isUpdatesFieldShown: json['isUpdatesFieldShown'] as bool? ?? true,
      modsGridState: json['modsGridState'] == null
          ? null
          : ModsGridState.fromJson(
              json['modsGridState'] as Map<String, dynamic>),
      shouldAutoUpdateOnLaunch:
          json['shouldAutoUpdateOnLaunch'] as bool? ?? false,
      secondsBetweenModFolderChecks:
          (json['secondsBetweenModFolderChecks'] as num?)?.toInt() ?? 15,
      toastDurationSeconds:
          (json['toastDurationSeconds'] as num?)?.toInt() ?? 7,
      maxHttpRequestsAtOnce:
          (json['maxHttpRequestsAtOnce'] as num?)?.toInt() ?? 20,
      folderNamingSetting: $enumDecodeNullable(
              _$FolderNamingSettingEnumMap, json['folderNamingSetting']) ??
          FolderNamingSetting.doNotChangeNameForHighestVersion,
      keepLastNVersions: (json['keepLastNVersions'] as num?)?.toInt(),
      allowCrashReporting: json['allowCrashReporting'] as bool?,
      updateToPrereleases: json['updateToPrereleases'] as bool? ?? false,
      autoEnableAndDisableDependencies:
          json['autoEnableAndDisableDependencies'] as bool? ?? false,
      enableLauncherPrecheck: json['enableLauncherPrecheck'] as bool? ?? true,
      modUpdateBehavior: $enumDecodeNullable(
              _$ModUpdateBehaviorEnumMap, json['modUpdateBehavior']) ??
          ModUpdateBehavior.switchToNewVersionIfWasEnabled,
      userId: json['userId'] as String? ?? "",
      activeModProfileId: json['activeModProfileId'] as String?,
    );

Map<String, dynamic> _$$SettingsImplToJson(_$SettingsImpl instance) =>
    <String, dynamic>{
      'gameDir': const JsonDirectoryConverter().toJson(instance.gameDir),
      'gameCoreDir':
          const JsonDirectoryConverter().toJson(instance.gameCoreDir),
      'modsDir': const JsonDirectoryConverter().toJson(instance.modsDir),
      'hasCustomModsDir': instance.hasCustomModsDir,
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
      'showJre23ConsoleWindow': instance.showJre23ConsoleWindow,
      'enableDirectLaunch': instance.enableDirectLaunch,
      'launchSettings': instance.launchSettings,
      'lastStarsectorVersion': instance.lastStarsectorVersion,
      'isUpdatesFieldShown': instance.isUpdatesFieldShown,
      'modsGridState': instance.modsGridState,
      'shouldAutoUpdateOnLaunch': instance.shouldAutoUpdateOnLaunch,
      'secondsBetweenModFolderChecks': instance.secondsBetweenModFolderChecks,
      'toastDurationSeconds': instance.toastDurationSeconds,
      'maxHttpRequestsAtOnce': instance.maxHttpRequestsAtOnce,
      'folderNamingSetting':
          _$FolderNamingSettingEnumMap[instance.folderNamingSetting]!,
      'keepLastNVersions': instance.keepLastNVersions,
      'allowCrashReporting': instance.allowCrashReporting,
      'updateToPrereleases': instance.updateToPrereleases,
      'autoEnableAndDisableDependencies':
          instance.autoEnableAndDisableDependencies,
      'enableLauncherPrecheck': instance.enableLauncherPrecheck,
      'modUpdateBehavior':
          _$ModUpdateBehaviorEnumMap[instance.modUpdateBehavior]!,
      'userId': instance.userId,
      'activeModProfileId': instance.activeModProfileId,
    };

const _$TriOSToolsEnumMap = {
  TriOSTools.dashboard: 'dashboard',
  TriOSTools.modManager: 'modManager',
  TriOSTools.modProfiles: 'modProfiles',
  TriOSTools.vramEstimator: 'vramEstimator',
  TriOSTools.chipper: 'chipper',
  TriOSTools.jreManager: 'jreManager',
  TriOSTools.portraits: 'portraits',
  TriOSTools.weapons: 'weapons',
  TriOSTools.settings: 'settings',
};

const _$FolderNamingSettingEnumMap = {
  FolderNamingSetting.doNotChangeNameForHighestVersion:
      'doNotChangeNameForHighestVersion',
  FolderNamingSetting.allFoldersVersioned: 'allFoldersVersioned',
  FolderNamingSetting.doNotChangeNamesEver: 'doNotChangeNamesEver',
};

const _$ModUpdateBehaviorEnumMap = {
  ModUpdateBehavior.doNotChange: 'doNotChange',
  ModUpdateBehavior.switchToNewVersionIfWasEnabled:
      'switchToNewVersionIfWasEnabled',
};
