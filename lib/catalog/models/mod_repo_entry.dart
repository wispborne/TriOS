import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'mod_repo_entry.mapper.dart';

/// Puts back the leading "0." on game versions that are missing it.
///
/// The catalog reads the version out of the forum thread title, so it inherits
/// whatever the mod author typed — e.g. "[97a-RC11]" or ".98a". Every real
/// Starsector version starts with "0.", and without it the version badge reads
/// wrong and the Game Version filter grows a bogus bucket.
///
/// Deliberately narrow: only a leading dot, or two or more digits before the
/// first dot. That leaves a hypothetical "1.0a" alone.
class GameVersionHook extends MappingHook {
  const GameVersionHook();

  static final _startsWithTwoDigits = RegExp(r'^\d{2}');

  @override
  dynamic beforeDecode(dynamic value) {
    if (value is! String) return value;
    final version = value.trim();
    if (version.isEmpty || version.startsWith('0.')) return value;
    if (version.startsWith('.')) return '0$version';
    if (_startsWithTwoDigits.hasMatch(version)) return '0.$version';
    return value;
  }
}

@MappableClass()
class ModRepoFile with ModRepoFileMappable {
  final List<ModRepoEntry> items;
  final String lastUpdated;

  ModRepoFile({required this.items, required this.lastUpdated});
}

@MappableClass()
class ModRepoEntry with ModRepoEntryMappable {
  /// The catalog's permanent id for this mod. It stays the same when the mod's
  /// name changes. Null for entries made in code rather than read from the
  /// catalog.
  final String? id;
  final String name;
  final String? summary;
  final String? description;
  final String? modVersion;
  @MappableField(hook: GameVersionHook())
  final String? gameVersionReq;
  final List<String>? authorsList;
  final Map<ModUrlType, String>? urls;
  final List<ModSource>? sources;
  final List<String>? categories;
  final Map<String, ModRepoImage>? images;
  final DateTime? dateTimeCreated;
  final DateTime? dateTimeEdited;

  /// The forum topics and Discord threads this mod was built from.
  final List<CatalogSourcePost>? sourcePosts;

  ModRepoEntry({
    this.id,
    required this.name,
    this.summary,
    this.description,
    this.modVersion,
    this.gameVersionReq,
    this.authorsList,
    this.urls,
    this.sources,
    this.categories,
    this.images,
    this.dateTimeCreated,
    this.dateTimeEdited,
    this.sourcePosts,
  });

  /// The forum topic this mod came from, if any.
  CatalogSourcePost? get forumPost => sourcePosts?.firstWhereOrNull(
    (post) => post.kind == CatalogSourceKind.forum,
  );

  /// The Discord threads this mod came from. Usually one, sometimes more.
  List<CatalogSourcePost> get discordPosts => [
    for (final post in sourcePosts ?? const <CatalogSourcePost>[])
      if (post.kind == CatalogSourceKind.discord) post,
  ];

  /// True when this mod shares its forum topic with other catalog mods. Only
  /// the AI finds mods like that, so their forum post has `foundBy: llm`.
  bool get isPartOfThread => forumPost?.foundBy == CatalogFoundBy.llm;

  List<String> getAuthors() => authorsList ?? [];

  /// Authors with case-insensitive duplicates merged, keeping the first
  /// occurrence's casing and order (e.g. ["Wisp", "wisp"] -> ["Wisp"]).
  List<String> getAuthorsDeduplicated() {
    final seen = <String>{};
    return getAuthors()
        .where((author) => seen.add(author.toLowerCase()))
        .toList();
  }

  List<String> getCategories() => categories ?? [];

  List<ModSource> getSources() => sources ?? [];

  Map<String, ModRepoImage> getImages() => images ?? {};

  Map<ModUrlType, String> getUrls() => urls ?? {};

  String? getBestWebsiteUrl() {
    if (urls == null) {
      return null;
    } else if (urls!.containsKey(ModUrlType.Forum)) {
      return urls![ModUrlType.Forum]!;
    } else if (urls!.containsKey(ModUrlType.NexusMods)) {
      return urls![ModUrlType.NexusMods]!;
    }
    return null;
  }
}

@MappableEnum()
enum ModSource { Index, ModdingSubforum, Discord, NexusMods }

@MappableEnum()
enum ModUrlType { Forum, Discord, NexusMods, DirectDownload, DownloadPage }

/// Where a source post lives.
@MappableEnum(defaultValue: CatalogSourceKind.unknown)
enum CatalogSourceKind { forum, discord, nexus, unknown }

/// What found a mod in a source post: the scraper's own rules, the AI, or both.
@MappableEnum(defaultValue: CatalogFoundBy.unknown)
enum CatalogFoundBy { rules, llm, rulesAndLlm, unknown }

/// One forum topic or Discord thread a catalog mod was built from.
@MappableClass()
class CatalogSourcePost with CatalogSourcePostMappable {
  final CatalogSourceKind kind;

  /// The forum topic id or Discord thread id.
  final String id;

  /// This mod's name in that post's AI answer. Null when the AI found nothing
  /// for this mod in the post.
  final String? llmModName;
  final CatalogFoundBy foundBy;

  CatalogSourcePost({
    required this.kind,
    required this.id,
    this.llmModName,
    this.foundBy = CatalogFoundBy.unknown,
  });
}

@MappableClass()
class ModRepoImage with ModRepoImageMappable {
  final String id;
  final String? filename;
  final String? description;
  final String? contentType;
  final int? size;
  final String? url;
  final String? proxyUrl;

  ModRepoImage({
    required this.id,
    this.filename,
    this.description,
    this.contentType,
    this.size,
    this.url,
    this.proxyUrl,
  });
}
