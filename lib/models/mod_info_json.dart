import 'dart:core';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';

part '../generated/models/mod_info_json.freezed.dart';
part '../generated/models/mod_info_json.g.dart';

@freezed
class EnabledModsJsonMode with _$EnabledModsJsonMode {
  const factory EnabledModsJsonMode(List<String> enabledMods) = _EnabledModsJsonMode;

  factory EnabledModsJsonMode.fromJson(Map<String, dynamic> json) => _$EnabledModsJsonModeFromJson(json);
}

@freezed
class ModInfoJson with _$ModInfoJson {
  const ModInfoJson._();

  const factory ModInfoJson(final String id,
      {@Default("") final String name,
      @JsonConverterVersionNullable() final Version? version,
      final String? author,
      final String? gameVersion,
      @Default([]) final List<Dependency> dependencies,
      final String? description}) = _ModInfoJson;

  factory ModInfoJson.fromJson(Map<String, dynamic> json) => _$ModInfoJsonFromJson(json);

  String get formattedName => "$name $version ($id)";
}

@freezed
class Dependency with _$Dependency {
  const Dependency._();

  const factory Dependency({
    final String? id,
    final String? name,
    @JsonConverterVersionNullable() final Version? version,
    // String? version,
  }) = _Dependency;

  factory Dependency.fromJson(Map<String, dynamic> json) => _$DependencyFromJson(json);
}

@freezed
class VersionObject with _$VersionObject {
  const VersionObject._();

  const factory VersionObject(
    final dynamic major,
    final dynamic minor,
    final dynamic patch,
  ) = _VersionObject;

  factory VersionObject.fromJson(Map<String, dynamic> json) => _$VersionObjectFromJson(json);

  @override
  String toString() => [major, minor, patch].whereNotNull().join(".");

  int compareTo(VersionObject? other) {
    if (other == null) return 0;

    var result = (major.toString().compareRecognizingNumbers(other.major.toString()));
    if (result != 0) return result;

    result = (minor.toString().compareRecognizingNumbers(other.minor.toString()));
    if (result != 0) return result;

    result = (patch.toString().compareRecognizingNumbers(other.patch.toString()));
    if (result != 0) return result;
    return result;
  }
}
