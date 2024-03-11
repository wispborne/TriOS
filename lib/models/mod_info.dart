import 'dart:io';

class ModInfo {
  String id;
  Directory modFolder;
  String name;
  String version;
  String? gameVersion;

  ModInfo(this.id, this.modFolder, this.name, this.version, this.gameVersion);

  late final formattedName = "$name $version ($id)";
}
