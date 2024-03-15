import 'dart:io';

import 'package:trios/models/version.dart';

import 'mod_info_json.dart';

class ModInfo {
  String id;
  String name;
  Version version;
  String? description;
  String? gameVersion;
  String? author;
  List<Dependency> dependencies = [];

  // ModDependencies? dependencies;

  ModInfo(this.id, this.name, this.version, this.author, this.description, this.gameVersion, this.dependencies);

  ModInfo.fromJsonModel(ModInfoJson model, Directory modFolder)
      : this(model.id, model.name, model.version, model.author, model.description, model.gameVersion,
            model.dependencies);

  // ModInfo.from091(ModInfoJsonModel_091a model) : this(model.id, model.name, model.version, model.gameVersion);

  late final formattedName = "$name $version ($id)";

  @override
  String toString() => "ModInfo(id: $id, name: $name, version: $version, gameVersion: $gameVersion)";
}
