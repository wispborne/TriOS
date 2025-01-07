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

/// Handles reading/writing settings from/to disk, and schedules those writes.
abstract class GenericAsyncSettingsManager<T> {
  File settingsFile = File("");
  final _mutex = Mutex();
  Timer? _debounceTimer;
  Completer<void>? _writeCompleter;

  /// Specifies the file format for the settings file.
  FileFormat get fileFormat;

  /// Subclasses must provide a function to serialize the settings to a map.
  Map<String, dynamic> Function(T obj) get toMap;

  /// Subclasses must provide a function to deserialize a map into the settings object.
  T Function(Map<String, dynamic> map) get fromMap;

  /// The name of the file where settings will be stored.
  String get fileName;

  /// Implement this method to provide the configuration data folder path.
  Future<Directory> getConfigDataFolderPath() =>
      Future.value(Constants.configDataFolderPath);

  /// Reads settings from disk, or uses the provided fallback state if there's any error.
  Future<T> readSettingsFromDisk(T fallback) async {
    settingsFile = await _getFile();
    if (await settingsFile.exists()) {
      try {
        final contents = await settingsFile.readAsBytes();
        final loadedState = await deserialize(contents);
        Fimber.i("$fileName successfully loaded from disk.");
        return loadedState;
      } catch (e, stacktrace) {
        Fimber.e("Error reading from disk, creating backup and then wiping: $e",
            ex: e, stacktrace: stacktrace);
        await _createBackup();
        await _performWriteSettingsToDisk(fallback);
        return fallback;
      }
    } else {
      Fimber.i("$fileName does not exist, creating default state.");
      await _performWriteSettingsToDisk(fallback);
      return fallback;
    }
  }

  /// Schedules a write operation to disk for the given state.
  Future<void> scheduleWriteSettingsToDisk(T newState) {
    _debounceTimer?.cancel();
    if (_writeCompleter == null || _writeCompleter!.isCompleted) {
      _writeCompleter = Completer<void>();
    }
    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        await _performWriteSettingsToDisk(newState);
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

  /// Performs the actual write to disk.
  Future<void> _performWriteSettingsToDisk(T stateToWrite) async {
    await _mutex.protect(() async {
      final serializedData = await serialize(stateToWrite);
      await settingsFile.writeAsBytes(serializedData);
      Fimber.i("$fileName successfully written to disk.");
    });
  }

  /// Override to do custom serialization
  Future<Uint8List> serialize(T obj) async {
    if (fileFormat == FileFormat.toml) {
      return utf8.encode(
        TomlDocument.fromMap(toMap(obj).removeNullValues()).toString(),
      );
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

  Future<File> _getFile() async {
    final dir = await getConfigDataFolderPath();
    await dir.create(recursive: true);
    final path = p.join(dir.path, fileName);
    Fimber.i("Settings file path resolved: $path");
    return File(path);
  }

  Future<void> _createBackup() async {
    final backupFileName = "${fileName}_backup.bak";
    final backupFile = File(p.join(settingsFile.parent.path, backupFileName));
    await settingsFile.copy(backupFile.path);
    Fimber.i("Backup of $fileName created at ${backupFile.path}");
  }
}
