import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:uuid/uuid.dart';

part 'shared_mod_list.mapper.dart';

/// A shared representation of a mod list that can be used for profiles, exports, or imports
@MappableClass()
class SharedModList with SharedModListMappable {
  const SharedModList({
    required this.id,
    required this.name,
    required this.description,
    required this.mods,
    required this.dateCreated,
    required this.dateModified,
  });

  final String id;
  final String name;
  final String description;
  final List<SharedModVariant> mods;
  final DateTime dateCreated;
  final DateTime dateModified;

  static SharedModList create({
    String? id,
    required String name,
    required List<SharedModVariant> mods,
    String description = '',
    DateTime? dateCreated,
    DateTime? dateModified,
  }) {
    return SharedModList(
      id: id ?? const Uuid().v4(),
      name: name,
      description: description,
      mods: mods,
      dateCreated: dateCreated ?? DateTime.now(),
      dateModified: dateModified ?? DateTime.now(),
    );
  }
}

/// A lightweight representation of a mod variant for sharing
@MappableClass()
class SharedModVariant with SharedModVariantMappable {
  const SharedModVariant({
    required this.modId,
    this.modName,
    @MappableField(key: 'variantId') required this.smolVariantId,
    @MappableField(hook: VersionHook()) this.versionName,
  });

  final String modId;
  final String? modName;
  final String smolVariantId;
  final Version? versionName;
}
