import 'dart:io';

import 'mod_info_json.dart';

class ModInfo {
  String id;
  Directory modFolder;
  String name;
  String version;
  String? gameVersion;
  // ModDependencies? dependencies;

  ModInfo(this.id, this.modFolder, this.name, this.version, this.gameVersion);
  // ModInfo.from091(ModInfoJsonModel_091a model) : this(model.id, model.name, model.version, model.gameVersion);

  late final formattedName = "$name $version ($id)";
}