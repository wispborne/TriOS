import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/models/enabled_mods.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';

import '../models/mod_info.dart';
import '../models/version.dart';

Future<List<ModInfo>> getModsInFolder(Directory modsFolder) async {
  var mods = <ModInfo?>[];

  for (var modFolder in modsFolder.listSync().whereType<Directory>()) {
    var progressText = StringBuffer();
    var modInfo = getModInfo(modFolder, progressText);

    mods.add(await modInfo);
  }

  return mods.whereType<ModInfo>().toList();
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

GameCompatibility compareGameVersions(String? modGameVersion, String? gameVersion) {
  // game is versioned like 0.95.1a-RC5 and 0.95.0a-RC5
  // they are fully compatible if the first three numbers are the same
  // they are partially compatible if the first two numbers are the same
  // they are incompatible if the first or second number is different
  if (modGameVersion == null || gameVersion == null) {
    return GameCompatibility.Compatible;
  }

  final modVersion = Version.parse(modGameVersion);
  final gameVersionParsed = Version.parse(gameVersion);
  if (modVersion.major == gameVersionParsed.major &&
      modVersion.minor == gameVersionParsed.minor &&
      modVersion.patch == gameVersionParsed.patch) {
    return GameCompatibility.Compatible;
  } else if (modVersion.major == gameVersionParsed.major && modVersion.minor == gameVersionParsed.minor) {
    return GameCompatibility.Warning;
  } else {
    return GameCompatibility.Incompatible;
  }
}

extension DependencyExt on Dependency {
  DependencyStateType isSatisfiedBy(ModInfo mod, EnabledMods enabledMods) {
    if (mod.id != id) {
      return DependencyStateType.Missing;
    }

    if (version != null && mod.version.compareTo(version!) < 0) {
      return DependencyStateType.WrongVersion;
    }

    if (!mod.isEnabled(enabledMods)) {
      return DependencyStateType.Disabled;
    }

    return DependencyStateType.Satisfied;
  }

  DependencyStateType isSatisfiedByAny(List<ModInfo> allMods, EnabledMods enabledMods) {
    var foundDependencies = allMods.filter((mod) => mod.id == id);
    if (foundDependencies.isEmpty) {
      return DependencyStateType.Missing;
    }

    final satisfyResults = foundDependencies.map((mod) => isSatisfiedBy(mod, enabledMods)).toList();
    if (satisfyResults.contains(DependencyStateType.Satisfied)) {
      return DependencyStateType.Satisfied;
    } else if (satisfyResults.contains(DependencyStateType.Disabled)) {
      return DependencyStateType.Disabled;
    } else if (satisfyResults.contains(DependencyStateType.WrongVersion)) {
      return DependencyStateType.WrongVersion;
    } else {
      return DependencyStateType.Missing;
    }
  }
}

extension ModInfoExt on ModInfo {
  GameCompatibility isCompatibleWithGame(String? gameVersion) {
    return compareGameVersions(gameVersion, this.gameVersion);
  }

  bool isEnabled(EnabledMods enabledMods) {
    return enabledMods.enabledMods.contains(id);
  }
}

enum GameCompatibility { Compatible, Warning, Incompatible }

//     sealed class DependencyState {
//         abstract val dependency: Dependency
//
//         data class Missing(override val dependency: Dependency, val outdatedModIfFound: Mod?) : DependencyState()
//         data class Disabled(override val dependency: Dependency, val variant: ModVariant) : DependencyState()
//         data class Enabled(override val dependency: Dependency, val variant: ModVariant) : DependencyState()
//     }

class DependencyState {
  final Dependency dependency;

  DependencyState(this.dependency);
}

enum DependencyStateType { Missing, Disabled, WrongVersion, Satisfied }
