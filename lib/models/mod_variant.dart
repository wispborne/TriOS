import 'dart:io';

import 'package:collection/collection.dart';
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

  String? get icoFilePath => modIconFilePaths
      .map((path) => modsFolder.resolve(path))
      .firstWhereOrNull((file) => file.existsSync())
      ?.path;
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
