import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';

import '../utils/dart_mappable_utils.dart';
import 'mod_info_json.dart';

part 'mod_info.mapper.dart';

// TODO should prob merge this into ModInfoJson
@MappableClass()
class ModInfo with ModInfoMappable {
  final String id;
  final String? name;
  @MappableField(hook: VersionHook())
  final Version? version;
  final String? description;
  final String? gameVersion;
  final String? author;
  final List<Dependency> dependencies;
  final String? originalGameVersion;
  final bool isUtility;
  final bool isTotalConversion;

  /// Optional override for where the mod sits in the game's load order.
  /// When absent the game sorts by display name instead.
  final String? sortString;

  ModInfo({
    required this.id,
    this.name,
    this.version,
    this.description,
    this.gameVersion,
    this.author,
    this.dependencies = const [],
    this.originalGameVersion,
    this.isUtility = false,
    this.isTotalConversion = false,
    this.sortString,
  });

  // Factory method to create a ModInfo from a ModInfoJson model
  factory ModInfo.fromJsonModel(ModInfoJson model, Directory modFolder) =>
      ModInfo(
        id: model.id,
        name: model.name,
        version: model.version,
        author: model.author,
        description: model.description,
        gameVersion: model.gameVersion,
        dependencies: model.dependencies,
        originalGameVersion: model.originalGameVersion,
        isUtility: model.utility,
        isTotalConversion: model.totalConversion,
        sortString: model.sortString,
      );

  // TODO swap this to id, change id to modId.
  String get smolId => createSmolId(id, version);

  String get nameOrId => name ?? id;

  /// Load-order sort key. Empty `sortString` falls back to name (matching the
  /// game).
  String get loadOrderKey =>
      (sortString == null || sortString!.isEmpty) ? nameOrId : sortString!;

  String get formattedNameVersionId =>
      "$name${version != null ? " $version" : ""}${" ($id)"}";

  String get formattedNameVersion =>
      "$nameOrId${version != null ? " $version" : ""}";

  late final List<ModType> modTypes = [
    if (isUtility) ModType.utility,
    if (isTotalConversion) ModType.totalConversion,
  ];
}

enum ModType { utility, totalConversion }
