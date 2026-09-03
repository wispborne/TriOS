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

/// The standard item statuses TriOS offers. A creator may type any other
/// single-line label instead.
///
/// A status is informational. It never changes selection, installation,
/// dependency, validation, or enabling behavior.
abstract final class ModpackItemStatuses {
  static const String required = 'Required';
  static const String recommended = 'Recommended';
  static const String optional = 'Optional';

  static const List<String> standard = [required, recommended, optional];

  /// Trims [value] and returns the standard spelling when it matches one of
  /// the standard labels ignoring case. Custom labels keep their own
  /// capitalization. Blank input becomes null, meaning no status.
  static String? normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    for (final label in standard) {
      if (label.toLowerCase() == trimmed.toLowerCase()) return label;
    }
    return trimmed;
  }

  /// Whether [value] is one of the standard labels, ignoring case.
  static bool isStandard(String value) {
    final trimmed = value.trim().toLowerCase();
    return standard.any((label) => label.toLowerCase() == trimmed);
  }
}

/// Clues for finding a modpack item in the Catalog when its own source stops
/// working. TriOS fills these in when it knows them.
@MappableClass()
class ModpackCatalogClues with ModpackCatalogCluesMappable {
  /// The catalog entry's name.
  final String? name;

  /// The mod's forum topic ID.
  final String? forumTopicId;

  /// The mod's Nexus Mods ID.
  final String? nexusModsId;

  /// Fields a newer TriOS wrote that this version does not know about. Kept
  /// so sharing a pack again does not strip them.
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

/// One mod named by a modpack, with the address TriOS uses to get it.
///
/// Any installed variant with this [modId] satisfies the item. The recorded
/// [version] is a display snapshot and does not pin the download.
@MappableClass()
class ModpackItem with ModpackItemMappable {
  /// The mod's `mod_info.json` ID. Case-sensitive.
  @MappableField(key: 'id')
  final String modId;

  /// The HTTP or HTTPS address TriOS downloads from.
  final String url;

  /// Whether [url] is a Version Checker file or a fixed download.
  final ModpackItemSourceType sourceType;

  /// The mod's display name when the pack was made. Optional snapshot.
  final String? name;

  /// The mod version seen when the pack was made. Optional snapshot. It does
  /// not pin installation to that release.
  final String? version;

  /// The creator's optional label, such as Required or Recommended.
  final String? status;

  /// The creator's optional plain-text note for this item.
  final String? note;

  /// Optional clues for Catalog recovery.
  final ModpackCatalogClues? catalog;

  /// Fields a newer TriOS wrote that this version does not know about.
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

  /// The name to show, falling back to the mod ID when the pack has no name.
  String get displayName => name?.trim().isNotEmpty == true ? name! : modId;
}

/// The complete shared data of a modpack. This is what links, `.trios-modpack`
/// files, and update addresses contain.
@MappableClass()
class ModpackDefinition with ModpackDefinitionMappable {
  /// The shape of this definition. Separate from the pack's own [version] and
  /// from the transport prefix on a compressed link.
  static const int currentFormatVersion = 1;

  final int formatVersion;

  /// Opaque, case-sensitive pack identity: 16 random bytes written as 22
  /// unpadded base64url characters. Later versions of the same pack keep it.
  final String id;

  final String name;

  /// A positive integer TriOS increases when saved shared content changes.
  final int version;

  final String? author;
  final String? description;

  /// The Starsector version this pack was made for. A label only. It never
  /// changes what TriOS accepts, selects, or installs.
  final String? gameVersion;

  final String? homepageUrl;

  /// Where a newer definition of this same pack can be found.
  final String? updateUrl;

  /// The pack's items, in the creator's order. Order is for display only.
  final List<ModpackItem> items;

  /// Fields a newer TriOS wrote that this version does not know about.
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

  /// Whether TriOS understands this definition's shape well enough to edit,
  /// install, or share it.
  bool get isSupportedFormat => formatVersion == currentFormatVersion;

  ModpackItem? itemForModId(String modId) =>
      items.where((item) => item.modId == modId).firstOrNull;

  /// Every mod ID in the pack, in item order.
  List<String> get modIds => items.map((item) => item.modId).toList();
}
