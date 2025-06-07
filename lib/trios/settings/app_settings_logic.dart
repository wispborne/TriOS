import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:toml/toml.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/map_diff.dart';
import 'package:trios/utils/util.dart';

/// Settings State Provider
final appSettings = NotifierProvider<AppSettingNotifier, Settings>(
  () => AppSettingNotifier(),
);

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
        Fimber.w(
          "Error building settings notifier",
          ex: e,
          stacktrace: stackTrace,
        );
        rethrow;
      }
    }

    final settings = state!;
    configureLogging(
      allowSentryReporting: settings.allowCrashReporting ?? false,
    );
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
          Fimber.e(
            "Error reading from disk, creating backup: $e",
            ex: e,
            stacktrace: stackTrace,
          );
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
      Fimber.e(
        "Error serializing and saving $_fileName: $e",
        ex: e,
        stacktrace: stackTrace,
      );
      rethrow;
    }
  }
}

/// Mutex, but synchronous.
class SyncLock {
  bool _locked = false;

  void lock() {
    if (_locked) {
      throw StateError('Lock is already acquired');
    }
    _locked = true;
  }

  void unlock() {
    if (!_locked) {
      throw StateError('Lock is not acquired');
    }
    _locked = false;
  }

  T protectSync<T>(T Function() action) {
    lock();
    try {
      return action();
    } finally {
      unlock();
    }
  }
}
