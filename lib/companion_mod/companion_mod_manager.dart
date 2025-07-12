import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';

/// Provider for the CompanionModManager
final companionModManagerProvider = Provider<CompanionModManager>(
  (ref) => CompanionModManager(ref),
);

class CompanionModManager {
  static String assetsModPath =
      '${getAssetsPath()}/common/${Constants.companionModFolderName}';

  final Ref ref;

  CompanionModManager(this.ref);

  /// Copies the TriOS companion mod from assets to the game's mods folder
  /// and updates the game version in mod_info.json
  Future<void> copyModToGameFolder({bool enableMod = true}) async {
    try {
      // Get the mods folder path using Riverpod
      final modsFolder = ref.read(AppState.modsFolder).valueOrNull;
      if (modsFolder == null) {
        throw StateError('Game mods folder not configured');
      }

      // Get the current game version using Riverpod
      final gameVersion = await ref.read(AppState.starsectorVersion.future);
      if (gameVersion == null) {
        throw StateError('Game version not available');
      }

      // Create destination directory
      final destinationPath = Directory(
        p.join(modsFolder.path, Constants.companionModFolderName),
      );

      // Delete if exists
      if (await destinationPath.exists()) {
        await destinationPath.delete(recursive: true);
      }

      await destinationPath.create(recursive: true);

      // Copy mod files from assets
      await _copyModFiles(destinationPath);

      // Update mod_info.json with current game version
      await _updateModInfo(destinationPath, gameVersion);

      Fimber.i(
        'TriOS companion mod copied successfully to ${destinationPath.path}',
      );

      if (enableMod) {
        final mod = ref
            .read(AppState.mods)
            .firstWhereOrNull((mod) => mod.id == Constants.companionModId);
        if (mod != null) {
          ref
              .read(modManager.notifier)
              .changeActiveModVariant(mod, mod.findHighestVersion);
        } else {
          Fimber.w('TriOS companion mod not found in mods list');
        }
      }
    } catch (e, stackTrace) {
      Fimber.w(
        'Failed to copy companion mod: $e',
        ex: e,
        stacktrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Alternative method that allows specifying a custom mod folder name
  Future<void> copyModToGameFolderWithName(String modFolderName) async {
    try {
      // Get the mods folder path using Riverpod
      final modsFolder = ref.read(AppState.modsFolder).valueOrNull;
      if (modsFolder == null) {
        throw StateError('Game mods folder not configured');
      }

      // Get the current game version using Riverpod
      final gameVersion = await ref.read(AppState.starsectorVersion.future);
      if (gameVersion == null) {
        throw StateError('Game version not available');
      }

      // Create destination directory with custom name
      final destinationPath = Directory(p.join(modsFolder.path, modFolderName));
      await destinationPath.create(recursive: true);

      // Copy mod files from assets
      await _copyModFiles(destinationPath);

      // Update mod_info.json with current game version
      await _updateModInfo(destinationPath, gameVersion);

      Fimber.i(
        'TriOS companion mod copied successfully to ${destinationPath.path}',
      );
    } catch (e, stackTrace) {
      Fimber.e(
        'Failed to copy companion mod: $e',
        ex: e,
        stacktrace: stackTrace,
      );
      rethrow;
    }
  }

  Mod? getLoadedCompanionMod() {
    return ref
        .read(AppState.mods)
        .firstWhereOrNull((mod) => mod.id == Constants.companionModId);
  }

  /// Copies all files from the assets mod folder to the destination
  Future<void> _copyModFiles(Directory destination) async {
    // In Flutter, assets are embedded in the app bundle and accessed differently
    // We'll need to read from the bundle and write to the destination

    // For now, we'll assume the mod files are available as individual assets
    // You may need to adjust this based on your actual asset structure
    final assetFiles = await _getAssetFiles();

    for (final assetFile in assetFiles) {
      final relativePath = p.relative(assetFile.path, from: assetsModPath);
      final destinationFile = File(p.join(destination.path, relativePath));

      // Ensure parent directory exists
      await destinationFile.parent.create(recursive: true);

      // Copy the file
      await assetFile.copy(destinationFile.path);
    }
  }

  /// Gets the list of asset files to copy
  /// This is a simplified version - you may need to adjust based on your asset structure
  Future<List<File>> _getAssetFiles() async {
    return assetsModPath
        .toDirectory()
        .list(recursive: true)
        .whereType<File>()
        .toList();
  }

  /// Updates the mod_info.json file with the current game version
  Future<void> _updateModInfo(Directory modFolder, String gameVersion) async {
    final modInfoFile = File(
      p.join(modFolder.path, Constants.unbrickedModInfoFileName),
    );

    if (!await modInfoFile.exists()) {
      throw FileSystemException('mod_info.json not found', modInfoFile.path);
    }

    try {
      // Read the current mod_info.json
      final jsonString = await modInfoFile.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Update the gameVersion key
      jsonData['gameVersion'] = gameVersion;

      // Write back to file with pretty formatting
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(jsonData);
      await modInfoFile.writeAsString(prettyJson);

      Fimber.i('Updated mod_info.json with game version: $gameVersion');
    } catch (e) {
      throw FormatException('Failed to update mod_info.json: $e');
    }
  }

  /// Gets the path to the trios_image_replacements.json config file
  Future<File> _getImageReplacementsConfigFile() async {
    final modsFolder = ref.read(AppState.modsFolder).valueOrNull;
    if (modsFolder == null) {
      throw StateError('Game mods folder not configured');
    }

    final companionModPath = Directory(
      p.join(modsFolder.path, Constants.companionModFolderName),
    );

    if (!await companionModPath.exists()) {
      throw StateError(
        'TriOS companion mod not found. Please copy the mod first.',
      );
    }

    // Create the config directory if it doesn't exist
    final configDir = Directory(
      p.join(companionModPath.path, 'data', 'config'),
    );
    await configDir.create(recursive: true);

    return File(p.join(configDir.path, 'trios_image_replacements.json'));
  }

  /// Safely reads existing image replacements from the config file
  /// Returns an empty map if the file doesn't exist or is invalid
  Future<Map<String, String>> _readExistingReplacements() async {
    try {
      final configFile = await _getImageReplacementsConfigFile();

      if (!await configFile.exists()) {
        return {};
      }

      final jsonString = await configFile.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final replacementsList = jsonData['replacements'] as List<dynamic>?;

      if (replacementsList == null) {
        return {};
      }

      final Map<String, String> existingReplacements = {};
      for (final item in replacementsList) {
        if (item is Map<String, dynamic>) {
          final original = item['original'] as String?;
          final replacement = item['replacement'] as String?;
          if (original != null && replacement != null) {
            existingReplacements[original] = replacement;
          }
        }
      }

      return existingReplacements;
    } catch (e) {
      Fimber.w('Error reading existing replacements config: $e');
      return {};
    }
  }

  /// Writes the replacements map to the config file with proper JSON formatting
  Future<void> _writeReplacementsToFile(
    File configFile,
    Map<String, String> replacements,
  ) async {
    // Convert replacements map to the expected JSON structure
    final List<Map<String, String>> replacementsList = replacements.entries
        .map((entry) => {
              'original': entry.key,
              'replacement': entry.value,
            })
        .toList();

    final jsonData = {
      'replacements': replacementsList,
    };

    // Write the JSON file with pretty formatting
    const encoder = JsonEncoder.withIndent('  ');
    final prettyJson = encoder.convert(jsonData);
    await configFile.writeAsString(prettyJson);
  }

  /// Updates the trios_image_replacements.json file in the companion mod
  /// with the provided portrait replacement mappings
  Future<void> updateImageReplacementsConfig(
    Map<String, String> replacements,
  ) async {
    try {
      final configFile = await _getImageReplacementsConfigFile();
      await _writeReplacementsToFile(configFile, replacements);

      Fimber.i(
        'Updated trios_image_replacements.json with ${replacements.length} replacements',
      );
    } catch (e, stackTrace) {
      Fimber.e(
        'Failed to update image replacements config: $e',
        ex: e,
        stacktrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Updates the image replacements config using portrait hash to file path mappings
  /// This method converts portrait hashes to actual file paths for the JSON config
  Future<void> updateImageReplacementsFromHashMap(
    Map<String, String> hashToPathReplacements,
    Map<String, Portrait> hashToPortrait,
  ) async {
    try {
      // Convert hash-based replacements to path-based replacements
      final Map<String, String> pathReplacements = {};

      for (final entry in hashToPathReplacements.entries) {
        final originalHash = entry.key;
        final replacementPath = entry.value;

        // Find the original portrait by hash
        final originalPortrait = hashToPortrait[originalHash];
        if (originalPortrait == null) {
          Fimber.w('Original portrait not found for hash: $originalHash');
          continue;
        }

        // Use the original portrait's file path as the key
        pathReplacements[originalPortrait.imageFile.path] = replacementPath;
      }

      // Update the config file with path-based replacements
      await updateImageReplacementsConfig(pathReplacements);

      Fimber.i(
        'Converted ${hashToPathReplacements.length} hash-based replacements to ${pathReplacements.length} path-based replacements',
      );
    } catch (e, stackTrace) {
      Fimber.e(
        'Failed to update image replacements from hash map: $e',
        ex: e,
        stacktrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Clears all image replacements from the config file
  Future<void> clearImageReplacementsConfig() async {
    await updateImageReplacementsConfig({});
  }

  /// Adds a single image replacement to the existing config
  Future<void> addImageReplacement(String originalPath, String replacementPath) async {
    try {
      final existingReplacements = await _readExistingReplacements();
      existingReplacements[originalPath] = replacementPath;

      final configFile = await _getImageReplacementsConfigFile();
      await _writeReplacementsToFile(configFile, existingReplacements);

      Fimber.i('Added image replacement: $originalPath -> $replacementPath');
    } catch (e, stackTrace) {
      Fimber.e(
        'Failed to add image replacement: $e',
        ex: e,
        stacktrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Removes a single image replacement from the existing config
  Future<void> removeImageReplacement(String originalPath) async {
    try {
      final existingReplacements = await _readExistingReplacements();
      final removed = existingReplacements.remove(originalPath);

      if (removed != null) {
        final configFile = await _getImageReplacementsConfigFile();
        await _writeReplacementsToFile(configFile, existingReplacements);
        Fimber.i('Removed image replacement: $originalPath');
      } else {
        Fimber.w('Image replacement not found: $originalPath');
      }
    } catch (e, stackTrace) {
      Fimber.e(
        'Failed to remove image replacement: $e',
        ex: e,
        stacktrace: stackTrace,
      );
      rethrow;
    }
  }
}