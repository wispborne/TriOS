import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

import 'mod_info.dart';

part 'mod_variant.mapper.dart';

typedef SmolId = String;

@MappableClass()
class ModVariant with ModVariantMappable implements Comparable<ModVariant> {
  final ModInfo modInfo;
  final VersionCheckerInfo? versionCheckerInfo;
  @MappableField(hook: DirectoryHook())
  final Directory modFolder;
  final bool hasNonBrickedModInfo;

  ModVariant({
    required this.modInfo,
    required this.versionCheckerInfo,
    required this.modFolder,
    required this.hasNonBrickedModInfo,
  });

  String get smolId => createSmolId(modInfo.id, modInfo.version);

  /// In-memory cache, won't be updated if the mod's icon changes until restart.
  /// Better than re-reading the files every time, though.
  static Map<String, String?> iconCache = {};

  String? get iconFilePath {
    return iconCache.putIfAbsent(modInfo.id, () {
      var path = modIconFilePaths
          .map((path) => modFolder.resolve(path))
          .firstWhereOrNull((file) => file.existsSync())
          ?.path;

      if (path == null) {
        final lunaSettings = modFolder
            .resolve("data/config/LunaSettingsConfig.json")
            .toFile();
        if (lunaSettings.existsSync()) {
          try {
            final lunaSettingsIconPath =
                (lunaSettings
                            .readAsStringSyncAllowingMalformed()
                            .fixJsonToMap()
                            .entries
                            .first
                            .value
                        as Map<String, dynamic>)
                    .entries
                    .firstWhereOrNull(
                      (entry) => entry.key.toLowerCase().containsIgnoreCase(
                        "iconPath",
                      ),
                    )
                    ?.value;
            if (lunaSettingsIconPath is String) {
              final icon = modFolder.resolve(lunaSettingsIconPath).toFile();
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
    });
  }

  static String generateUniqueVariantFolderName(ModInfo modInfo) =>
      "${modInfo.name?.fixFilenameForFileSystem().take(100)}-${modInfo.version}";

  /// Don't use this for sorting! Use ModVariant directly, as it has multiple fallbacks.
  ///
  /// Returns the version in Version Checker if possible (authors sometimes will do `0.35` in ModInfo but `0.3.5` in Version Checker)
  /// and falls back to the `mod_info.json` version.
  Version? get bestVersion {
    return versionCheckerVersion ?? modInfo.version;
  }

  Version? get versionCheckerVersion => versionCheckerInfo?.modVersion
      ?.toString()
      .let((it) => Version.parse(it, sanitizeInput: false));

  bool get isModInfoEnabled => hasNonBrickedModInfo;

  bool isEnabled(List<Mod> mods) => mod(mods)?.isEnabled(this) == true;

  Mod? mod(List<Mod> mods) {
    return mods.firstWhereOrNull((mod) => mod.id == modInfo.id);
  }

  File? get modInfoFile => getModInfoFile(modFolder);

  /// Compares using the Version Checker version if available.
  /// If not available OR both are the same version in that file, falls back to the `mod_info.json` version (which has all non-numeric chars stripped out).
  /// If that is also the same, it will compare the `mod_info.json` as a string.
  @override
  int compareTo(ModVariant? other) {
    if (other == null) return -1;
    int result = 0;

    if (versionCheckerVersion != null && other.versionCheckerVersion != null) {
      result = versionCheckerVersion!.compareTo(other.versionCheckerVersion!);
    }
    if (result != 0) {
      return result;
    }
    result = modInfo.version?.compareTo(other.modInfo.version) ?? 0;
    if (result != 0) {
      return result;
    }

    return modInfo.version.toString().compareTo(
      other.modInfo.version.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ModVariant && other.smolId == smolId;
  }

  @override
  int get hashCode => smolId.hashCode;
}

const modIconFilePaths = [
  "icon.ico",
  "icon.png",
  "icon.jpg",
  "icon.jpeg",
  "icon.webp",
  "icon.gif",
];

final smolIdAllowedChars = RegExp(r'[^0-9a-zA-Z\\.\-_]');

final _smolIdCache = <String, String>{};

String createSmolId(String id, Version? version) {
  final versionString = version.toString();
  final cacheKey = '$id-$versionString';

  if (_smolIdCache.containsKey(cacheKey)) {
    return _smolIdCache[cacheKey]!;
  }

  final result =
      '${id.replaceAll(smolIdAllowedChars, '').take(6)}-${versionString.replaceAll(smolIdAllowedChars, '').take(9)}-${(id.hashCode + version.hashCode).abs()}';
  _smolIdCache[cacheKey] = result;

  if (_smolIdCache.length > 1000) {
    _smolIdCache.clear();
  }

  return result;
}
