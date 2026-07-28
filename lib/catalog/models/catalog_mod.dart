import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_links.dart';
import 'package:trios/catalog/forum_data_manager.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/logging.dart';

/// The description in an installed mod's `mod_info.json`. Reads the variant
/// that's turned on, or the newest one the user has if none is.
String? modInfoDescription(Mod? installedMod) =>
    installedMod?.findFirstEnabledOrHighestVersion?.modInfo.description;

/// The text with spaces trimmed off, or null when nothing is left.
String? trimmedOrNull(String? text) {
  final trimmed = text?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// The first option that actually says something. Null when none do.
String? firstNonBlank(List<String?> options) =>
    options.map(trimmedOrNull).nonNulls.firstOrNull;

/// Everything the app knows about one catalog mod, combined from the catalog
/// entry, the forum index entry, the AI-written `llm` block, the cached forum
/// post details, and the installed mod on disk.
///
/// Holds every candidate value side by side and does not decide which one to
/// show — that's the resolver's job. Not serialized; rebuilt from its sources
/// each time the underlying data changes.
class CatalogMod {
  /// The raw catalog entry this was built from.
  final ModRepoEntry entry;

  // -- Identity --

  final String title;
  final String authors;
  final String? partOfThreadTitle;

  // -- Author info (rich, from forum details when available) --

  final String? authorTitle;
  final int? authorPostCount;
  final String? authorAvatarPath;

  // -- Candidate texts, kept apart --

  /// The catalog entry's `summary` field (short).
  final String? summaryText;

  /// The catalog entry's `description` field (long).
  final String? descriptionText;

  /// The installed mod's `mod_info.json` description.
  final String? modInfoText;

  /// The AI-written one-sentence summary.
  final String? aiSentence;

  /// The AI-written paragraph summary.
  final String? aiParagraph;

  // -- The matched AI entry --

  final ForumLlmMod? llmMod;
  final ForumLlmChangelog? changelog;
  final List<ForumLlmSupportLink> supportLinks;
  final String? saveCompatibility;

  // -- Images --

  /// The catalog image URL from the entry's `images` map.
  final String? catalogImageUrl;

  /// A fallback image from the AI block, when the entry has no scraped image.
  final String? fallbackImageUrl;

  // -- Forum facts --

  final String? category;
  final DateTime? postDate;
  final DateTime? lastEditDate;
  final int? views;
  final int? replies;
  final String? topicUrl;
  final DateTime? lastPostDate;
  final bool isWip;
  final bool isArchived;

  // -- Attribute keys (for the filter chips) --

  final List<String> attributeKeys;

  // -- Install state --

  final Mod? installedMod;

  // -- Downloads --

  final List<ForumLlmDownload> downloads;

  const CatalogMod({
    required this.entry,
    required this.title,
    required this.authors,
    this.partOfThreadTitle,
    this.authorTitle,
    this.authorPostCount,
    this.authorAvatarPath,
    this.summaryText,
    this.descriptionText,
    this.modInfoText,
    this.aiSentence,
    this.aiParagraph,
    this.llmMod,
    this.changelog,
    this.supportLinks = const [],
    this.saveCompatibility,
    this.catalogImageUrl,
    this.fallbackImageUrl,
    this.category,
    this.postDate,
    this.lastEditDate,
    this.views,
    this.replies,
    this.topicUrl,
    this.lastPostDate,
    this.isWip = false,
    this.isArchived = false,
    this.attributeKeys = const [],
    this.installedMod,
    this.downloads = const [],
  });

  bool get isPartOfThread => partOfThreadTitle != null;
}

/// Picks the LLM mod entry this catalog mod represents: for a mod bundled in
/// another mod's thread, the entry whose name matches; otherwise the thread's
/// main mod.
ForumLlmMod? _resolveLlmMod(ModRepoEntry mod, ForumLlmData? llm) {
  if (llm == null) return null;
  if (mod.isPartOfThread) {
    final key = mod.name.toLowerCase().trim();
    return llm.mods.firstWhereOrNull(
          (m) => m.name.toLowerCase().trim() == key,
        ) ??
        llm.mainMod;
  }
  return llm.mainMod;
}

/// Builds the set of Attribute chip-value keys for a mod. Pure — no provider
/// reads. The `forumIndex` carries the WIP and Archived flags that used to
/// require a separate provider lookup.
List<String> _buildAttributeKeys(ModRepoEntry mod, ForumModIndex? forumIndex) {
  final result = <String>[];
  final urls = mod.urls;
  if (urls?.containsKey(ModUrlType.DirectDownload) == true) {
    result.add('download');
  }
  final sources = mod.sources;
  if (sources?.contains(ModSource.Discord) == true) result.add('discord');
  if (sources?.contains(ModSource.Index) == true) result.add('index');
  if (sources?.contains(ModSource.ModdingSubforum) == true) {
    result.add('forum');
  }
  if (forumIndex != null) {
    if (forumIndex.isWip) result.add('wip');
    if (forumIndex.isArchivedModIndex) result.add('archived');
  }
  return result;
}

/// Builds a [CatalogMod] from the data sources the app already has.
///
/// Takes data in, returns a model out. No `ref`, no `BuildContext`, no
/// settings — that's what makes it testable.
///
/// [forumDetails] is optional: it's only available when the user has opened a
/// specific mod's dialog and the forum post is cached. When present, its richer
/// fields (author title, avatar, post count) win over the index.
CatalogMod gatherCatalogMod({
  required ModRepoEntry mod,
  ForumModIndex? forumIndex,
  ForumModDetails? forumDetails,
  Mod? installedMod,
}) {
  final llm = forumIndex?.llm;
  final llmMod = _resolveLlmMod(mod, llm);
  final extras = llmMod?.extras;

  final authorsList = mod.authorsList?.isNotEmpty == true
      ? mod.getAuthorsDeduplicated().join(', ')
      : (forumDetails?.author ?? forumIndex?.author ?? '');

  // Forum details carry richer author metadata; index fills in the rest.
  final authorTitle = forumDetails?.authorTitle;
  final authorPostCount = forumDetails?.authorPostCount;
  final authorAvatarPath = forumDetails?.authorAvatarPath;

  // Title: prefer the catalog entry name, then details, then index.
  final title = mod.name.isNotEmpty
      ? mod.name
      : (forumDetails?.title ?? forumIndex?.title ?? '???');

  // Dates: details first (it has the post's own date), then index, then
  // catalog for the created date.
  final postDate =
      forumDetails?.postDate ?? forumIndex?.createdDate ?? mod.dateTimeCreated;
  final lastEditDate = forumDetails?.lastEditDate ?? mod.dateTimeEdited;

  // Category: details first, then index.
  final category = forumDetails?.category ?? forumIndex?.category;

  final mainImage = mod.images?.values.firstOrNull?.url ?? llmMod?.image;

  return CatalogMod(
    entry: mod,
    title: title,
    authors: authorsList,
    partOfThreadTitle: mod.partOfThreadTitle,
    authorTitle: authorTitle,
    authorPostCount: authorPostCount,
    authorAvatarPath: authorAvatarPath,
    summaryText: mod.summary.isNotNullOrBlank ? mod.summary : null,
    descriptionText: mod.description.isNotNullOrBlank ? mod.description : null,
    modInfoText: modInfoDescription(installedMod),
    aiSentence: extras?.summary?.sentence,
    aiParagraph: extras?.summary?.paragraph,
    llmMod: llmMod,
    changelog: extras?.changelog,
    supportLinks: extras?.supportLinks ?? const [],
    saveCompatibility: extras?.saveCompatibility,
    catalogImageUrl: mainImage,
    fallbackImageUrl: llmMod?.imageUrl,
    category: category,
    postDate: postDate,
    lastEditDate: lastEditDate,
    views: forumIndex?.views,
    replies: forumIndex?.replies,
    lastPostDate: forumIndex?.lastPostDate,
    topicUrl: forumDetails != null
        ? (forumIndex?.topicUrl ?? forumDetails.title)
        : forumIndex?.topicUrl,
    isWip: forumIndex?.isWip ?? false,
    isArchived: forumIndex?.isArchivedModIndex ?? false,
    attributeKeys: _buildAttributeKeys(mod, forumIndex),
    installedMod: installedMod,
    downloads: llmMod?.downloads ?? const [],
  );
}

/// One gathered mod per catalog entry. Watches the catalog entries, forum data,
/// and catalog links. Does NOT watch version-check results — those stream in
/// continuously, and rebuilding the whole catalog for each would be wasteful.
final catalogModsProvider = Provider<List<CatalogMod>>((ref) {
  final entries = ref.watch(modRepoEntriesProvider);
  final forumLookup = ref.watch(forumDataByTopicId);
  final links = ref.watch(catalogLinksProvider);

  final sw = Stopwatch()..start();
  final result = entries.map((entry) {
    final topicId = extractForumTopicId(entry.urls?[ModUrlType.Forum]);
    final forumIndex = topicId != null ? forumLookup[topicId] : null;
    final installedMod = links.modForEntry(entry);
    return gatherCatalogMod(
      mod: entry,
      forumIndex: forumIndex,
      installedMod: installedMod,
    );
  }).toList();
  Fimber.i('catalogModsProvider built ${result.length} mods in ${sw.elapsedMilliseconds}ms');
  return result;
});
