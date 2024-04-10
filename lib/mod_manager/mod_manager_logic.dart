import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/models/enabled_mods.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';

import '../models/mod_info.dart';
import '../models/version.dart';

Future<List<ModVariant>> getModsInFolder(Directory modsFolder) async {
  var mods = <ModVariant?>[];

  for (var modFolder in modsFolder.listSync().whereType<Directory>()) {
    try {
      var progressText = StringBuffer();
      var modInfo = await getModInfo(modFolder, progressText);
      if (modInfo == null) {
        continue;
      }

      final modVariant = ModVariant(
          modInfo: modInfo,
          modsFolder: modFolder,
          versionCheckerInfo: getVersionFile(modFolder)?.let((it) => getVersionCheckerInfo(it)));

      // Screenshot mode
      // if (modVariant.modInfo.isCompatibleWithGame("0.97a-RC10") == GameCompatibility.compatible || (Random().nextBool() && Random().nextBool())) {
      mods.add(modVariant);
      // }
    } catch (e, st) {
      Fimber.w("Unable to read mod in ${modFolder.absolute}. ($e)\n$st");
    }
  }

  return mods.whereType<ModVariant>().toList();
}

VersionCheckerInfo? getVersionCheckerInfo(File versionFile) {
  if (!versionFile.existsSync()) return null;
  try {
    var info = VersionCheckerInfo.fromJson(versionFile.readAsStringSync().fixJsonToMap());

    if (info.modThreadId != null) {
      info = info.copyWith(modThreadId: info.modThreadId?.replaceAll(RegExp(r'[^0-9]'), ''));

      if (info.modThreadId!.trimStart("0").isEmpty) {
        info = info.copyWith(modThreadId: null);
      }
    }

    return info;
  } catch (e, st) {
    Fimber.e("Unable to read version checker json file in ${versionFile.absolute}. ($e)\n$st");
    return null;
  }
}

File? getVersionFile(Directory modFolder) {
  final csv = File(p.join(modFolder.path, Constants.versionCheckerCsvPath));
  if (!csv.existsSync()) return null;
  try {
    return modFolder
        .resolve((const CsvToListConverter(eol: "\n").convert(csv.readAsStringSync().replaceAll("\r\n", "\n"))[1][0]
            as String))
        .toFile();
  } catch (e, st) {
    Fimber.e("Unable to read version checker csv file in ${modFolder.absolute}. ($e)\n$st");
    return null;
  }
}

Future<ModInfo?> getModInfo(Directory modFolder, StringBuffer progressText) async {
  try {
    return modFolder
        .listSync()
        .whereType<File>()
        .firstWhereOrNull((file) => file.nameWithExtension == "mod_info.json")
        ?.let((modInfoFile) async {
      var rawString = await withFileHandleLimit(() => modInfoFile.readAsString());
      var jsonEncodedYaml = (rawString).replaceAll("\t", "  ").fixJsonToMap();

      // try {
      final model = ModInfo.fromJsonModel(ModInfoJson.fromJson(jsonEncodedYaml), modFolder);

      // Fimber.v("Using 0.9.5a mod_info.json format for ${modInfoFile.absolute}");

      return model;
      // } catch (e) {
      //   final model = ModInfoModel_091a.fromJson(jsonEncodedYaml);
      //
      //   Fimber.v("Using 0.9.1a mod_info.json format for ${modInfoFile.absolute}");
      //
      //   return ModInfo(model.id, modFolder, model.name, model.version.toString(), model.gameVersion);
      // }
    });
  } catch (e, st) {
    Fimber.v("Unable to find or read 'mod_info.json' in ${modFolder.absolute}. ($e)\n$st");
    return null;
  }
}

File getEnabledModsFile(Directory modsFolder) {
  return File(p.join(modsFolder.path, "enabled_mods.json"));
}

Future<EnabledMods> getEnabledMods(Directory modsFolder) async {
  return EnabledMods.fromJson((await getEnabledModsFile(modsFolder).readAsString()).fixJsonToMap());
}

Future<void> disableMod(String modInfoId, Directory modsFolder, WidgetRef ref) async {
  var enabledMods = await getEnabledMods(modsFolder);
  enabledMods = enabledMods.copyWith(enabledMods: enabledMods.enabledMods.filter((id) => id != modInfoId).toSet());

  await getEnabledModsFile(modsFolder).writeAsString(jsonEncode(enabledMods.toJson()));
  ref.invalidate(AppState.enabledMods);
}

Future<void> enableMod(String modInfoId, Directory modsFolder, WidgetRef ref) async {
  var enabledMods = await getEnabledMods(modsFolder);
  enabledMods = enabledMods.copyWith(enabledMods: enabledMods.enabledMods.toSet()..add(modInfoId));
  await getEnabledModsFile(modsFolder).writeAsString(jsonEncode(enabledMods.toJson()));
  ref.invalidate(AppState.enabledMods);
}

