import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../utils/logging.dart';

/// A class to manage configuration settings stored in a JSON file.
class ConfigManager {
  late String _filePath;
  late Map<String, dynamic> _config;

  /// Creates an instance of [ConfigManager] with the specified [fileName].
  ///
  /// Initializes the configuration in-memory copy and sets the default file path
  /// based on the operating system.
  ConfigManager(String fileName) {
    _config = {}; // Initialize _config with an empty map
    _setDefaultPath(fileName);
  }

  /// Sets the default file path for the configuration file based on the operating system.
  ///
  /// [fileName] is the name of the configuration file.
  void _setDefaultPath(String fileName) {
    String executablePath = path.dirname(Platform.resolvedExecutable);

    if (Platform.isMacOS) {
      _filePath = path.join(executablePath, '..', 'Resources', fileName);
    } else if (Platform.isWindows) {
      _filePath = path.join(executablePath, fileName);
    } else if (Platform.isLinux) {
      _filePath = path.join(executablePath, fileName);
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  /// Reads the configuration file asynchronously and updates the in-memory configuration.
  ///
  /// If the file does not exist, the in-memory configuration remains unchanged.
  Future<void> readConfig() async {
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        _config = jsonDecode(contents);
      }
    } catch (e) {
      Fimber.i("Error reading config file: $e");
    }
  }

  /// Writes the in-memory configuration to the file asynchronously.
  Future<void> writeConfig() async {
    try {
      final file = File(_filePath);
      final contents = jsonEncode(_config);
      await file.writeAsString(contents);
    } catch (e) {
      Fimber.i("Error writing config file: $e");
    }
  }

  /// Updates a specific key in the configuration and saves the change to the disk.
  ///
  /// [key] is the key to update in the configuration.
  /// [value] is the new value to set for the specified key.
  Future<void> updateConfig(String key, dynamic value, {bool flushToDisk = true}) async {
    _config[key] = value;
    if (flushToDisk) {
      await writeConfig();
    }
  }

  /// Replaces the entire configuration with a new one and saves the change to the disk.
  ///
  /// [newConfig] is the new configuration to replace the current one.
  Future<void> setConfig(Map<String, dynamic> newConfig) async {
    _config = newConfig;
    await writeConfig();
  }

  /// Returns an unmodifiable view of the in-memory configuration.
  ///
  /// This ensures that the original configuration cannot be modified directly.
  Map<String, dynamic> get config => Map.unmodifiable(_config);

  late final file = File(_filePath);
}
