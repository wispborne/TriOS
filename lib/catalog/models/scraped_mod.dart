import 'package:dart_mappable/dart_mappable.dart';

part 'scraped_mod.mapper.dart';

@MappableClass()
class ScrapedModsRepo with ScrapedModsRepoMappable {
  final List<ScrapedMod> items;
  final String lastUpdated;

  ScrapedModsRepo({required this.items, required this.lastUpdated});
}

@MappableClass()
class ScrapedMod with ScrapedModMappable {
  final String name;
  final String? summary;
  final String? description;
  final String? modVersion;
  final String? gameVersionReq;
  final List<String>? authorsList;
  final Map<ModUrlType, String>? urls;
  final List<ModSource>? sources;
  final List<String>? categories;
  final Map<String, ScrapedModImage>? images;
  final DateTime? dateTimeCreated;
  final DateTime? dateTimeEdited;

  /// Set only on synthesized entries: a mod that lives inside another mod's
  /// forum thread (e.g. an add-on) gets its own card, marked "part of <this
  /// thread title>". Null for real catalog entries. Built at runtime, so it's
  /// absent from the scraped data and never round-trips through it.
  final String? partOfThreadTitle;

  ScrapedMod({
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
    this.partOfThreadTitle,
  });

  /// True when this is a synthesized entry for a mod bundled in another mod's
  /// forum thread.
  bool get isPartOfThread => partOfThreadTitle != null;

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

  Map<String, ScrapedModImage> getImages() => images ?? {};

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

@MappableClass()
class ScrapedModImage with ScrapedModImageMappable {
  final String id;
  final String? filename;
  final String? description;
  final String? contentType;
  final int? size;
  final String? url;
  final String? proxyUrl;

  ScrapedModImage({
    required this.id,
    this.filename,
    this.description,
    this.contentType,
    this.size,
    this.url,
    this.proxyUrl,
  });
}
