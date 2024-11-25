import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:toml/toml.dart';
import 'package:trios/utils/extensions.dart';

import '../trios/constants.dart';
import 'logging.dart';

/// A generic class for managing settings stored in TOML or JSON files.
///
/// This class handles serialization and deserialization of settings objects,
/// and provides mechanisms for thread-safe updates and automatic persistence
/// to disk.
abstract class GenericSettingsNotifier<T> extends AsyncNotifier<T> {
  late File settingsFile;
  late String _fileName;
  final _mutex = Mutex();

  /// Specifies the file format for the settings file.
  /// Must be overridden in subclasses to return either `FileFormat.toml` or `FileFormat.json`.
  FileFormat get fileFormat;

  /// Subclasses must provide a factory for default state creation.
  T Function() get createDefaultState;

  /// Subclasses must provide a function to serialize the settings to a map.
  Map<String, dynamic> Function(T) get toMap;

  /// Subclasses must provide a function to deserialize a map into the settings object.
  T Function(Map<String, dynamic>) get fromMap;

  /// The name of the file where settings will be stored.
  String get fileName;

  /// Initializes and loads the state from the settings file (TOML or JSON),
  /// or uses the default state if the file is missing or invalid.
  @override
  Future<T> build() async {
    _fileName = fileName;
    settingsFile = await _getFile();

    return await _mutex.protect(() async {
      if (await settingsFile.exists()) {
        try {
          final contents = await settingsFile.readAsString();
          final loadedState = fileFormat == FileFormat.toml
              ? fromMap(TomlDocument.parse(contents).toMap())
              : fromMap(jsonDecode(contents) as Map<String, dynamic>);
          Fimber.i("State successfully loaded from disk.");
          return loadedState;
        } catch (e, stacktrace) {
          Fimber.e("Error reading from disk, creating backup: $e",
              ex: e, stacktrace: stacktrace);
          await _createBackup();
          return createDefaultState();
        }
      } else {
        Fimber.i("File does not exist, creating default state.");
        await writeSettingsToDisk(createDefaultState());
        return createDefaultState();
      }
    });
  }

  /// Updates the current state using the provided mutator function and persists the updated state to disk.
  ///
  /// The `mutator` function modifies the current state, and the updated state is saved if changes are detected.
  /// If an error occurs during the update, the optional `onError` callback is invoked.
  @override
  Future<T> update(
    FutureOr<T> Function(T currentState) mutator, {
    FutureOr<T> Function(Object, StackTrace)? onError,
  }) async {
    final oldState = state.asData?.value;
    if (oldState == null) {
      throw StateError('Cannot update because the current state is null.');
    }

    try {
      final newState = await mutator(oldState);

      if (newState != oldState) {
        state = AsyncData(newState); // Notify listeners
        Fimber.i("State updated, writing to disk...");

        await _mutex.protect(() async {
          await writeSettingsToDisk(newState);
          Fimber.i("State successfully written to disk.");
        });
      }

      return newState;
    } catch (e, stacktrace) {
      if (onError != null) {
        return await onError(e, stacktrace);
      } else {
        Fimber.e("Error during update: $e", ex: e, stacktrace: stacktrace);
        state = AsyncError(e, stacktrace);
        rethrow;
      }
    }
  }

  /// Writes the provided state to the settings file (TOML or JSON) on disk.
  Future<void> writeSettingsToDisk(T currentState) async {
    try {
      final serializedData = fileFormat == FileFormat.toml
          ? TomlDocument.fromMap(toMap(currentState)).toString()
          : jsonEncode(toMap(currentState));
      await settingsFile.writeAsString(serializedData);
    } catch (e, stackTrace) {
      Fimber.e("Error serializing and saving settings data: $e",
          ex: e, stacktrace: stackTrace);
      rethrow;
    }
  }

  /// Creates a backup of the current settings file with a `.bak` extension.
  Future<void> _createBackup() async {
    int backupNumber = 1;
    File backupFile;
    do {
      backupFile = settingsFile.parent
          .resolve("${_fileName}_backup_$backupNumber.bak")
          .toFile();
      backupNumber++;
    } while (await backupFile.exists());

    await settingsFile.copy(backupFile.path);
    Fimber.i("Backup created at ${backupFile.path}");
  }

  /// Resolves the path for the settings file and ensures the directory exists.
  Future<File> _getFile() async {
    final dir = await configDataFolderPath;
    await dir.create(recursive: true);
    final path = dir.resolve(_fileName).path;
    Fimber.i("File path resolved: $path");
    return File(path);
  }
}

/// Supported file formats for the settings file.
enum FileFormat { toml, json }
