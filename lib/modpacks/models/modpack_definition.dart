import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'modpack_definition.mapper.dart';

/// How TriOS obtains one modpack item.
@MappableEnum()
enum ModpackItemSourceType {
  /// A Version Checker file. The item tracks the mod's latest release.
  versionFile,

  /// A fixed download address. The item keeps using that file until the pack
  /// creator publishes a newer pack version.
  directDownload,
}

/// The standard item statuses. Creators may type any other single-line
/// label.
///
/// A status is informational only: it never affects selection, installation,
/// dependencies, or enabling.
abstract final class ModpackItemStatuses {
  static const String required = 'Required';
  static const String recommended = 'Recommended';
  static const String optional = 'Optional';

  static const List<String> standard = [required, recommended, optional];

  /// Trims [value], matching standard labels case-insensitively and returning
  /// their standard spelling. Custom labels keep their capitalization. Blank
  /// input becomes null.
  static String? normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    for (final label in standard) {
      if (label.toLowerCase() == trimmed.toLowerCase()) return label;
    }
    return trimmed;
  }

  static bool isStandard(String value) {
    final trimmed = value.trim().toLowerCase();
    return standard.any((label) => label.toLowerCase() == trimmed);
  }
}

/// Clues for finding a modpack item in the Catalog if its source stops
/// working. TriOS fills these in when it knows them.
@MappableClass()
class ModpackCatalogClues with ModpackCatalogCluesMappable {
  final String? name;
  final String? forumTopicId;
  final String? nexusModsId;

  /// Fields a newer TriOS wrote that this version doesn't know about. Kept so
  /// sharing the pack again doesn't strip them.
  final Map<String, dynamic> unknownFields;

  const ModpackCatalogClues({
    this.name,
    this.forumTopicId,
    this.nexusModsId,
    this.unknownFields = const {},
  });

  bool get isEmpty =>
      name == null &&
      forumTopicId == null &&
      nexusModsId == null &&
      unknownFields.isEmpty;
}

/// One mod named by a modpack.
///
/// Any installed variant with this [modId] satisfies the item. The recorded
/// name and version are display snapshots and don't pin the download.
@MappableClass()
class ModpackItem with ModpackItemMappable {
  /// The mod's `mod_info.json` ID. Case-sensitive.
  @MappableField(key: 'id')
  final String modId;

  final String url;
  final ModpackItemSourceType sourceType;
  final String? name;
  final String? version;
  final String? status;
  final String? note;

  /// Optional clues for Catalog recovery.
  final ModpackCatalogClues? catalog;

  /// Fields a newer TriOS wrote that this version doesn't know about.
  final Map<String, dynamic> unknownFields;

  const ModpackItem({
    required this.modId,
    required this.url,
    required this.sourceType,
    this.name,
    this.version,
    this.status,
    this.note,
    this.catalog,
    this.unknownFields = const {},
  });

  String get displayName => name?.trim().isNotEmpty == true ? name! : modId;
}

/// The complete shared data of a modpack: what links, `.trios-modpack` files,
/// and update addresses contain.
@MappableClass()
class ModpackDefinition with ModpackDefinitionMappable {
  /// The shape of this definition. Separate from the pack's [version] and from
  /// the transport prefix on a link.
  static const int currentFormatVersion = 1;

  final int formatVersion;

  /// Opaque, case-sensitive pack identity: 16 random bytes as 22 unpadded
  /// base64url characters. Later versions of the same pack keep it.
  final String id;

  final String name;

  /// A positive integer TriOS increases when saved shared content changes.
  final int version;

  final String? author;
  final String? description;

  /// The Starsector version this pack targets. A label only; it never changes
  /// what TriOS installs.
  final String? gameVersion;

  final String? homepageUrl;

  /// Where a newer definition of this same pack can be found.
  final String? updateUrl;

  /// The pack's items, in the creator's order. Order is for display only.
  final List<ModpackItem> items;

  /// Fields a newer TriOS wrote that this version doesn't know about.
  final Map<String, dynamic> unknownFields;

  const ModpackDefinition({
    this.formatVersion = currentFormatVersion,
    required this.id,
    required this.name,
    required this.version,
    this.author,
    this.description,
    this.gameVersion,
    this.homepageUrl,
    this.updateUrl,
    this.items = const [],
    this.unknownFields = const {},
  });

  bool get isSupportedFormat => formatVersion == currentFormatVersion;

  ModpackItem? itemForModId(String modId) =>
      items.where((item) => item.modId == modId).firstOrNull;

  List<String> get modIds => items.map((item) => item.modId).toList();
}
