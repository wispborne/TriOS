import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/util.dart';

import 'mod_info_json.dart';

part '../generated/models/mod_info.freezed.dart';
part '../generated/models/mod_info.g.dart';

@freezed
class ModInfo with _$ModInfo {
  const ModInfo._();

  const factory ModInfo({
    required String id,
    required String name,
    @JsonConverterVersion() required Version version,
    String? description,
    String? gameVersion,
    String? author,
    @Default([]) List<Dependency> dependencies,
  }) = _ModInfo;

  factory ModInfo.fromJsonModel(ModInfoJson model, Directory modFolder) => ModInfo(
        id: model.id,
        name: model.name,
        version: model.version,
        author: model.author,
        description: model.description,
        gameVersion: model.gameVersion,
        dependencies: model.dependencies,
      );

  factory ModInfo.fromJson(Map<String, dynamic> json) => _$ModInfoFromJson(json);

// late final formattedName = "$name $version ($id)";

// @override
// String toString() => "ModInfo(id: $id, name: $name, version: $version, gameVersion: $gameVersion)";
}
