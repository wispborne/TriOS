import 'dart:core';

import 'package:freezed_annotation/freezed_annotation.dart';

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
    required final String version,
  }) = _ModInfoJsonModel_091a;

  factory ModInfoJsonModel_091a.fromJson(Map<String, dynamic> json) => _$ModInfoJsonModel_091aFromJson(json);
}


@freezed
class ModInfoJsonModel_095a with _$ModInfoJsonModel_095a {
  const factory ModInfoJsonModel_095a({
    required final String id,
    required final String name,
    required final Version_095a version,
  }) = _ModInfoJsonModel_095a;

  factory ModInfoJsonModel_095a.fromJson(Map<String, dynamic> json) => _$ModInfoJsonModel_095aFromJson(json);
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

// class ToStringJsonConverter implements ICustomConverter<String> {
//   const ToStringJsonConverter() : super();
//
//   @override
//   String fromJSON(dynamic jsonValue, DeserializationContext context) {
//     return jsonValue.toString();
//   }
//
//   @override
//   dynamic toJSON(String object, SerializationContext context) {
//     return object;
//   }
// }
//
//
// class ToNullableStringJsonConverter implements ICustomConverter<String?> {
//   const ToNullableStringJsonConverter() : super();
//
//   @override
//   String? fromJSON(dynamic jsonValue, DeserializationContext context) {
//     return jsonValue?.toString();
//   }
//
//   @override
//   dynamic toJSON(String? object, SerializationContext context) {
//     return object;
//   }
// }