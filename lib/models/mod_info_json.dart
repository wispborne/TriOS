import 'dart:core';

import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';

part 'mod_info_json.mapper.dart';

@MappableClass()
class EnabledModsJsonMode with EnabledModsJsonModeMappable {
  final List<String> enabledMods;

  EnabledModsJsonMode(this.enabledMods);
}

@MappableClass()
class ModInfoJson with ModInfoJsonMappable {
  final String id;
  final String? name;

  @MappableField(hook: NullableVersionHook())
  final Version? version;
  final String? author;
  final String? gameVersion;
  final List<Dependency> dependencies;
  final String? description;
  final String? originalGameVersion;
  final bool utility;
  final bool totalConversion;

  ModInfoJson(
    this.id, {
    this.name,
    this.version,
    this.author,
    this.gameVersion,
    this.dependencies = const [],
    this.description,
    this.originalGameVersion,
    this.utility = false,
    this.totalConversion = false,
  });

  String get formattedName => "$name $version ($id)";
}

@MappableClass()
class Dependency with DependencyMappable {
  final String? id;
  final String? name;
  @MappableField(hook: NullableVersionHook())
  final Version? version;

  Dependency({this.id, this.name, this.version});

  String get formattedNameVersionId =>
      "$name${version != null ? " $version" : ""}${id != null ? " ($id)" : ""}";

  String get formattedNameVersion =>
      "$nameOrId${version != null ? " $version" : ""}";

  String get nameOrId => name ?? id ?? "(no name or id!)";
}

@MappableClass()
class VersionObject with VersionObjectMappable {
  final dynamic major;
  final dynamic minor;
  final dynamic patch;

  VersionObject(this.major, this.minor, this.patch);

  @override
  String toString() => [major, minor, patch].whereNotNull().join(".");

  int compareTo(VersionObject? other) {
    if (other == null) return 0;

    var result =
        (major.toString().compareRecognizingNumbers(other.major.toString()));
    if (result != 0) return result;

    result =
        (minor.toString().compareRecognizingNumbers(other.minor.toString()));
    if (result != 0) return result;

    result =
        (patch.toString().compareRecognizingNumbers(other.patch.toString()));
    return result;
  }
}
