import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

/// Internal service for pure file system operations on mod variants.
///
/// Handles "bricking" and "unbricking" mod_info.json files by renaming them
/// between enabled and disabled states. This is a low-level service that should
/// only be called from ModManagerNotifier's coordination logic.
///
/// **Private - not part of public API.**
class ModVariantCore {
  /// Disables a mod by renaming mod_info.json to mod_info.json.disabled.
  ///
  /// This "bricks" the mod so it won't be loaded by the game.
  /// Throws an exception if mod_info.json doesn't exist.
  void brickModInfoFile(Directory modFolder, String smolId) {
    final modInfoFile = modFolder.resolve(Constants.unbrickedModInfoFileName);

    if (!modInfoFile.existsSync()) {
      throw Exception("mod_info.json not found in ${modFolder.absolute}");
    }

    modInfoFile.renameSync(
      modInfoFile.parent.resolve(Constants.modInfoFileDisabledNames.first).path,
    );
    Fimber.i(
      "Disabled '$smolId': renamed to '${Constants.modInfoFileDisabledNames.first}'.",
    );
  }

  /// Enables a mod by renaming mod_info.json.disabled to mod_info.json.
  ///
  /// This "unbricks" the mod so it will be loaded by the game.
  /// Looks for any disabled variant and enables the first writable one found.
  Future<void> unbrickModInfoFile(ModVariant modVariant) async {
    // Look for any disabled mod_info files in the folder.
    final disabledModInfoFiles =
        (await Constants.modInfoFileDisabledNames
                .map((it) => modVariant.modFolder.resolve(it).toFile())
                .whereAsync((it) async => await it.isWritable()))
            .toList();

    // And re-enable one.
    if (!modVariant.isModInfoEnabled) {
      disabledModInfoFiles.firstOrNull?.let((disabledModInfoFile) async {
        disabledModInfoFile.renameSync(
          modVariant.modFolder.resolve(Constants.modInfoFileName).path,
        );
        Fimber.i(
          "Re-enabled ${modVariant.smolId}: renamed ${disabledModInfoFile.nameWithExtension} to ${Constants.modInfoFileName}.",
        );
      });
    }
  }

  /// Checks if a mod_info.json file is currently disabled (bricked).
  bool isModInfoBricked(ModVariant modVariant) {
    return !modVariant.isModInfoEnabled;
  }
}
