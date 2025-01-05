import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:toml/toml.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/map_diff.dart';
import 'package:trios/utils/util.dart';

import '../../mod_manager/homebrew_grid/wisp_grid_state.dart';
import '../../mod_manager/mods_grid_state.dart';
import '../../models/launch_settings.dart';
import '../../utils/dart_mappable_utils.dart';

part 'settings.mapper.dart';

const sharedPrefsSettingsKey = "settings";

/// Settings State Provider
final appSettings =
    NotifierProvider<AppSettingNotifier, Settings>(() => AppSettingNotifier());

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
  @Deprecated(
      "Bad idea, can get stuck in crash -> downgrade -> auto-update -> crash loop.")
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

/// Manages loading, storing, and updating the app's [Settings] while keeping the UI reactive.
/// It uses a debounced write strategy to minimize frequent disk writes.
class AppSettingNotifier extends Notifier<Settings> {
  final Duration _debounceDuration = Duration(milliseconds: 300);
  Timer? _debounceTimer;
  bool _isInitialized = false;

  /// Performs synchronous file I/O for [Settings].
  final SettingsFileManager _fileManager = SettingsFileManager();

  @override
  Settings build() {
    if (!_isInitialized) {
      try {
        final loadedState = _fileManager.loadSync();
        // If the file is missing or unreadable, create a default Settings instance.
        if (loadedState != null) {
          state = loadedState;
        } else {
          state = Settings();
          _fileManager.writeSync(state!);
        }
        _isInitialized = true;
      } catch (e, stackTrace) {
        Fimber.w("Error building settings notifier",
            ex: e, stacktrace: stackTrace);
        rethrow;
      }
    }

    final settings = state!;
    configureLogging(
        allowSentryReporting: settings.allowCrashReporting ?? false);
    return _applyDefaultsIfNeeded(settings);
  }

  /// Queues a settings write operation for [newSettings]. Waits [_debounceDuration] before writing.
  void _scheduleWriteSettings(Settings newSettings) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _fileManager.writeSync(newSettings);
    });
  }

  /// Updates [Settings] in memory by applying [mutator], optionally handling errors,
  /// and triggers a debounced disk write if changes occur.
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

    newState = _recalculatePathsIfNeeded(prevState, newState);
    state = newState;
    Fimber.i("Settings updated: ${prevState.toMap().diff(newState.toMap())}");
    _scheduleWriteSettings(newState);
    return newState;
  }

  /// Adds defaults if critical fields are missing and schedules a disk write if anything changes.
  Settings _applyDefaultsIfNeeded(Settings settings) {
    var updated = settings;
    var changed = false;

    if (updated.gameDir == null || updated.gameDir.toString().isEmpty) {
      updated = updated.copyWith(gameDir: defaultGamePath());
      changed = true;
    }

    final recalc = _recalculatePathsIfNeeded(settings, updated);
    if (recalc != updated) {
      updated = recalc;
      changed = true;
    }

    if (changed) {
      _scheduleWriteSettings(updated);
    }
    return updated;
  }

  /// Adjusts mod-related paths if the [gameDir] changes.
  /// No immediate disk write—this is deferred to a later step.
  Settings _recalculatePathsIfNeeded(Settings prevState, Settings newState) {
    var updated = newState;

    if (updated.gameDir != null && updated.gameDir != prevState.gameDir) {
      if (!updated.hasCustomModsDir) {
        final newModsDir = generateModsFolderPath(updated.gameDir!)?.path;
        updated = updated.copyWith(modsDir: newModsDir?.toDirectory());
      }
      updated = updated.copyWith(
        gameCoreDir: generateGameCorePath(updated.gameDir!),
      );
    }
    return updated;
  }
}

/// Performs synchronous file I/O for [Settings], backing up corrupt or unreadable files.
class SettingsFileManager {
  final SyncLock _lock = SyncLock();
  late final File _settingsFile;

  /// Hardcoded file format and file name.
  final FileFormat _fileFormat = FileFormat.json;
  final String _fileName = 'trios_settings-v1.json';

  /// Singleton instance, if needed.
  static final SettingsFileManager _instance = SettingsFileManager._internal();

  factory SettingsFileManager() => _instance;

  SettingsFileManager._internal() {
    _settingsFile = _getFileSync();
  }

  Directory getConfigDataFolderPathSync() => Constants.configDataFolderPath;

  File _getFileSync() {
    final dir = getConfigDataFolderPathSync();
    dir.createSync(recursive: true);
    final fullPath = p.join(dir.path, _fileName);
    Fimber.i("Settings file path resolved: $fullPath");
    return File(fullPath);
  }

  void _createBackupSync() {
    int backupNumber = 1;
    File backupFile;
    do {
      final backupFileName = "${_fileName}_backup_$backupNumber.bak";
      backupFile = File(p.join(_settingsFile.parent.path, backupFileName));
      backupNumber++;
    } while (backupFile.existsSync());

    _settingsFile.copySync(backupFile.path);
    Fimber.i("Backup of $_fileName created at ${backupFile.path}");
  }

  /// Attempts to load [Settings] from disk, returning `null` on failure.
  Settings? loadSync() {
    return _lock.protectSync(() {
      if (_settingsFile.existsSync()) {
        try {
          final contents = _settingsFile.readAsStringSync();
          final map = (_fileFormat == FileFormat.toml)
              ? TomlDocument.parse(contents).toMap()
              : jsonDecode(contents) as Map<String, dynamic>;
          Fimber.i("$_fileName successfully loaded from disk.");
          return SettingsMapper.fromMap(map);
        } catch (e, stackTrace) {
          Fimber.e("Error reading from disk, creating backup: $e",
              ex: e, stacktrace: stackTrace);
          _createBackupSync();
        }
      }
      return null;
    });
  }

  /// Writes [settings] to the file system, replacing any existing data.
  void writeSync(Settings settings) {
    try {
      _lock.protectSync(() {
        final serializedData = (_fileFormat == FileFormat.toml)
            ? TomlDocument.fromMap(settings.toMap()).toString()
            : settings.toMap().prettyPrintJson();

        _settingsFile.writeAsStringSync(serializedData);
        Fimber.i("$_fileName successfully written to disk.");
      });
    } catch (e, stackTrace) {
      Fimber.e("Error serializing and saving $_fileName: $e",
          ex: e, stacktrace: stackTrace);
      rethrow;
    }
  }
}
