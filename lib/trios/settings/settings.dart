import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/jre_manager/jre_23.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';

import '../../mod_manager/mods_grid_state.dart';
import '../../models/launch_settings.dart';

part 'settings.mapper.dart';

const sharedPrefsSettingsKey = "settings";

/// Settings State Provider
final appSettings =
    NotifierProvider<SettingSaver, Settings>(() => SettingSaver());

/// MacOs: /Users/<user>/Library/Preferences/org.wisp.TriOS.plist
// Settings? readAppSettings() {
//   if (sharedPrefs.containsKey(sharedPrefsSettingsKey)) {
//     return SettingsMapper.fromJson(
//         jsonDecode(sharedPrefs.getString(sharedPrefsSettingsKey)!));
//   } else {
//     return null;
//   }
// }
//
// /// Use `appSettings` instead, which updates relevant data. Only use this while app is starting up.
// void writeAppSettings(Settings newSettings) {
//   sharedPrefs.setString(
//       sharedPrefsSettingsKey, jsonEncode(newSettings.toJson()));
// }

/// Settings object model
@MappableClass()
class Settings with SettingsMappable {
  @MappableField(hook: DirectoryHook())
  final Directory? gameDir;
  @MappableField(hook: DirectoryHook())
  final Directory? gameCoreDir;
  @MappableField(hook: DirectoryHook())
  final Directory? modsDir;
  final bool hasCustomModsDir;
  final bool isRulesHotReloadEnabled;
  final double? windowXPos;
  final double? windowYPos;
  final double? windowWidth;
  final double? windowHeight;
  final bool? isMaximized;
  final bool? isMinimized;
  final TriOSTools? defaultTool;
  final String? jre23VmparamsFilename;
  final bool? useJre23;
  final bool showJre23ConsoleWindow;
  final String? themeKey;

  /// If true, TriOS acts as the launcher. If false, basically just clicks game exe.
  final bool enableDirectLaunch;
  final LaunchSettings launchSettings;
  final String? lastStarsectorVersion;
  final bool isUpdatesFieldShown;
  final ModsGridState? modsGridState;

  // Settings Page
  final bool shouldAutoUpdateOnLaunch;
  final int secondsBetweenModFolderChecks;
  final int toastDurationSeconds;
  final int maxHttpRequestsAtOnce;
  final FolderNamingSetting folderNamingSetting;
  final int? keepLastNVersions;
  final bool? allowCrashReporting;
  final bool updateToPrereleases;
  final bool autoEnableAndDisableDependencies;
  final bool enableLauncherPrecheck;
  final ModUpdateBehavior modUpdateBehavior;
  final String userId; // For Sentry
  final bool? hasHiddenForumDarkModeTip;

  // Mod profiles are stored in [ModProfilesSettings] and [ModProfileManagerNotifier],
  // in a different shared_prefs key.
  final String? activeModProfileId;

  Settings({
    this.gameDir,
    this.gameCoreDir,
    this.modsDir,
    this.hasCustomModsDir = false,
    this.isRulesHotReloadEnabled = false,
    this.windowXPos,
    this.windowYPos,
    this.windowWidth,
    this.windowHeight,
    this.isMaximized,
    this.isMinimized,
    this.defaultTool,
    this.jre23VmparamsFilename,
    this.useJre23,
    this.showJre23ConsoleWindow = true,
    this.themeKey,
    this.enableDirectLaunch = false,
    this.launchSettings = const LaunchSettings(),
    this.lastStarsectorVersion,
    this.isUpdatesFieldShown = true,
    this.modsGridState,
    this.shouldAutoUpdateOnLaunch = false,
    this.secondsBetweenModFolderChecks = 15,
    this.toastDurationSeconds = 7,
    this.maxHttpRequestsAtOnce = 20,
    this.folderNamingSetting = FolderNamingSetting.allFoldersVersioned,
    this.keepLastNVersions,
    this.allowCrashReporting,
    this.updateToPrereleases = false,
    this.autoEnableAndDisableDependencies = false,
    this.enableLauncherPrecheck = true,
    this.modUpdateBehavior = ModUpdateBehavior.switchToNewVersionIfWasEnabled,
    this.userId = '',
    this.hasHiddenForumDarkModeTip,
    this.activeModProfileId,
  });
}

