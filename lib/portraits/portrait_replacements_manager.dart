import 'dart:io';

import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/logging.dart';

/// Manages persistent storage of portrait replacements
class PortraitReplacementsManager extends GenericAsyncSettingsManager<Map<String, String>> {
  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => 'portrait_replacements.json';

  @override
  Map<String, dynamic> Function(Map<String, String> obj) get toMap => 
    (obj) => obj.cast<String, dynamic>();

  @override
  Map<String, String> Function(Map<String, dynamic> map) get fromMap => 
    (map) => map.cast<String, String>();

  /// Loads portrait replacements from disk
  Future<Map<String, String>> loadReplacements() async {
    try {
      return await readSettingsFromDisk({});
    } catch (e) {
      Fimber.e('Error loading portrait replacements: $e');
      return {};
    }
  }

  /// Saves a portrait replacement mapping
  Future<void> saveReplacement(String originalHash, String replacementPath) async {
    try {
      final replacements = await loadReplacements();
      replacements[originalHash] = replacementPath;
      await scheduleWriteSettingsToDisk(replacements);
      Fimber.i('Portrait replacement saved: $originalHash -> $replacementPath');
    } catch (e) {
      Fimber.e('Error saving portrait replacement: $e');
    }
  }

  /// Removes a portrait replacement mapping
  Future<void> removeReplacement(String originalHash) async {
    try {
      final replacements = await loadReplacements();
      replacements.remove(originalHash);
      await scheduleWriteSettingsToDisk(replacements);
      Fimber.i('Portrait replacement removed: $originalHash');
    } catch (e) {
      Fimber.e('Error removing portrait replacement: $e');
    }
  }

  /// Gets replacement path for a portrait hash, cleaning up dead references
  Future<String?> getReplacement(String portraitHash) async {
    try {
      final replacements = await loadReplacements();
      final replacementPath = replacements[portraitHash];
      
      if (replacementPath != null) {
        if (await File(replacementPath).exists()) {
          return replacementPath;
        } else {
          // Clean up dead reference
          await removeReplacement(portraitHash);
        }
      }
      
      return null;
    } catch (e) {
      Fimber.e('Error getting portrait replacement: $e');
      return null;
    }
  }
}