import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/mod_variant.dart';
import '../../models/version.dart';
import '../../utils/util.dart';

part '../../generated/mod_profiles/models/mod_profile.freezed.dart';
part '../../generated/mod_profiles/models/mod_profile.g.dart';

@freezed
class ShallowModVariant with _$ShallowModVariant {
  const factory ShallowModVariant({
    required String modId,
    String? modName,
    required String smolVariantId,
    @JsonConverterVersionNullable() Version? version,
  }) = _ShallowModVariant;

  factory ShallowModVariant.fromModVariant(ModVariant variant) {
    return ShallowModVariant(
      modId: variant.modInfo.id,
      modName: variant.modInfo.name,
      smolVariantId: variant.smolId,
      version: variant.modInfo.version,
    );
  }

  factory ShallowModVariant.fromJson(Map<String, dynamic> json) =>
      _$ShallowModVariantFromJson(json);
}

@freezed
class ModProfile with _$ModProfile {
  const factory ModProfile({
    required String id,
    required String name,
    required String description,
    required int sortOrder,
    required List<ShallowModVariant> enabledModVariants,
    DateTime? dateCreated,
    DateTime? dateModified,
  }) = _ModProfile;

  factory ModProfile.fromJson(Map<String, dynamic> json) =>
      _$ModProfileFromJson(json);
}
