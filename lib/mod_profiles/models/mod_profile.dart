import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:uuid/uuid.dart';

import '../../utils/dart_mappable_utils.dart';

part 'mod_profile.mapper.dart';

@MappableClass()
class ModProfiles with ModProfilesMappable {
  const ModProfiles({
    required this.modProfiles,
  });

  final List<ModProfile> modProfiles;
}

@MappableClass()
class ShallowModVariant with ShallowModVariantMappable {
  const ShallowModVariant({
    required this.modId,
    this.modName,
    required this.smolVariantId,
    @MappableField(key: 'version', hook: NullableVersionMappingHook())
    this.version,
  });

  factory ShallowModVariant.fromModVariant(ModVariant variant) {
    return ShallowModVariant(
      modId: variant.modInfo.id,
      modName: variant.modInfo.name,
      smolVariantId: variant.smolId,
      version: variant.modInfo.version,
    );
  }

  final String modId;
  final String? modName;
  final String smolVariantId;
  final Version? version;
}

@MappableClass()
class ModProfile with ModProfileMappable {
  const ModProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.sortOrder,
    required this.enabledModVariants,
    this.dateCreated,
    this.dateModified,
  });

  final String id;
  final String name;
  final String description;
  final int sortOrder;
  final List<ShallowModVariant> enabledModVariants;
  final DateTime? dateCreated;
  final DateTime? dateModified;

  static ModProfile newProfile(
      String name, List<ShallowModVariant> enabledModVariants,
      {String description = '', sortOrder = 0}) {
    return ModProfile(
      id: const Uuid().v4(),
      name: name,
      description: description,
      sortOrder: sortOrder,
      enabledModVariants: enabledModVariants,
      dateCreated: DateTime.now(),
      dateModified: DateTime.now(),
    );
  }
}
