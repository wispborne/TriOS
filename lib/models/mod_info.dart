import 'dart:io';

class ModInfo {
  String id;
  Directory modFolder;
  String name;
  String version;

  ModInfo(this.id, this.modFolder, this.name, this.version);

  late final formattedName = "$name $version ($id)";
}
