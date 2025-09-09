import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/companion_mod/companion_mod_manager.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/thirdparty/dartx/io/file_system_entity.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/logging.dart';

/// State notifier for portrait replacements
/// Key is original portrait hash, value is replacement portrait
class PortraitReplacementsNotifier
    extends AsyncNotifier<Map<String, SavedPortrait>> {
  final _PortraitReplacementsStorage _storage = _PortraitReplacementsStorage();

  @override
  Future<Map<String, SavedPortrait>> build() async {
    return await _loadReplacements();
  }

  /// Saves a portrait replacement mapping
  Future<void> saveReplacement(Portrait original, Portrait replacement) async {
    // state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _saveReplacement(
        original.toSavedPortrait(),
        replacement.toSavedPortrait(),
      );
    });
  }

  /// Removes a portrait replacement mapping
  Future<void> removeReplacement(Portrait original) async {
    // state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _removeReplacement(original.toSavedPortrait());
    });
  }

  /// Gets replacement portrait for a portrait hash
  Future<Portrait?> getReplacementByHash(
    String portraitHash,
    Map<String, Portrait> portraitsByHash,
  ) async {
    final replacement = await _getReplacement(portraitHash);
    return replacement?.toPortrait(portraitsByHash);
  }

  /// Gets replacement portrait for a portrait hash
  /// Note: loads portrait from disk and hashes bytes
  Future<SavedPortrait?> getReplacementByPath(File portraitPath) async {
    final hash = Portrait.hashImagesBytes(await portraitPath.readAsBytes());
    return await _getReplacement(hash);
  }

  /// Gets replacement path for a portrait hash
  Future<SavedPortrait?> _getReplacement(String portraitHash) async {
    final currentState = state.valueOrNull ?? {};
    final replacementPortrait = currentState[portraitHash];

    if (replacementPortrait != null) {
      // if (await File(replacementPortrait).exists()) {
      return replacementPortrait;
      // } else {
      // Clean up dead reference
      // await removeReplacement(portraitHash);
      // }
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
  Future<void> syncToCompanionModWithPortraits() async {
    try {
      final replacements = await _storage.readSettingsFromDisk({});
      final companionModManager = ref.read(companionModManagerProvider);

      await companionModManager.updateImageReplacementsConfig(replacements);
    } catch (e) {
      Fimber.w(
        'Failed to sync replacements to companion mod with portraits: $e',
      );
    }
  }

  /// Internal method to load replacements from storage
  Future<Map<String, SavedPortrait>> _loadReplacements() async {
    try {
      final replacements = await _storage.readSettingsFromDisk({});
      await _syncToCompanionMod(replacements);
      return replacements.toMapWithoutReplacedSavePortrait();
    } catch (e) {
      Fimber.e('Error loading portrait replacements: $e');
      return {};
    }
  }

  /// Internal method to save a replacement
  Future<Map<String, SavedPortrait>> _saveReplacement(
    SavedPortrait original,
    SavedPortrait replacement,
  ) async {
    try {
      final replacements = await _storage.readSettingsFromDisk({});
      replacements[original.hash] = ReplacedSavedPortrait(
        original: original,
        replacement: replacement,
      );
      await _storage.scheduleWriteSettingsToDisk(replacements);
      await _syncToCompanionMod(replacements);

      Fimber.i('Portrait replacement saved: $original -> $replacement');
      return replacements.toMapWithoutReplacedSavePortrait();
    } catch (e) {
      Fimber.e('Error saving portrait replacement: $e');
      rethrow;
    }
  }

  /// Internal method to remove a replacement
  Future<Map<String, SavedPortrait>> _removeReplacement(
    SavedPortrait original,
  ) async {
    try {
      final replacements = await _storage.readSettingsFromDisk({});
      replacements.remove(original.hash);
      await _storage.scheduleWriteSettingsToDisk(replacements);
      await _syncToCompanionMod(replacements);

      Fimber.i(
        'Portrait replacement removed: ${original.relativePath.toFile().name}',
      );
      return replacements.toMapWithoutReplacedSavePortrait();
    } catch (e) {
      Fimber.e('Error removing portrait replacement: $e');
      rethrow;
    }
  }

  /// Internal method to clear all replacements
  Future<Map<String, SavedPortrait>> _clearReplacements() async {
    try {
      const replacements = <String, ReplacedSavedPortrait>{};
      await _storage.scheduleWriteSettingsToDisk(replacements);
      await _syncToCompanionMod(replacements);

      Fimber.i('All portrait replacements cleared');
      return replacements.toMapWithoutReplacedSavePortrait();
    } catch (e) {
      Fimber.e('Error clearing portrait replacements: $e');
      rethrow;
    }
  }

  /// Syncs current replacements to the companion mod
  Future<void> _syncToCompanionMod(
    Map<String, ReplacedSavedPortrait> replacements,
  ) async {
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
    extends GenericAsyncSettingsManager<Map<String, ReplacedSavedPortrait>> {
  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => 'portrait_replacements.json';

  @override
  Map<String, dynamic> Function(Map<String, ReplacedSavedPortrait> obj)
  get toMap =>
      (obj) => obj.map((key, value) => MapEntry(key, value.toMap()));

  @override
  Map<String, ReplacedSavedPortrait> Function(Map<String, dynamic> map)
  get fromMap =>
      (map) => map.map(
        (key, value) =>
            MapEntry(key, ReplacedSavedPortraitMapper.fromMap(value)),
      );
}

extension SavedPortraitExt on Map<String, ReplacedSavedPortrait> {
  Map<String, SavedPortrait> toMapWithoutReplacedSavePortrait() =>
      map((key, value) => MapEntry(key, value.replacement));
}

extension SavedPortraitsMapExt on Map<String, SavedPortrait> {
  Map<String, Portrait?> hydrateToPortraitMap(
    Map<String, Portrait> allPortraits, {
    required bool logWarnings,
  }) => map((hashOfOriginal, replacement) {
    try {
      return MapEntry(hashOfOriginal, allPortraits[replacement.hash]!);
    } catch (ex) {
      if (logWarnings) {
        Fimber.w(
          'Failed to hydrate portrait: $hashOfOriginal (${allPortraits[hashOfOriginal]?.relativePath} to replacement ${replacement.hash} (${replacement.relativePath})'
          '\n\tUnable to find replacement portrait ${replacement.hash} in loaded portraits.',
        );
      }
      return MapEntry(
        hashOfOriginal,
        Portrait( // TODO not sure if this is a good idea, want to display when a portrait cannot be found in the UI
          modVariant: null,
          hash: replacement.hash,
          imageFile: replacement.lastKnownFullPath.toFile(),
          relativePath: replacement.relativePath,
          width: 100,
          height: 100,
        ),
      );
    }
  });

  Map<String, Portrait> hydrateToPortraitMapFromLoaded(
    Map<ModVariant?, List<Portrait>> loadedPortraits,
    bool logWarnings,
  ) => hydrateToPortraitMap(
    loadedPortraits.convertToPortraitMap(),
    logWarnings: logWarnings,
  ).filterValues((value) => value != null).cast<String, Portrait>();
}

extension PortraitMapConversion on Map<ModVariant?, List<Portrait>> {
  Map<String, Portrait> convertToPortraitMap() {
    // Convert the nested portraits map into a flat Map<String, Portrait> where key is hash
    final Map<String, Portrait> allPortraits = {};

    for (final entry in entries) {
      for (final portrait in entry.value) {
        // Store portrait with its hash as the key
        allPortraits[portrait.hash] = portrait;
      }
    }

    return allPortraits;
  }
}
