import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_links.dart';
import 'package:trios/catalog/forum_data_manager.dart';
import 'package:trios/catalog/models/forum_data_bundle.dart';
import 'package:trios/catalog/models/mod_image_source.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/strip_markdown.dart';

/// The description in an installed mod's `mod_info.json`. Reads the variant
/// that's turned on, or the newest one the user has if none is.
String? modInfoDescription(Mod? installedMod) =>
    installedMod?.findFirstEnabledOrHighestVersion?.modInfo.description;

/// The text with spaces trimmed off, or null when nothing is left.
String? trimmedOrNull(String? text) {
  final trimmed = text?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// Mod text with any markdown taken off, or null when nothing is left. The
/// catalog shows these texts as-is, so markers like `**bold**` would show up
/// on screen.
String? _asPlainText(String? text) {
  final trimmed = trimmedOrNull(text);
  return trimmed == null ? null : trimmedOrNull(stripMarkdown(trimmed));
}

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

  /// A link to where the mod's code lives, e.g. a GitHub page.
  final String? sourceCodeUrl;

  /// The license the author wrote on the forum. Free text: anything from
  /// "MIT" to a paragraph of house rules, so it can't be matched against a
  /// list of license names.
  final String? licenseText;

  // -- Images --

  /// The best available image: AI-block image, scraped catalog image, author
  /// avatar, or the installed mod's icon on disk.
  final ModImageSource? catalogImage;

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
    this.sourceCodeUrl,
    this.licenseText,
    this.catalogImage,
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

  /// The license when the whole thing is just a link — a few mods point at a
  /// Creative Commons page instead of writing terms out. Null when the
  /// license is text, even if a link is buried in it.
  String? get licenseUrl {
    final text = licenseText;
    if (text == null) return null;
    if (text.contains(RegExp(r'\s'))) return null;
    if (text.startsWith('http://') || text.startsWith('https://')) return text;
    return null;
  }
}

/// A human name for the site a source code link points at, e.g. "GitHub".
/// Falls back to the site address for anywhere else.
String sourceCodeHostName(String url) {
  final fullHost = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  final host = fullHost.startsWith('www.') ? fullHost.substring(4) : fullHost;
  return switch (host) {
    'github.com' => 'GitHub',
    'bitbucket.org' => 'Bitbucket',
    'gitlab.com' => 'GitLab',
    '' => 'Source code',
    _ => host,
  };
}

String? _resolveAvatarUrl(String? p) {
  if (p == null || p.isEmpty) return null;
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  try {
    return Uri.parse(
      'https://fractalsoftworks.com/forum/',
    ).resolve(p).toString();
  } catch (_) {
    return null;
  }
}

/// The AI's answer for this catalog mod, found by the name the catalog gives
/// it in each source post. The forum topic's answer comes first, then each
/// Discord thread's. Null when no source post names an AI answer.
///
/// The catalog has already decided which answer belongs to which mod, so this
/// never guesses by name or falls back to a post's main mod.
ForumLlmMod? llmModForEntry(
  ModRepoEntry mod, {
  ForumModIndex? forumIndex,
  List<DiscordThreadAnswer> discordThreads = const [],
}) {
  final forumName = mod.forumPost?.llmModName;
  if (forumName != null) {
    final match = forumIndex?.llm?.mods.firstWhereOrNull(
      (m) => m.name == forumName,
    );
    if (match != null) return match;
  }
  for (final post in mod.discordPosts) {
    final name = post.llmModName;
    if (name == null) continue;
    final thread = discordThreads.firstWhereOrNull(
      (t) => t.threadId == post.id,
    );
    final match = thread?.mods.firstWhereOrNull((m) => m.name == name);
    if (match != null) return match;
  }
  return null;
}

/// The AI answers for the Discord threads [mod] came from, out of [byThreadId].
List<DiscordThreadAnswer> discordThreadsFor(
  ModRepoEntry mod,
  Map<String, DiscordThreadAnswer> byThreadId,
) => [
  for (final post in mod.discordPosts)
    if (byThreadId[post.id] case final thread?) thread,
];

