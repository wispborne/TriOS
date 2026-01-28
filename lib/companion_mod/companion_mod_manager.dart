import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
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

  Directory? get companionModDefaultFolder {
    final modsFolder = ref.read(AppState.modsFolder).value;
    if (modsFolder == null) {
      return null;
    }
    return Directory(p.join(modsFolder.path, Constants.companionModFolderName));
  }

  /// Replaces mod folder if it already exists.
  Future<void> fullySetUpCompanionMod({
    bool enableMod = true,
    bool includePortraitReplacements = true,
  }) async {
    await copyModToModsFolder();
    final mod = getLoadedCompanionMod();

    if (mod != null && enableMod) {
      await ref
          .read(modManager.notifier)
          .changeActiveModVariant(mod, mod.findHighestVersion);
    }

    if (includePortraitReplacements) {
      await ref
          .read(AppState.portraitReplacementsManager.notifier)
          .syncToCompanionModWithPortraits();
    }
  }

  /// Copies the TriOS companion mod from assets to the game's mods folder
  /// and updates the game version in mod_info.json
  Future<void> copyModToModsFolder({bool overwriteExisting = true}) async {
    try {
      // Get the mods folder path using Riverpod
      final modsFolder = ref.read(AppState.modsFolder).value;
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

      if (!await destinationPath.exists()) {
        await destinationPath.create(recursive: true);
      }

      // Copy mod files from assets
      await _copyModFiles(destinationPath);

      // Update mod_info.json with current game version
      await _updateModInfo(destinationPath, gameVersion);

      Fimber.i(
        'TriOS companion mod copied successfully to ${destinationPath.path}',
      );
    } catch (e, stackTrace) {
      Fimber.w(
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
    final assetFiles = await _getAssetFiles();

    for (final assetFile in assetFiles) {
      final relativePath = p.relative(assetFile.path, from: assetsModPath);
      final destinationFile = File(p.join(destination.path, relativePath));

      // Ensure parent directory exists
      await destinationFile.parent.create(recursive: true);

      // Copy the file
      try {
        if (await assetFile.exists()) {
          await assetFile.delete();
        }

        await assetFile.copy(destinationFile.path);
      } catch (e, st) {
        Fimber.e(
          "Error deleting or copying existing file '${assetFile.path}' when (re)installing Companion Mod.",
          ex: e,
          stacktrace: st,
        );
      }
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
      jsonData['id'] = Constants.companionModId;

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
  Future<File?> _getImageReplacementsConfigFile() async {
    final modsFolder = ref.read(AppState.modsFolder).value;
    if (modsFolder == null) {
      Fimber.i(
        "Game mods folder not configured. Often happens before game folder has been read yet.",
      );
      return null;
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

      if (configFile == null || !await configFile.exists()) {
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
    Map<String, String> replacementPaths,
  ) async {
    // Convert replacements map to the expected JSON structure
    final List<Map<String, String>> replacementsList = replacementPaths.entries
        .map((entry) => {'original': entry.key, 'replacement': entry.value})
        .toList();

    final jsonData = {'replacements': replacementsList};

    // Write the JSON file with pretty formatting
    const encoder = JsonEncoder.withIndent('  ');
    final prettyJson = encoder.convert(jsonData);
    await configFile.writeAsString(prettyJson);
  }

  /// Updates the trios_image_replacements.json file in the companion mod
  /// with the provided portrait replacement mappings
  Future<void> updateImageReplacementsConfig(
    Map<String, ReplacedSavedPortrait> replacements,
  ) async {
    final gameCoreFolder = ref.read(AppState.gameCoreFolder).value;

    if (gameCoreFolder == null) {
      throw StateError('Game core folder not configured');
    }

    final configFile = await _getImageReplacementsConfigFile();
    if (configFile == null) return;

    try {
      await _writeReplacementsToFile(
        configFile,
        _convertSavedPortraitMapToPaths(replacements, gameCoreFolder),
      );

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

  Map<String, String> _convertSavedPortraitMapToPaths(
    Map<String, ReplacedSavedPortrait> replacements,
    Directory gameCoreFolder,
  ) {
    return replacements
        .mapEntries(
          // Convert SavedPortrait to image file paths that'll get stored in the Companion Mod.
          // Must be relative to the game/mod folder.
          (entry) => MapEntry(
            entry.value.original.relativePath.replaceAll("\\", "/"),
            entry.value.replacement.relativePath.replaceAll("\\", "/"),
          ),
        )
        .toMap();
  }

  /// Clears all image replacements from the config file
  Future<void> clearImageReplacementsConfig() async {
    await updateImageReplacementsConfig({});
  }

  /// Adds a single image replacement to the existing config
  Future<void> addImageReplacement(
    String originalPath,
    String replacementPath,
  ) async {
    try {
      final existingReplacements = await _readExistingReplacements();
      existingReplacements[originalPath] = replacementPath;

      final configFile = await _getImageReplacementsConfigFile();
      if (configFile == null) return;
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
        if (configFile == null) return;
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
