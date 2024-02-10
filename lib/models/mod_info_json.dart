import 'dart:core';
import 'package:dart_json_mapper/dart_json_mapper.dart' show JsonMapper, jsonSerializable, JsonProperty;



@jsonSerializable
class EnabledModsJsonMode {
  // @JsonProperty("enabledMods")
  final List<String> enabledMods;

  EnabledModsJsonMode(this.enabledMods);
}

@jsonSerializable
class ModInfoJsonModel_091a {
// @JsonProperty("id")
  final String id;

// @JsonProperty("name")
  final String name;

// @JsonProperty("version")
  final String version;

  ModInfoJsonModel_091a(this.id, this.name, this.version);
}

@jsonSerializable
class ModInfoJsonModel_095a {
// @JsonProperty("id")
  final String id;

// @JsonProperty("name")
  final String name;

// @JsonProperty("version")
  Version_095a version;

  ModInfoJsonModel_095a(this.id, this.name, this.version);
}

@jsonSerializable
class Version_095a {
// @JsonProperty("major")
  final String major;

// @JsonProperty("minor")
  final String minor;

// @JsonProperty("patch")
  final String patch;

  Version_095a(this.major, this.minor, this.patch);
}
