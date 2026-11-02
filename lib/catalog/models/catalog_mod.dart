import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_extras_manager.dart';
import 'package:trios/catalog/catalog_links.dart';
import 'package:trios/catalog/forum_data_manager.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/forum_data_bundle.dart';
import 'package:trios/catalog/models/mod_image_source.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/mod_search.dart';
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
/// post details, the extras record, and the installed mod on disk.
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

  /// The mod's short summary in the author's own words: the extras record's
  /// summary, which Starmodder shows too, else the catalog entry's `summary`.
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

  // -- Extras --

  /// The mod's record in `mod-catalog-extras.json`. Null when the file isn't
  /// available, or when the mod was added after the file was built.
  ///
  /// Read [categories], [requiredMods], [optionalMods] and
  /// [canAddToSaveAnswer] rather than these fields: they fall back to other
  /// data when there's no record.
  final CatalogExtras? extras;

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
    this.extras,
  });

  bool get isPartOfThread => partOfThreadTitle != null;

  /// Other names people use for the mod: the ones the scraper found in the
  /// post, then the hand-kept list.
  List<String> get nicknames => [
    ...?llmMod?.nicknames,
    ...?Constants.catalogNicknames[entry.id],
  ];

  /// Other names the mod's authors go by, e.g. "Wispborne" for "Wisp".
  List<String> get otherAuthorNames => [
    for (final author in entry.getAuthors()) ...getModAuthorAliases(author),
  ];

  /// True when the mod is a tool rather than a game mod. From the extras
  /// record, or from the AI answer when there's no record.
  bool get isTool => _isToolFrom(extras, llmMod);

  /// True when the author says the mod can be added to a save in progress.
  bool get canAddToSave => canAddToSaveAnswer == CatalogSaveAnswer.yes;

  /// Whether the mod can be added to a save in progress. From the extras
  /// record, or from the AI answer when there's no record.
  CatalogSaveAnswer? get canAddToSaveAnswer =>
      _canAddToSaveFrom(extras, llmMod);

  /// The categories to show. Starmodder's cleaned-up ones from the extras
  /// record, or the catalog entry's own when there's no record.
  List<String> get categories => extras?.categories ?? entry.getCategories();

  /// Mods this mod requires. From the extras record, or from the AI answer
  /// when there's no record. Names from the AI answer have no catalog id.
  List<CatalogNeed> get requiredMods =>
      extras?.needs ?? _needsFromNames(llmMod?.extras?.needs);

  /// Mods this mod works with but doesn't require. Same sources as
  /// [requiredMods].
  List<CatalogNeed> get optionalMods =>
      extras?.optionalNeeds ?? _needsFromNames(llmMod?.extras?.optionalNeeds);

  /// Mods the author says conflict with this mod.
  /// Uses the same sources as [requiredMods].
  List<CatalogConflict> get conflictingMods =>
      extras?.conflicts ??
      [
        for (final conflict in llmMod?.extras?.conflicts ?? const [])
          CatalogConflict(name: conflict.name, quote: conflict.quote),
      ];

  static List<CatalogNeed> _needsFromNames(List<String>? names) => [
    for (final name in names ?? const <String>[]) CatalogNeed(name: name),
  ];

  /// What the author says about using AI. From the extras record, or from the
  /// AI answer when the record has none. Null when nothing has read the post
  /// for it.
  CatalogAiUse? get aiUse => extras?.aiUse ?? llmMod?.extras?.aiUse;

  /// True when the author says AI was used, false when they say none was, and
  /// null when they say nothing about it.
  bool? get usesAi => aiUse?.usesAi;

  /// The day the mod was posted, as a [catalogDayNumber]. From the extras
  /// record, or from [postDate] when there's no record.
  int? get postedDay => catalogDayNumber(extras?.addedOn ?? postDate);

  /// The day the mod's post was last edited, as a [catalogDayNumber]. From
  /// the extras record, or [postedDay] when it has no edit date.
  int? get editedDay => catalogDayNumber(extras?.editedOn) ?? postedDay;

  /// The day the newest release was seen, as a [catalogDayNumber]. Only the
  /// extras record has this, so there is no fallback.
  int? get lastReleaseDay => catalogDayNumber(extras?.lastReleaseDate);

  /// Every link the mod has: forum, Discord, NexusMods, direct download,
  /// download page, and each download link the scraper found.
  List<String> get allLinks => [
    ...?entry.urls?.values,
    for (final download in downloads) download.url,
  ];

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

bool _isToolFrom(CatalogExtras? extras, ForumLlmMod? llmMod) =>
    (extras?.isTool ?? llmMod?.isTool) == true;

