import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trios/utils/extensions.dart';

import '../trios/constants.dart';
import 'logging.dart';

/// Creates a settings file that can notify on changes.
abstract class GenericSettingsNotifier<T> extends AsyncNotifier<T> {
  late String _fileName;
  late File _file;
  final _mutex = Mutex();

  // Subclasses should provide a factory for default state
  T Function() get defaultStateFactory;

  // Subclasses must provide a function for serialization (to JSON)
  dynamic Function(T) get toJson;

  // Subclasses must provide a function for deserialization (from JSON)
  T Function(dynamic) get fromJson;

  // Provide file name during initialization
  String get fileName;

  // This is called when the notifier is first created. It will initialize and load the state.
  @override
  Future<T> build() async {
    _fileName = fileName;
    _file = await _getFile();

    // Use mutex to prevent race conditions during file access
    return await _mutex.protect(() async {
      if (await _file.exists()) {
        try {
          final contents = await _file.readAsString();
          // pls
          final jsonData = jsonDecode(jsonDecode(contents));
          final loadedState = fromJson(jsonData);
          Fimber.i("State successfully loaded from disk.");
          return loadedState;
        } catch (e, stacktrace) {
          Fimber.e("Error reading from disk, creating backup: $e",
              ex: e, stacktrace: stacktrace);
          await _createBackup();
          return defaultStateFactory(); // Return default state if error occurs
        }
      } else {
        Fimber.i("File does not exist, creating default state.");
        await _writeToDisk(defaultStateFactory());
        return defaultStateFactory();
      }
    });
  }

  // Update the state using a mutator function and persist to disk if changed
  @override
  Future<T> update(
    FutureOr<T> Function(T currentState) mutator, {
    FutureOr<T> Function(Object, StackTrace)? onError,
  }) async {
    final oldState = state.asData?.value;
    if (oldState == null) return oldState!;

    try {
      final newState = await mutator(oldState);

      if (newState != oldState) {
        state = AsyncData(newState); // Notify listeners immediately
        Fimber.i("State updated, writing to disk...");

        await _mutex.protect(() async {
          await _writeToDisk(newState);
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

  // Writes the given state to disk as JSON
  Future<void> _writeToDisk(T currentState) async {
    final jsonData = toJson(currentState);
    final jsonString = jsonEncode(jsonData);
    await _file.writeAsString(jsonString);
  }

  // Create a backup of the corrupted file with a numbered .bak extension
  Future<void> _createBackup() async {
    int backupNumber = 1;
    File backupFile;
    do {
      backupFile = _file.parent
          .resolve("${_fileName}_backup_$backupNumber.bak")
          .toFile();
      backupNumber++;
    } while (await backupFile.exists());

    await _file.copy(backupFile.path);
    Fimber.i("Backup created at ${backupFile.path}");
  }

  Future<File> _getFile() async {
    final dir = await configDataFolderPath;
    await dir.create(recursive: true); // Ensure directory exists
    final path = dir.resolve(_fileName).path;
    Fimber.i("File path resolved: $path");
    return File(path);
  }
}
