import 'dart:core';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/models/version.dart';

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
      @VersionJsonConverter() required final Version version,
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
    @VersionJsonConverterNullable() final Version? version,
    // String? version,
  }) = _Dependency;

  factory Dependency.fromJson(Map<String, dynamic> json) => _$DependencyFromJson(json);
}

@freezed
class Version_095a with _$Version_095a {
  const Version_095a._();

  const factory Version_095a(
    final dynamic major,
    final dynamic minor,
    final dynamic patch,
  ) = _Version_095a;

  factory Version_095a.fromJson(Map<String, dynamic> json) => _$Version_095aFromJson(json);

  @override
  String toString() => "$major.$minor.$patch";
}

class VersionJsonConverter implements JsonConverter<Version, dynamic> {
  const VersionJsonConverter();

  @override
  Version fromJson(dynamic json) {
    try {
      if (json is Map<String, dynamic>) {
        return Version.parse(Version_095a.fromJson(json).toString());
      }
      return Version.parse(json);
    } catch (e, st) {
      rethrow;
    }
  }

  @override
  String toJson(dynamic object) {
    if (object is Version_095a) {
      return "${object.major}.${object.minor}.${object.patch}";
    } else {
      return object.toString();
    }
  }
}

class VersionJsonConverterNullable implements JsonConverter<Version?, dynamic> {
  const VersionJsonConverterNullable();

  @override
  Version? fromJson(dynamic json) {
    try {
      return VersionJsonConverter().fromJson(json);
    } catch (e, st) {
      return null;
    }
  }

  @override
  String toJson(dynamic object) {
    return VersionJsonConverter().toJson(object);
  }
}
