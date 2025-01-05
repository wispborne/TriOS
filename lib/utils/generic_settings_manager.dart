import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import "package:msgpack_dart/msgpack_dart.dart" as m2;
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;
import 'package:toml/toml.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

/// Supported file formats for the settings file.
enum FileFormat { toml, json, msgpack }

final Duration _debounceDuration = Duration(milliseconds: 300);

/// A generic class for managing settings stored in TOML or JSON files.
/// This class can be used independently of Riverpod.
abstract class GenericAsyncSettingsManager<T> {
  File settingsFile = File("");
  final _mutex = Mutex();

  /// The current state of the settings.
  T? state;

  /// Specifies the file format for the settings file.
  FileFormat get fileFormat;

  /// Subclasses must provide a factory for default state creation.
  T Function() get createDefaultState;

  /// Subclasses must provide a function to serialize the settings to a map.
  Map<String, dynamic> Function(T obj) get toMap;

  /// Subclasses must provide a function to deserialize a map into the settings object.
  T Function(Map<String, dynamic> map) get fromMap;

  GenericAsyncSettingsManager() {
    state = createDefaultState();
  }

  /// Override to do custom serialization
  Future<Uint8List> serialize(T obj) async {
    if (fileFormat == FileFormat.toml) {
      return utf8.encode(
          TomlDocument.fromMap(toMap(obj).removeNullValues()).toString());
    } else if (fileFormat == FileFormat.msgpack) {
      return m2.serialize(toMap(obj));
    } else {
      return utf8.encode(toMap(obj).prettyPrintJson());
    }
  }

  /// Override to do custom deserialization
  Future<T> deserialize(Uint8List contents) async {
    if (fileFormat == FileFormat.toml) {
      return fromMap(TomlDocument.parse(utf8.decode(contents)).toMap());
    } else if (fileFormat == FileFormat.msgpack) {
      return fromMap(
          (m2.deserialize(contents) as Map<dynamic, dynamic>).cast());
    } else {
      return fromMap(jsonDecode(utf8.decode(contents)) as Map<String, dynamic>);
    }
  }

  /// The name of the file where settings will be stored.
  String get fileName;

  /// Resolves the path for the settings file and ensures the directory exists.
  Future<File> _getFile() async {
    final dir = await getConfigDataFolderPath();
    await dir.create(recursive: true);
    final path = p.join(dir.path, fileName);
    Fimber.i("Settings file path resolved: $path");
    return File(path);
  }

  /// Implement this method to provide the configuration data folder path.
  Future<Directory> getConfigDataFolderPath() =>
      Future.value(Constants.configDataFolderPath);

  /// Initializes and loads the state from the settings file (TOML or JSON),
  /// or uses the default state if the file is missing or invalid.
  Future<T> readSettingsFromDisk() async {
    settingsFile = await _getFile();

    return await _mutex.protect(() async {
      if (await settingsFile.exists()) {
        try {
          final contents = await settingsFile.readAsBytes();
          final loadedState = await deserialize(contents);
          Fimber.i("$fileName successfully loaded from disk.");
          state = loadedState;
          return state!;
        } catch (e, stacktrace) {
          Fimber.e(
              "Error reading from disk, creating backup and then wiping: $e",
              ex: e,
              stacktrace: stacktrace);
          await _createBackup();
          await writeSettingsToDisk(createDefaultState());
          state = createDefaultState();
          return state!;
        }
      } else {
        Fimber.i("$fileName does not exist, creating default state.");
        state = createDefaultState();
        await writeSettingsToDisk(state!);
        return state!;
      }
    });
  }

  // Debouncing variables
  Timer? _debounceTimer;
  Completer<void>? _writeCompleter;

  /// Schedules a write operation to disk.
  Future<void> scheduleWriteSettingsToDisk() {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Create a new completer if none exists or the previous one is completed
    if (_writeCompleter == null || _writeCompleter!.isCompleted) {
      _writeCompleter = Completer<void>();
    }

    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        await writeSettingsToDisk(state!);
        _writeCompleter?.complete();
      } catch (e, stackTrace) {
        Fimber.e("Error serializing and saving settings data to $fileName: $e",
            ex: e, stacktrace: stackTrace);
        _writeCompleter?.completeError(e, stackTrace);
        rethrow;
      } finally {
        _writeCompleter = null;
      }
    });

    return _writeCompleter!.future;
  }

  Future<void> writeSettingsToDisk(T currentState) async {
    final serializedData = await serialize(currentState);
    await settingsFile.writeAsBytes(serializedData);
    Fimber.i("$fileName successfully written to disk.");
  }

  /// Updates the current state using the provided mutator function and persists the updated state to disk.
  /// You probably you want to use the [update] in a [GenericSettingsAsyncNotifier] instead.
  Future<T> update(
    FutureOr<T> Function(T currentState) mutator, {
    FutureOr<T> Function(Object, StackTrace)? onError,
  }) async {
    return await _mutex.protect(() async {
      final oldState = state!;
      try {
        final newState = await mutator(oldState);

        if (newState.hashCode != oldState.hashCode) {
          state = newState;
          Fimber.i("$fileName updated, writing to disk...");
          scheduleWriteSettingsToDisk();
        } else {
          Fimber.d("No $fileName settings change detected.");
        }

        return state!;
      } catch (e, stacktrace) {
        if (onError != null) {
          return await onError(e, stacktrace);
        } else {
          Fimber.e("Error during $fileName update: $e",
              ex: e, stacktrace: stacktrace);
          rethrow;
        }
      }
    });
  }

  /// Creates a backup of the current settings file with a `.bak` extension.
  Future<void> _createBackup() async {
    File backupFile;
    final backupFileName = "${fileName}_backup.bak";
    backupFile = File(p.join(settingsFile.parent.path, backupFileName));

    await settingsFile.copy(backupFile.path);
    Fimber.i("Backup of $fileName created at ${backupFile.path}");
  }
}

/// A simple synchronous lock for thread safety.
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