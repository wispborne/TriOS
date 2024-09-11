import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/util.dart';

import 'mod_info_json.dart';

part '../generated/models/mod_info.freezed.dart';
part '../generated/models/mod_info.g.dart';

// TODO should prob merge this into ModInfoJson
@freezed
class ModInfo with _$ModInfo {
  const ModInfo._();

  const factory ModInfo({
    required String id,
    String? name,
    @JsonConverterVersionNullable() Version? version,
    String? description,
    String? gameVersion,
    String? author,
    @Default([]) List<Dependency> dependencies,
    String? originalGameVersion,
    @JsonConverterBool() @Default(false) final bool isUtility,
    @JsonConverterBool() @Default(false) final bool isTotalConversion,
  }) = _ModInfo;

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
      );

  factory ModInfo.fromJson(Map<String, dynamic> json) =>
      _$ModInfoFromJson(json);

  // TODO swap this to id, change id to modId.
  String get smolId => createSmolId(id, version);
  String get nameOrId => name ?? id;
  String get formattedNameVersionId => "$name${version != null ? " $version" : ""}${" ($id)"}";
  String get formattedNameVersion => "$nameOrId${version != null ? " $version" : ""}";

// late final formattedName = "$name $version ($id)";

// @override
// String toString() => "ModInfo(id: $id, name: $name, version: $version, gameVersion: $gameVersion)";
}
