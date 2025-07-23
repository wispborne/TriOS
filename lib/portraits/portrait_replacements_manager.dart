import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/companion_mod/companion_mod_manager.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/logging.dart';

final portraitReplacementsManager =
    AsyncNotifierProvider<PortraitReplacementsNotifier, Map<String, String>>(
      () => PortraitReplacementsNotifier(),
    );

/// State notifier for portrait replacements
class PortraitReplacementsNotifier extends AsyncNotifier<Map<String, String>> {
  final _PortraitReplacementsStorage _storage = _PortraitReplacementsStorage();

  @override
  Future<Map<String, String>> build() async {
    return await _loadReplacements();
  }

  /// Saves a portrait replacement mapping
  Future<void> saveReplacement(
    String originalHash,
    String replacementPath,
  ) async {
    // state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _saveReplacement(originalHash, replacementPath);
    });
  }

  /// Removes a portrait replacement mapping
  Future<void> removeReplacement(String originalHash) async {
    // state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _removeReplacement(originalHash);
    });
  }

  /// Gets replacement path for a portrait hash
  Future<String?> getReplacement(String portraitHash) async {
    final current = state.valueOrNull ?? {};
    final replacementPath = current[portraitHash];

    if (replacementPath != null) {
      if (await File(replacementPath).exists()) {
        return replacementPath;
      } else {
        // Clean up dead reference
        await removeReplacement(portraitHash);
      }
    }

    return null;
  }

  /// Clears all replacements
  Future<void> clearReplacements() async {
    // state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _clearReplacements();
    });
  }

  /// Syncs replacements to companion mod with portrait mapping
  Future<void> syncToCompanionModWithPortraits(
    Map<String, Portrait> hashToPortrait,
  ) async {
    try {
      final replacements = await _storage.readSettingsFromDisk({});
      final companionModManager = ref.read(companionModManagerProvider);

      await companionModManager.updateImageReplacementsFromHashMap(
        replacements,
        hashToPortrait,
      );
    } catch (e) {
      Fimber.w(
        'Failed to sync replacements to companion mod with portraits: $e',
      );
    }
  }

  /// Internal method to load replacements from storage
  Future<Map<String, String>> _loadReplacements() async {
    try {
      final replacements = await _storage.readSettingsFromDisk({});
      await _syncToCompanionMod(replacements);
      return replacements;
    } catch (e) {
      Fimber.e('Error loading portrait replacements: $e');
      return {};
    }
  }

  /// Internal method to save a replacement
  Future<Map<String, String>> _saveReplacement(
    String originalHash,
    String replacementPath,
  ) async {
    try {
      final replacements = await _storage.readSettingsFromDisk({});
      replacements[originalHash] = replacementPath;
      await _storage.scheduleWriteSettingsToDisk(replacements);
      await _syncToCompanionMod(replacements);

      Fimber.i('Portrait replacement saved: $originalHash -> $replacementPath');
      return replacements;
    } catch (e) {
      Fimber.e('Error saving portrait replacement: $e');
      rethrow;
    }
  }

  /// Internal method to remove a replacement
  Future<Map<String, String>> _removeReplacement(String originalHash) async {
    try {
      final replacements = await _storage.readSettingsFromDisk({});
      replacements.remove(originalHash);
      await _storage.scheduleWriteSettingsToDisk(replacements);
      await _syncToCompanionMod(replacements);

      Fimber.i('Portrait replacement removed: $originalHash');
      return replacements;
    } catch (e) {
      Fimber.e('Error removing portrait replacement: $e');
      rethrow;
    }
  }

  /// Internal method to clear all replacements
  Future<Map<String, String>> _clearReplacements() async {
    try {
      const replacements = <String, String>{};
      await _storage.scheduleWriteSettingsToDisk(replacements);
      await _syncToCompanionMod(replacements);

      Fimber.i('All portrait replacements cleared');
      return replacements;
    } catch (e) {
      Fimber.e('Error clearing portrait replacements: $e');
      rethrow;
    }
  }

  /// Syncs current replacements to the companion mod
  Future<void> _syncToCompanionMod(Map<String, String> replacements) async {
    try {
      final companionModManager = ref.read(companionModManagerProvider);

      // We need to convert hash-based replacements to path-based ones
      // This requires getting the portrait data, which we'll attempt to get from app state
      // For now, we'll use the updateImageReplacementsFromHashMap method if we have portrait data

      // Try to get portrait data from existing providers if available
      // Note: This is a simplified approach - in a real implementation you might need
      // to pass the portrait hash-to-portrait mapping or have it available through state

      // For now, just update with the hash-based replacements as a fallback
      // The companion mod manager will need to handle the conversion
      await companionModManager.updateImageReplacementsConfig(replacements);
    } catch (e) {
      Fimber.w('Failed to sync replacements to companion mod: $e');
      // Don't rethrow as this is a sync operation that shouldn't block the main operation
    }
  }
}

/// Private storage manager for portrait replacements
class _PortraitReplacementsStorage
    extends GenericAsyncSettingsManager<Map<String, String>> {
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
}