CatalogSaveAnswer? _canAddToSaveFrom(
  CatalogExtras? extras,
  ForumLlmMod? llmMod,
) {
  if (extras != null) return extras.canAdd;
  final text = llmMod?.extras?.canAdd;
  if (text == null) return null;
  return CatalogSaveAnswer.values.asNameMap()[text] ??
      CatalogSaveAnswer.unknown;
}

final DateTime _epoch = DateTime.utc(1970);

/// Whole days since 1970-01-01, for the calendar day [date] is written on.
/// The date sliders run over these, so each stop is one day that some mod
/// actually has.
///
/// The year, month and day are read as they are, not moved to UTC first. The
/// extras file writes bare dates like "2025-03-01", which Dart reads as local
/// midnight, and moving those to UTC would shift them a day east of UTC.
int? catalogDayNumber(DateTime? date) {
  if (date == null) return null;
  return DateTime.utc(date.year, date.month, date.day)
      .difference(_epoch)
      .inDays;
}

/// The day a [catalogDayNumber] stands for, at midnight UTC.
DateTime dateFromCatalogDayNumber(num day) =>
    _epoch.add(Duration(days: day.round()));

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
  CatalogSaveAnswer? canAddToSaveAnswer,
  bool isTool = false,
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
  if (canAddToSaveAnswer == CatalogSaveAnswer.yes) result.add('safeToAdd');
  if (isTool) result.add('tool');
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
///
/// [extras] is the mod's record in `mod-catalog-extras.json`, found by its
/// catalog id.
CatalogMod gatherCatalogMod({
  required ModRepoEntry mod,
  ForumModIndex? forumIndex,
  List<DiscordThreadAnswer> discordThreads = const [],
  ForumModDetails? forumDetails,
  Mod? installedMod,
  CatalogExtras? extras,
}) {
  final llmMod = llmModForEntry(
    mod,
    forumIndex: forumIndex,
    discordThreads: discordThreads,
  );
  final llmExtras = llmMod?.extras;
  final sourceCodeUrl = llmExtras?.sourceCodeUrl;

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

  final catalogForumUrl = mod.urls?[ModUrlType.Forum];

  return CatalogMod(
    entry: mod,
    title: title,
    authors: authorsList,
    partOfThreadTitle: mod.isPartOfThread ? forumIndex?.title : null,
    authorTitle: authorTitle,
    authorPostCount: authorPostCount,
    authorAvatarPath: avatarPathResolved,
    summaryText: _asPlainText(extras?.summary ?? mod.summary),
    descriptionText: _asPlainText(mod.description),
    modInfoText: _asPlainText(modInfoDescription(installedMod)),
    aiSentence: _asPlainText(llmExtras?.summary?.sentence),
    aiParagraph: _asPlainText(llmExtras?.summary?.paragraph),
    llmMod: llmMod,
    changelog: llmExtras?.changelog,
    supportLinks: llmExtras?.supportLinks ?? const [],
    saveCompatibility: llmExtras?.saveCompatibility,
    sourceCodeUrl: sourceCodeUrl,
    // Forum posts write `&nbsp;` where they mean a space; the app shows the
    // license as-is, so the code turns it back into one here.
    licenseText: trimmedOrNull(llmExtras?.license?.replaceAll('&nbsp;', ' ')),
    catalogImage: mainImage,
    category: category,
    postDate: postDate,
    lastEditDate: lastEditDate,
    views: forumIndex?.views,
    replies: forumIndex?.replies,
    lastPostDate: forumIndex?.lastPostDate,
    topicUrl:
        forumIndex?.topicUrl ?? (forumDetails != null ? catalogForumUrl : null),
    isWip: forumIndex?.isWip ?? false,
    isArchived: forumIndex?.isArchivedModIndex ?? false,
    attributeKeys: _buildAttributeKeys(
      mod,
      forumIndex,
      sourceCodeUrl: sourceCodeUrl,
      canAddToSaveAnswer: _canAddToSaveFrom(extras, llmMod),
      isTool: _isToolFrom(extras, llmMod),
    ),
    installedMod: installedMod,
    downloads: llmMod?.downloads ?? const [],
    extras: extras,
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
  final extrasById = ref.watch(catalogExtrasByIdProvider);

  final sw = Stopwatch()..start();
  final result = entries.map((entry) {
    final topicId = catalogForumTopicId(entry);
    final forumIndex = topicId != null ? forumLookup[topicId] : null;
    final installedMod = links.modForEntry(entry);
    return gatherCatalogMod(
      mod: entry,
      forumIndex: forumIndex,
      discordThreads: discordThreadsFor(entry, discordLookup),
      installedMod: installedMod,
      extras: extrasById[entry.id],
    );
  }).toList();
  Fimber.i(
    'catalogModsProvider built ${result.length} mods in ${sw.elapsedMilliseconds}ms',
  );
  return result;
});
