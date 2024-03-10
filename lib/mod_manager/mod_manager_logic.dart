import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fimber/fimber.dart';
import 'package:path/path.dart' as p;
import 'package:trios/models/enabled_mods.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';

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

      try {
        final model = ModInfoJsonModel_095a.fromJson(jsonEncodedYaml);

        Fimber.v("Using 0.9.5a mod_info.json format for ${modInfoFile.absolute}");

        return ModInfo(
            model.id, modFolder, model.name, "${model.version.major}.${model.version.minor}.${model.version.patch}");
      } catch (e) {
        final model = ModInfoJsonModel_091a.fromJson(jsonEncodedYaml);

        Fimber.v("Using 0.9.1a mod_info.json format for ${modInfoFile.absolute}");

        return ModInfo(model.id, modFolder, model.name, model.version);
      }
    });
  } catch (e, st) {
    Fimber.v("Unable to find or read 'mod_info.json' in ${modFolder.absolute}. ($e)\n$st");
    return null;
  }
}

Future<List<String>> getEnabledMods(Directory modsFolder) async {
  return EnabledMods.fromJson((await File(p.join(modsFolder.path, "enabled_mods.json")).readAsString()).fixJsonToMap())
      .enabledMods;
}
