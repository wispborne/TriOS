import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/utils/log_collapser.dart';
import 'package:trios/utils/logging.dart';

part 'catalog_extras.mapper.dart';

/// What the author says about using AI tools to make the mod.
///
/// Only the author's own statement counts. There are three cases:
/// - No [CatalogAiUse] at all: the post has not been read for AI use yet.
/// - [usesAi] null (written `{}`): the post was read and says nothing usable.
/// - [usesAi] true or false: the author says AI was used, or says none was.
@MappableClass()
class CatalogAiUse with CatalogAiUseMappable {
  /// True when the author says AI was used, false when they say none was, and
  /// null when the post says nothing about it.
  final bool? usesAi;

  /// What AI was used for. At least one entry when [usesAi] is true.
  final List<CatalogAiUseEntry>? uses;

  /// The AI tools the post names.
  final List<String>? tools;

  /// The author's own words, copied from the post.
  final String? quote;

  CatalogAiUse({this.usesAi, this.uses, this.tools, this.quote});
}

/// One use of an AI tool the author's statement names. Kept as plain text so
/// a value the scraper adds later doesn't fail the parse.
@MappableClass()
class CatalogAiUseEntry with CatalogAiUseEntryMappable {
  /// The part of the mod, e.g. "portraits" or "code".
  final String area;

  /// "generated", "edited" or "assisted". Null when the author doesn't say.
  final String? how;

  /// "all", "most" or "some". Null when the author doesn't say.
  final String? extent;

  /// True when the player can leave this part out, such as an optional
  /// portrait pack.
  final bool? optional;

  CatalogAiUseEntry({required this.area, this.how, this.extent, this.optional});
}

/// Yes, no or depends: the author's answer to a save question, such as
/// whether the mod can be added to a game in progress.
@MappableEnum(defaultValue: CatalogSaveAnswer.unknown)
enum CatalogSaveAnswer { yes, no, depends, unknown }

/// What kind of picture the AI saw.
@MappableEnum(defaultValue: CatalogPictureKind.unknown)
enum CatalogPictureKind {
  screenshot,
  logo,
  banner,
  art,
  button,
  badge,
  divider,
  missing,
  other,
  unknown,
}

/// How well the AI thought a picture would work as the mod's card picture.
@MappableEnum(defaultValue: CatalogPictureFit.unknown)
enum CatalogPictureFit { good, okay, poor, unknown }

/// Where a picture was posted.
@MappableEnum(defaultValue: CatalogPictureSource.unknown)
enum CatalogPictureSource { forum, discord, nexus, unknown }

/// `mod-catalog-extras.json`: facts the scraper works out while it builds
/// Starmodder, one record per catalog mod id.
///
/// Not decoded with a mapper. [parseCatalogExtrasFile] reads it one record at
/// a time, so one bad record doesn't hide the rest.
class CatalogExtrasFile {
  /// The newest schema version TriOS can read. The scraper raises its number
  /// when it renames a field or changes its shape, not when it adds one.
  static const knownSchemaVersion = 1;

  final int schemaVersion;
  final DateTime? generatedAt;

  /// Keyed by catalog id. Empty when [schemaVersion] is newer than TriOS
  /// knows.
  final Map<String, CatalogExtras> mods;

  const CatalogExtrasFile({
    required this.schemaVersion,
    this.generatedAt,
    this.mods = const {},
  });

  /// True when TriOS can read this file's schema version.
  bool get isKnownSchema => schemaVersion <= knownSchemaVersion;
}

/// Reads `mod-catalog-extras.json`. A record that fails to decode is dropped,
/// and one line with the count is logged. A file with a schema version newer
/// than [CatalogExtrasFile.knownSchemaVersion] comes back with no records.
CatalogExtrasFile parseCatalogExtrasFile(Map<String, dynamic> json) {
  final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 0;
  final generatedAt = DateTime.tryParse('${json['generatedAt']}');
  if (schemaVersion > CatalogExtrasFile.knownSchemaVersion) {
    Fimber.w(
      'Mod catalog extras file has schema version $schemaVersion, but TriOS '
      'only reads up to ${CatalogExtrasFile.knownSchemaVersion}. Ignoring it.',
    );
    return CatalogExtrasFile(
      schemaVersion: schemaVersion,
      generatedAt: generatedAt,
    );
  }

  final mods = <String, CatalogExtras>{};
  final dropped = LogCollapser();
  final rawMods = json['mods'];
  if (rawMods is Map) {
    rawMods.forEach((id, value) {
      try {
        mods['$id'] = CatalogExtrasMapper.fromMap(
          Map<String, dynamic>.from(value as Map),
        );
      } catch (ex) {
        dropped.add('$ex');
      }
    });
  }
  dropped.flush('Mod catalog extras', noun: 'dropped record');
  return CatalogExtrasFile(
    schemaVersion: schemaVersion,
    generatedAt: generatedAt,
    mods: mods,
  );
}

/// One catalog mod's record in `mod-catalog-extras.json`. The scraper leaves
/// out nulls, empty lists and empty maps, so a missing list reads as empty.
@MappableClass()
class CatalogExtras with CatalogExtrasMappable {
  /// The name Starmodder shows. Only there when it differs from the catalog's
  /// name.
  final String? displayName;

  /// The short summary Starmodder shows under the mod's name, in the author's
  /// own words: an excerpt from the mod's part of the forum post, else the
  /// catalog's summary, else an excerpt from the Discord post. Never AI text.
  final String? summary;

