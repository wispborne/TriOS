import 'dart:core';

import 'package:fimber/fimber.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

part '../generated/models/mod_info_json.freezed.dart';
part '../generated/models/mod_info_json.g.dart';

@freezed
class EnabledModsJsonMode with _$EnabledModsJsonMode {
  const factory EnabledModsJsonMode(List<String> enabledMods) = _EnabledModsJsonMode;

  factory EnabledModsJsonMode.fromJson(Map<String, dynamic> json) => _$EnabledModsJsonModeFromJson(json);
}

@freezed
class ModInfoJsonModel_091a with _$ModInfoJsonModel_091a {
  const factory ModInfoJsonModel_091a({
    required final String id,
    required final String name,
    @VersionJsonConverter() required final Version version,
    required final String? gameVersion,
  }) = _ModInfoJsonModel_091a;

  factory ModInfoJsonModel_091a.fromJson(Map<String, dynamic> json) => _$ModInfoJsonModel_091aFromJson(json);
}

@freezed
class ModInfoJsonModel_095a with _$ModInfoJsonModel_095a {
  const factory ModInfoJsonModel_095a({
    required final String id,
    required final String name,
    @VersionJsonConverter() required final Version version,
    required final String? gameVersion,
  }) = _ModInfoJsonModel_095a;

  factory ModInfoJsonModel_095a.fromJson(Map<String, dynamic> json) => _$ModInfoJsonModel_095aFromJson(json);
}

@freezed
class ModInfoJson with _$ModInfoJson {
  const factory ModInfoJson(
    final String id,
    final String name,
    @VersionJsonConverter() final Version version,
    final String? gameVersion,
  ) = _ModInfoJson;

  factory ModInfoJson.fromJson(Map<String, dynamic> json) => _$ModInfoJsonFromJson(json);
}

@freezed
class Version_095a with _$Version_095a {
  const factory Version_095a(
    final dynamic major,
    final dynamic minor,
    final dynamic patch,
  ) = _Version_095a;

  factory Version_095a.fromJson(Map<String, dynamic> json) => _$Version_095aFromJson(json);
}

class VersionJsonConverter implements JsonConverter<Version, dynamic> {
  const VersionJsonConverter();

  @override
  Version fromJson(dynamic json) {
    try {
      return Version.parse(json);
    } catch (e) {
      Fimber.d("Unable to parse version from json: $json");
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