/// Builds the set of Attribute chip-value keys for a mod. Pure — no provider
/// reads. The `forumIndex` carries the WIP and Archived flags that used to
/// require a separate provider lookup.
List<String> _buildAttributeKeys(
  ModRepoEntry mod,
  ForumModIndex? forumIndex, {
  String? sourceCodeUrl,
}) {
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
  if (sourceCodeUrl != null) result.add('sourceCode');
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
///
/// [discordThreads] are the AI answers for the Discord threads the mod came
/// from. They are used only when the forum topic has no AI answer for it.
CatalogMod gatherCatalogMod({
  required ModRepoEntry mod,
  ForumModIndex? forumIndex,
  List<DiscordThreadAnswer> discordThreads = const [],
  ForumModDetails? forumDetails,
  Mod? installedMod,
}) {
  final llmMod = llmModForEntry(
    mod,
    forumIndex: forumIndex,
    discordThreads: discordThreads,
  );
  final extras = llmMod?.extras;
  final sourceCodeUrl = extras?.sourceCodeUrl;

  final authorsList = mod.authorsList?.isNotEmpty == true
      ? mod.getAuthorsDeduplicated().join(', ')
      : (forumDetails?.author ?? forumIndex?.author ?? '');

  // Forum details carry richer author metadata; index fills in the rest.
  final authorTitle = forumDetails?.authorTitle;
  final authorPostCount = forumDetails?.authorPostCount;
  final avatarPathResolved = _resolveAvatarUrl(forumDetails?.authorAvatarPath);

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

  // The AI's pick comes first: it chose an image out of the forum post, while
  // the index just takes whatever image it scraped first.
  final mainImage =
      ModImageSource.web(llmMod?.imageUrl) ??
      ModImageSource.web(mod.images?.values.firstOrNull?.url) ??
      ModImageSource.web(avatarPathResolved) ??
      ModImageSource.file(
        installedMod?.findFirstEnabledOrHighestVersion?.iconFilePath,
      );

  return CatalogMod(
    entry: mod,
    title: title,
    authors: authorsList,
    partOfThreadTitle: mod.isPartOfThread ? forumIndex?.title : null,
    authorTitle: authorTitle,
    authorPostCount: authorPostCount,
    authorAvatarPath: avatarPathResolved,
    summaryText: _asPlainText(mod.summary),
    descriptionText: _asPlainText(mod.description),
    modInfoText: _asPlainText(modInfoDescription(installedMod)),
    aiSentence: _asPlainText(extras?.summary?.sentence),
    aiParagraph: _asPlainText(extras?.summary?.paragraph),
    llmMod: llmMod,
    changelog: extras?.changelog,
    supportLinks: extras?.supportLinks ?? const [],
    saveCompatibility: extras?.saveCompatibility,
    sourceCodeUrl: sourceCodeUrl,
    // Forum posts write `&nbsp;` where they mean a space; the app shows the
    // license as-is, so the code turns it back into one here.
    licenseText: trimmedOrNull(extras?.license?.replaceAll('&nbsp;', ' ')),
    catalogImage: mainImage,
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
    attributeKeys: _buildAttributeKeys(
      mod,
      forumIndex,
      sourceCodeUrl: sourceCodeUrl,
    ),
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
  final discordLookup = ref.watch(discordThreadsById);
  final links = ref.watch(catalogLinksProvider);

  final sw = Stopwatch()..start();
  final result = entries.map((entry) {
    final topicId = extractForumTopicId(entry.urls?[ModUrlType.Forum]);
    final forumIndex = topicId != null ? forumLookup[topicId] : null;
    final installedMod = links.modForEntry(entry);
    return gatherCatalogMod(
      mod: entry,
      forumIndex: forumIndex,
      discordThreads: discordThreadsFor(entry, discordLookup),
      installedMod: installedMod,
    );
  }).toList();
  Fimber.i(
    'catalogModsProvider built ${result.length} mods in ${sw.elapsedMilliseconds}ms',
  );
  return result;
});
