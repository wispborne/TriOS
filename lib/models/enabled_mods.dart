import 'package:freezed_annotation/freezed_annotation.dart';

part '../generated/models/enabled_mods.freezed.dart';
part '../generated/models/enabled_mods.g.dart';

@freezed
class EnabledMods with _$EnabledMods {
  const factory EnabledMods(Set<String> enabledMods) = _EnabledMods;

  factory EnabledMods.fromJson(Map<String, dynamic> json) => _$EnabledModsFromJson(json);
}