Future<void> forceChangeModGameVersion(ModVariant modVariant, String newGameVersion) async {
  final modInfoFile = modVariant.modsFolder.resolve(Constants.modInfoFileName).toFile();
  // Replace the game version in the mod_info.json file.
  // Don't use the code model, we want to keep any extra fields that might not be in the model.
  final modInfoJson = modInfoFile.readAsStringSync().fixJsonToMap();
  modInfoJson["gameVersion"] = newGameVersion;
  modInfoJson["originalGameVersion"] = modVariant.modInfo.gameVersion;
  await modInfoFile.writeAsString(jsonEncodePrettily(modInfoJson));
}

GameCompatibility compareGameVersions(String? modGameVersion, String? gameVersion) {
  // game is versioned like 0.95.1a-RC5 and 0.95.0a-RC5
  // they are fully compatible if the first three numbers are the same
  // they are partially compatible if the first two numbers are the same
  // they are incompatible if the first or second number is different
  if (modGameVersion == null || gameVersion == null) {
    return GameCompatibility.compatible;
  }

  final modVersion = Version.parse(modGameVersion);
  final gameVersionParsed = Version.parse(gameVersion);
  if (modVersion.major == gameVersionParsed.major &&
      modVersion.minor == gameVersionParsed.minor &&
      modVersion.patch == gameVersionParsed.patch) {
    return GameCompatibility.compatible;
  } else if (modVersion.major == gameVersionParsed.major && modVersion.minor == gameVersionParsed.minor) {
    return GameCompatibility.warning;
  } else {
    return GameCompatibility.incompatible;
  }
}

extension DependencyExt on Dependency {
  DependencyStateType isSatisfiedBy(ModInfo mod, EnabledMods enabledMods) {
    if (id != mod.id) {
      return Missing();
    }

    //  && mod.version.compareTo(version!) < 0
    if (version != null) {
      if (mod.version?.major != version!.major) {
        return VersionInvalid(mod);
      } else if (mod.version?.minor != version!.minor) {
        return VersionWarning(mod);
      }
    }

    if (!mod.isEnabled(enabledMods)) {
      return Disabled(mod);
    }

    return Satisfied(mod);
  }

  DependencyStateType isSatisfiedByAny(List<ModVariant> allMods, EnabledMods enabledMods) {
    var foundDependencies = allMods.filter((mod) => mod.modInfo.id == id);
    if (foundDependencies.isEmpty) {
      return Missing();
    }

    final satisfyResults = foundDependencies.map((mod) => isSatisfiedBy(mod.modInfo, enabledMods)).toList();

    // Return the least severe state.
    return satisfyResults.firstWhereOrNull((it) => it is Satisfied) ??
        satisfyResults.firstWhereOrNull((it) => it is Disabled) ??
        satisfyResults.firstWhereOrNull((it) => it is VersionWarning) ??
        satisfyResults.firstWhereOrNull((it) => it is VersionInvalid) ??
        satisfyResults.firstWhereOrNull((it) => it is Missing) ??
        Missing();
    // if (satisfyResults.contains(DependencyStateType.Satisfied)) {
    //   return DependencyStateType.Satisfied;
    // } else if (satisfyResults.contains(DependencyStateType.Disabled)) {
    //   return DependencyStateType.Disabled;
    // } else if (satisfyResults.contains(DependencyStateType.VersionWarning)) {
    //   return DependencyStateType.VersionWarning;
    // } else if (satisfyResults.contains(DependencyStateType.VersionInvalid)) {
    //   return DependencyStateType.VersionInvalid;
    // } else {
    //   return DependencyStateType.Missing;
    // }
  }
}

Future<void> installModFromArchive(File archiveFile) async {
  if (!archiveFile.existsSync()) {
    throw Exception("File does not exist: ${archiveFile.path}");
  }

  final libArchive = LibArchive();
  final archiveFileList = libArchive.listEntriesInArchive(archiveFile);
  final modInfoFiles = archiveFileList.filter((it) => it.pathName.containsIgnoreCase(Constants.modInfoFileName));
}

extension ModInfoExt on ModInfo {
  GameCompatibility isCompatibleWithGame(String? gameVersion) {
    return compareGameVersions(gameVersion, this.gameVersion);
  }

  bool isEnabled(EnabledMods enabledMods) {
    return enabledMods.enabledMods.contains(id);
  }
}

enum GameCompatibility { compatible, warning, incompatible }

class DependencyState {
  final Dependency dependency;

  DependencyState(this.dependency);
}

sealed class DependencyStateType {
  final ModInfo? mod;

  DependencyStateType({this.mod});
}

class Missing extends DependencyStateType {
  Missing() : super();
}

class Disabled extends DependencyStateType {
  Disabled(ModInfo mod) : super(mod: mod);
}

class VersionInvalid extends DependencyStateType {
  VersionInvalid(ModInfo mod) : super(mod: mod);
}

class VersionWarning extends DependencyStateType {
  VersionWarning(ModInfo mod) : super(mod: mod);
}

class Satisfied extends DependencyStateType {
  Satisfied(ModInfo mod) : super(mod: mod);
}
