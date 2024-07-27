import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/jre_manager/jre_23.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/enabled_mods.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';

import '../../mod_manager/mods_grid_state.dart';
import '../../models/launch_settings.dart';
import '../app_state.dart';

part '../../generated/trios/settings/settings.freezed.dart';
part '../../generated/trios/settings/settings.g.dart';

const sharedPrefsSettingsKey = "settings";

/// Settings State Provider
final appSettings =
    NotifierProvider<SettingSaver, Settings>(() => SettingSaver());

/// MacOs: /Users/<user>/Library/Preferences/org.wisp.TriOS.plist
Settings? readAppSettings() {
  if (sharedPrefs.containsKey(sharedPrefsSettingsKey)) {
    return Settings.fromJson(
        jsonDecode(sharedPrefs.getString(sharedPrefsSettingsKey)!));
  } else {
    return null;
  }
}

/// Use `appSettings` instead, which updates relevant data. Only use this while app is starting up.
void writeAppSettings(Settings newSettings) {
  sharedPrefs.setString(
      sharedPrefsSettingsKey, jsonEncode(newSettings.toJson()));
}

/// Settings object model
@freezed
class Settings with _$Settings {
  factory Settings({
    @JsonDirectoryConverter() final Directory? gameDir,
    @JsonDirectoryConverter() final Directory? gameCoreDir,
    @JsonDirectoryConverter() final Directory? modsDir,
    @Default(false) final bool hasCustomModsDir,
    @Default(false) final bool shouldAutoUpdateOnLaunch,
    @Default(false) final bool isRulesHotReloadEnabled,
    final double? windowXPos,
    final double? windowYPos,
    final double? windowWidth,
    final double? windowHeight,
    final bool? isMaximized,
    final bool? isMinimized,
    final TriOSTools? defaultTool,
    final String? jre23VmparamsFilename,
    final bool? useJre23,
    @Default(true) final bool showJre23ConsoleWindow,

    /// If true, TriOS acts as the launcher. If false, basically just clicks game exe.
    @Default(true) final bool enableDirectLaunch,
    @Default(LaunchSettings()) final LaunchSettings launchSettings,
    final String? lastStarsectorVersion,
    @Default(15) final int secondsBetweenModFolderChecks,
    @Default(7) final int toastDurationSeconds,
    @Default(true) final bool isUpdatesFieldShown,
    final ModsGridState? modsGridState,
    final bool? allowCrashReporting,
    @Default("") final String userId,

    // Mod profiles are stored in [ModProfilesSettings] and [ModProfileManagerNotifier],
    // in a different shared_prefs key.
    final String? activeModProfileId,
  }) = _Settings;

  factory Settings.fromJson(Map<String, Object?> json) =>
      _$SettingsFromJson(json);
}

/// When settings change, save them to shared prefs
class SettingSaver extends Notifier<Settings> {
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
    Settings? settings;
    try {
      settings = readAppSettings();
    } catch (e) {
      Fimber.e(
          "Error reading settings from shared prefs. Making a backup and resetting to default",
          ex: e);
      final backup = sharedPrefs.getString(sharedPrefsSettingsKey);
      if (backup != null) {
        sharedPrefs.setString("${sharedPrefsSettingsKey}_backup", backup);
      }
    }

    configureLogging(
        allowSentryReporting: settings?.allowCrashReporting ?? false);

    if (settings != null) {
      return _setDefaults(settings);
    } else {
      return _setDefaults(Settings());
    }

    // final gameDir = defaultGamePath()?.absolute;
    // if (gameDir == null) {
    //   return Settings();
    // } else {
    //   return Settings(gameDir: gameDir.path, modsDir: ref.read(modFolderPath)?.path);
    // }
  }

  void update(Settings Function(Settings) update) {
    final prevState = state;
    var newState = update(state);

    if (prevState == newState) {
      Fimber.v("No settings change: $newState");
      return;
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
  }

  Settings _recalculatePathsAndSaveToDisk(
      Settings prevState, Settings newState) {
    // Recalculate mod folder if the game path changes
    if (newState.gameDir != null && newState.gameDir != prevState.gameDir) {
      if (!newState.hasCustomModsDir) {
        var newModsDir = generateModFolderPath(newState.gameDir!)?.path;
        newState = newState.copyWith(modsDir: newModsDir?.toDirectory());
      }

      newState = newState.copyWith(
          gameCoreDir: generateGameCorePath(newState.gameDir!));

      final enabledModsFile = getEnabledModsFile(newState.modsDir!);
      if (enabledModsFile.existsSync() == false) {
        try {
          enabledModsFile.createSync(recursive: true);
          enabledModsFile
              .writeAsStringSync(const EnabledMods({}).toJson().toJsonString());
        } catch (e, stack) {
          Fimber.e(
              "Failed to create enabled mods file at ${enabledModsFile.path}",
              ex: e,
              stacktrace: stack);
        }
      }
    }

    Fimber.d("Updated settings: $newState");

    // Save to shared prefs
    writeAppSettings(newState);
    return newState;
  }
}

class JsonDirectoryConverter implements JsonConverter<Directory?, String?> {
  const JsonDirectoryConverter();

  @override
  Directory? fromJson(String? json) {
    if (json == null) {
      return null;
    } else {
      return json.toDirectory();
    }
  }

  @override
  String? toJson(Directory? object) {
    return object?.path;
  }
}
