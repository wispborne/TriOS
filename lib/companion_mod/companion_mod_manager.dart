import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
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
}
