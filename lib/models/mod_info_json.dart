import 'dart:core';

import 'package:fimber/fimber.dart';
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
      Fimber.d("Unable to parse version from json: $json", ex: e, stacktrace: st);
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