@MappableEnum()
enum FolderNamingSetting {
  @MappableValue(0)
  doNotChangeNameForHighestVersion,
  @MappableValue(1)
  allFoldersVersioned,
  @MappableValue(2)
  doNotChangeNamesEver;
}

@MappableEnum()
enum ModUpdateBehavior { doNotChange, switchToNewVersionIfWasEnabled }

/// When settings change, save them to shared prefs
class SettingSaver extends GenericSettingsNotifier<Settings> {
  Settings _setDefaults(Settings settings) {
    var newSettings = settings;

    if (settings.gameDir == null || newSettings.gameDir.toString().isEmpty) {
      newSettings = newSettings.copyWith(gameDir: defaultGamePath());
    }

    final jre23existInGameFolder =
        doesJre23ExistInGameFolder(newSettings.gameDir!);
    if (newSettings.useJre23 == null) {
      newSettings = newSettings.copyWith(useJre23: (jre23existInGameFolder));
    } else {
      // If useJRe23 is set to true, but it doesn't exist, set it to false.
      // Otherwise they might be unable to launch the game or turn off 23.
      if (newSettings.useJre23 == true && !jre23existInGameFolder) {
        newSettings = newSettings.copyWith(useJre23: false);
      }
    }

    // Calculates the default mods folder on first run.
    newSettings = _recalculatePathsAndSaveToDisk(settings, newSettings);
    return newSettings;
  }

  @override
  Settings build() {
    Settings? settings = super.build();

    configureLogging(
        allowSentryReporting: settings.allowCrashReporting ?? false);

    return _setDefaults(settings);
  }

  @override
  Settings update(
    Settings Function(Settings currentState) mutator, {
    Settings Function(Object, StackTrace)? onError,
  }) {
    final prevState = state;
    var newState = mutator(state);

    if (prevState == newState) {
      Fimber.v(() => "No settings change: $newState");
      return newState;
    }

    if (prevState.allowCrashReporting != newState.allowCrashReporting) {
      if (newState.allowCrashReporting ?? false) {
        Fimber.i("Crash reporting enabled.");
        configureLogging(allowSentryReporting: true);
      } else {
        Fimber.i("Crash reporting disabled.");
        configureLogging(allowSentryReporting: false);
      }
    }

    // Recalculate mod folder if the game path changes
    newState = _recalculatePathsAndSaveToDisk(prevState, newState);
    // Update state, triggering rebuilds
    state = newState;
    return newState;
  }

  Settings _recalculatePathsAndSaveToDisk(
      Settings prevState, Settings newState) {
    // Recalculate mod folder if the game path changes
    if (newState.gameDir != null && newState.gameDir != prevState.gameDir) {
      if (!newState.hasCustomModsDir) {
        var newModsDir = generateModsFolderPath(newState.gameDir!)?.path;
        newState = newState.copyWith(modsDir: newModsDir?.toDirectory());
      }

      newState = newState.copyWith(
          gameCoreDir: generateGameCorePath(newState.gameDir!));
    }

    Fimber.d("Updated settings: $newState");

    // Save to disk
    settingsManager.writeSettingsToDiskSync(newState);
    return newState;
  }

  @override
  GenericSettingsManager<Settings> createSettingsManager() =>
      AppSettingsManager();
}

class AppSettingsManager extends GenericSettingsManager<Settings> {
  @override
  Settings Function() get createDefaultState => () => Settings();

  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => "trios_settings.${fileFormat.name}";

  @override
  Settings Function(Map<String, dynamic> map) get fromMap =>
      (map) => SettingsMapper.fromMap(map);

  @override
  Map<String, dynamic> Function(Settings settings) get toMap =>
      (settings) => settings.toMap();
}
