import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';

import '../../mod_manager/homebrew_grid/wisp_grid_state.dart';
import '../../mod_manager/mods_grid_state.dart';
import '../../models/launch_settings.dart';
import '../../utils/dart_mappable_utils.dart';

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

  // Window State
  final double? windowXPos;
  final double? windowYPos;
  final double? windowWidth;
  final double? windowHeight;
  final bool? isMaximized;
  final bool? isMinimized;
  final TriOSTools? defaultTool;

  final String? lastActiveJreVersion;
  final bool showCustomJreConsoleWindow;
  final String? themeKey;
  final bool? showChangelogNextLaunch;

  /// If true, TriOS acts as the launcher. If false, basically just clicks game exe.
  final bool enableDirectLaunch;
  final LaunchSettings launchSettings;
  final String? lastStarsectorVersion;
  final bool isUpdatesFieldShown;
  @MappableField(hook: SafeDecodeHook())
  final WispGridState modsGridState;
  final ModsGridState? oldModsGridState;

  // Mods Page
  final bool doubleClickForModsPanel;

  // Settings Page
  @Deprecated("Bad idea, can get stuck in crash -> downgrade -> auto-update -> crash loop.")
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
  final bool checkIfGameIsRunning;

  @Deprecated("Use getSentryUserId instead.")
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
    this.lastActiveJreVersion,
    this.showCustomJreConsoleWindow = true,
    this.themeKey,
    this.showChangelogNextLaunch,
    this.enableDirectLaunch = false,
    this.launchSettings = const LaunchSettings(),
    this.lastStarsectorVersion,
    this.isUpdatesFieldShown = true,
    this.modsGridState = const WispGridState(
        groupingSetting:
            GroupingSetting(grouping: ModGridGroupEnum.enabledState)),
    this.oldModsGridState,
    this.doubleClickForModsPanel = true,
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
    this.checkIfGameIsRunning = true,
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
    settingsManager.scheduleWriteSettingsToDisk(newState);
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
  String get fileName => "trios_settings-v1.${fileFormat.name}";

  @override
  Settings Function(Map<String, dynamic> map) get fromMap =>
      (map) => SettingsMapper.fromMap(map);

  // @override
  // void loadSync() {
  //   super.loadSync();
  //
  //   _migrateFromV1();
  // }

  // void _migrateFromV1() {
  //   final sharedPrefsFile = Constants.configDataFolderPath.resolve("shared_preferences.json").toFile();
  //
  //   if (!sharedPrefsFile.existsSync()) {
  //     return;
  //   }
  //
  //   Fimber.i("Migrating from old shared prefs.");
  //   final sharedPrefs = sharedPrefsFile.readAsStringSync();
  //   final oldPrefs = SettingsMapper.fromJson(sharedPrefs);
  //   Fimber.i("Old prefs: $oldPrefs");
  // }

  @override
  Map<String, dynamic> Function(Settings settings) get toMap =>
      (settings) => settings.toMap();
}