  /// The cleaned-up categories Starmodder uses, e.g. "Ships and weapons".
  final List<String> categories;

  /// The categories the mod was posted under, after matching names are
  /// combined.
  final List<String> rawCategories;

  /// Each credited author's other known names, keyed by the credited name.
  final Map<String, List<String>> otherAuthorNames;

  /// The day Starmodder says the mod was posted.
  final DateTime? addedOn;

  /// The day Starmodder says the mod's post was last edited.
  final DateTime? editedOn;

  /// When the newest release in [releases] was seen.
  final DateTime? lastReleaseDate;

  /// Newest first.
  final List<CatalogRelease> releases;

  /// Mods this mod requires.
  final List<CatalogNeed> needs;

  /// Mods this mod works with but doesn't require.
  final List<CatalogNeed> optionalNeeds;

  /// True when the mod is a tool rather than a game mod.
  final bool? isTool;

  final bool? saveCompatible;

  /// Whether the mod can be added to a game in progress.
  final CatalogSaveAnswer? canAdd;

  /// Whether a game in progress survives updating the mod.
  final CatalogSaveAnswer? canUpdate;

  /// Whether the mod can be removed from a game in progress.
  final CatalogSaveAnswer? canRemove;

  /// The author's words behind [canAdd].
  final String? saveCompatibilityText;

  /// The author's words behind [canUpdate].
  final String? updateCompatibilityText;

  /// The author's words behind [canRemove].
  final String? removalCompatibilityText;

  /// What the author says about using AI tools. Null when the post hasn't
  /// been read for it.
  final CatalogAiUse? aiUse;

  /// Other mods with the same name.
  final List<CatalogSameNameMod> sameNameMods;

  /// Pictures from the mod's posts.
  final List<CatalogGalleryPicture> gallery;

  /// The mod's Discord post as cleaned HTML, as Starmodder shows it.
  final String? discordPostHtml;

  CatalogExtras({
    this.displayName,
    this.summary,
    this.categories = const [],
    this.rawCategories = const [],
    this.otherAuthorNames = const {},
    this.addedOn,
    this.editedOn,
    this.lastReleaseDate,
    this.releases = const [],
    this.needs = const [],
    this.optionalNeeds = const [],
    this.isTool,
    this.saveCompatible,
    this.canAdd,
    this.canUpdate,
    this.canRemove,
    this.saveCompatibilityText,
    this.updateCompatibilityText,
    this.removalCompatibilityText,
    this.aiUse,
    this.sameNameMods = const [],
    this.gallery = const [],
    this.discordPostHtml,
  });
}

/// One new version of a mod, as the scraper saw it.
@MappableClass()
class CatalogRelease with CatalogReleaseMappable {
  /// The day the new version was first seen.
  final DateTime seenOn;

  /// The version before. Null for the first release on record.
  final String? oldVersion;

  final String newVersion;

  /// The game version the mod was for when the release was seen.
  final String? gameVersion;

  /// That version's changelog, copied from the post.
  final String? changelogNotes;

  /// What the post says about updating to this version.
  final String? updateCompatibilityText;

  /// Yes, no or depends, read from [updateCompatibilityText].
  final CatalogSaveAnswer? canUpdate;

  CatalogRelease({
    required this.seenOn,
    this.oldVersion,
    required this.newVersion,
    this.gameVersion,
    this.changelogNotes,
    this.updateCompatibilityText,
    this.canUpdate,
  });
}

/// A mod another mod needs. [id] is its catalog id, or null when the scraper
/// found no catalog mod by that name.
@MappableClass()
class CatalogNeed with CatalogNeedMappable {
  final String name;
  final String? id;

  /// For a mod needed only because another requirement needs it: the name of
  /// that requirement, as written on the same list. Null for the mods the
  /// post names itself.
  final String? via;

  CatalogNeed({required this.name, this.id, this.via});
}

/// Another mod with the same name.
@MappableClass()
class CatalogSameNameMod with CatalogSameNameModMappable {
  final String title;

  /// The mod's forum thread. A mod with no [id] has this instead.
  final String? url;

  /// The mod's catalog id, when it has one.
  final String? id;

  /// Who wrote it. This is what tells two mods with one name apart.
  final List<String> authors;

  final String? gameVersion;
  final String? modVersion;

  /// The day its forum thread was last posted on.
  final DateTime? threadLastPostOn;

  CatalogSameNameMod({
    required this.title,
    this.url,
    this.id,
    this.authors = const [],
    this.gameVersion,
    this.modVersion,
    this.threadLastPostOn,
  });
}

/// One picture from a mod's posts.
@MappableClass()
class CatalogGalleryPicture with CatalogGalleryPictureMappable {
  final String url;

  /// The picture's own caption or alt text.
  final String? caption;

  /// An AI-written description of the picture.
  final String? aiCaption;

  final CatalogPictureKind? aiKind;
  final CatalogPictureFit? aiFit;

  /// True when the AI couldn't fetch or open the picture.
  final bool aiUnreadable;

  /// True for a badge, button, icon or other small picture.
  final bool small;

  final CatalogPictureSource? source;

  CatalogGalleryPicture({
    required this.url,
    this.caption,
    this.aiCaption,
    this.aiKind,
    this.aiFit,
    this.aiUnreadable = false,
    this.small = false,
    this.source,
  });
}
