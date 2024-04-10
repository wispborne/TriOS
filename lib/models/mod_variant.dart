import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:fimber/fimber.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/utils/extensions.dart';

import 'mod_info.dart';

part '../generated/models/mod_variant.freezed.dart';
// part '../generated/models/mod_variant.g.dart';

@freezed
class ModVariant with _$ModVariant {
  const ModVariant._();

  const factory ModVariant({
    required ModInfo modInfo,
    required VersionCheckerInfo? versionCheckerInfo,
    required Directory modsFolder,
    // required File? backupFile,
  }) = _ModVariant;

  String get smolId => createSmolId(modInfo.id, modInfo.version);

  // TODO this sucks, it does a file read every time it's called, but Freezed doesn't support lazy properties
  String? get iconFilePath {
    var path = modIconFilePaths
        .map((path) => modsFolder.resolve(path))
        .firstWhereOrNull((file) => file.existsSync())
        ?.path;

    if (path == null) {
      final lunaSettings =
          modsFolder.resolve("data/config/LunaSettingsConfig.json").toFile();
      if (lunaSettings.existsSync()) {
        try {
          final lunaSettingsIconPath = (lunaSettings
                  .readAsStringSyncAllowingMalformed()
                  .fixJsonToMap()
                  .entries
                  .first
                  .value as Map<String, dynamic>)
              .entries
              .firstWhereOrNull((entry) =>
                  entry.key.toLowerCase().containsIgnoreCase("iconPath"))
              ?.value;
          if (lunaSettingsIconPath is String) {
            final icon = modsFolder.resolve(lunaSettingsIconPath).toFile();
            if (icon.existsSync()) {
              path = icon.path;
            }
          }
        } catch (e) {
          Fimber.d("Error reading LunaSettingsConfig.json: $e");
        }
      }
    }

    return path;
  }
// required bool doesModInfoFileExist = modFolder.resolve(Constants.UNBRICKED_MOD_INFO_FILE).exists()
}

const modIconFilePaths = [
  "icon.ico",
  "icon.png",
  "icon.jpg",
  "icon.jpeg",
  "icon.gif"
];

final smolIdAllowedChars = RegExp(r'[^0-9a-zA-Z\\.\-_]');

String createSmolId(String id, Version? version) {
  return '${id.replaceAll(smolIdAllowedChars, '').take(6)}-${version.toString().replaceAll(smolIdAllowedChars, '').take(9)}-${(id.hashCode + version.hashCode).abs()}';
}

// private val smolIdAllowedChars = Regex("""[^0-9a-zA-Z\\.\-_]""")
//         fun createSmolId(id: String, version: Version) =
//             buildString {
//                 append(id.replace(smolIdAllowedChars, "").take(6))
//                 append("-")
//                 append(version.toString().replace(smolIdAllowedChars, "").take(9))
//                 append("-")
//                 append(
//                     Objects.hash(
//                         id,
//                         version.toString()
//                     )
//                         .absoluteValue // Increases chance of a collision but ids look less confusing.
//                 )
//             }
//
//         private val systemFolderNameAllowedChars = Regex("""[^0-9a-zA-Z\\.\-_ ]""")
//         fun createSmolId(modInfo: ModInfo) = createSmolId(modInfo.id, modInfo.version)
