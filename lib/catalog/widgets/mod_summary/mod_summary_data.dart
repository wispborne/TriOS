import 'package:collection/collection.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/thirdparty/dartx/string.dart';

/// Everything the [ModSummaryWidget] can show about a mod, gathered from the
/// three sources we might have: the catalog entry, the forum index
/// entry (stats, dates, LLM data), and — when a post is cached — the rich
/// forum details. Keeps the widget source-agnostic.
class ModSummaryData {
  final String title;
  final String author;
  final String? authorTitle;
  final int? authorPostCount;
  final String? authorAvatarPath;

  /// The forum board/category the topic lives in ("where it's posted").
  final String? category;
  final DateTime? postDate;
  final DateTime? lastEditDate;
  final int? views;
  final int? replies;

  /// The mod's own description text (from the catalog entry), if any.
  final String? authorText;
  final ForumLlmSummary? aiSummary;
  final ForumLlmChangelog? changelog;
  final List<ForumLlmSupportLink> supportLinks;
  final String? saveCompatibility;

  /// The catalog mod, used to render its image. Null when we only have forum
  /// details (no matching catalog entry).
  final CatalogMod? catalogMod;

  /// A preview image from the LLM data, used when [catalogMod] has no image.
  final String? fallbackImageUrl;

  /// The forum topic URL, for opening the author's profile / the post.
  final String? topicUrl;

  const ModSummaryData({
    required this.title,
    required this.author,
    this.authorTitle,
    this.authorPostCount,
    this.authorAvatarPath,
    this.category,
    this.postDate,
    this.lastEditDate,
    this.views,
    this.replies,
    this.authorText,
    this.aiSummary,
    this.changelog,
    this.supportLinks = const [],
    this.saveCompatibility,
    this.catalogMod,
    this.fallbackImageUrl,
    this.topicUrl,
  });

  /// Builds summary data from a catalog entry and its optional forum
  /// index entry. Used for the card tooltip and the catalog-details dialog.
  factory ModSummaryData.fromCatalog(CatalogMod mod, ForumModIndex? index) {
    final llmMod = _resolveLlmMod(mod, index);
    final extras = llmMod?.extras;
    final authors = mod.authorsList?.isNotEmpty == true
        ? mod.getAuthorsDeduplicated().join(', ')
        : (index?.author ?? '');
    return ModSummaryData(
      title: mod.name.isNotEmpty ? mod.name : (index?.title ?? '???'),
      author: authors,
      category: index?.category,
      postDate: index?.createdDate ?? mod.dateTimeCreated,
      lastEditDate: mod.dateTimeEdited,
      views: index?.views,
      replies: index?.replies,
      // Prefer the summary, but fall back to the description when the summary
      // is missing OR blank — an empty string would otherwise hide a real
      // description and make us show the AI text instead.
      authorText: mod.summary.isNotNullOrBlank ? mod.summary : mod.description,
      aiSummary: extras?.summary,
      changelog: extras?.changelog,
      supportLinks: extras?.supportLinks ?? const [],
      saveCompatibility: extras?.saveCompatibility,
      catalogMod: mod,
      fallbackImageUrl: llmMod?.imageUrl,
      topicUrl: index?.topicUrl,
    );
  }

  /// Builds summary data from a cached forum post's details, its optional
  /// index entry, and the matching catalog entry (for the image). Used for the
  /// forum-post dialog.
  factory ModSummaryData.fromDetails(
    ForumModDetails details,
    ForumModIndex? index,
    CatalogMod? mod,
  ) {
    final llmMod = _resolveLlmMod(mod, index);
    final extras = llmMod?.extras;
    return ModSummaryData(
      title: details.title,
      author: details.author,
      authorTitle: details.authorTitle,
      authorPostCount: details.authorPostCount,
      authorAvatarPath: details.authorAvatarPath,
      category: details.category ?? index?.category,
      postDate: details.postDate ?? index?.createdDate,
      lastEditDate: details.lastEditDate,
      views: index?.views,
      replies: index?.replies,
      authorText: mod?.summary.isNotNullOrBlank == true
          ? mod?.summary
          : mod?.description,
      aiSummary: extras?.summary,
      changelog: extras?.changelog,
      supportLinks: extras?.supportLinks ?? const [],
      saveCompatibility: extras?.saveCompatibility,
      catalogMod: mod,
      fallbackImageUrl: llmMod?.imageUrl,
      topicUrl: index?.topicUrl ?? details.title,
    );
  }

  /// Picks the LLM mod entry this summary represents: for a mod bundled in
  /// another mod's thread, the matching entry by name; otherwise the thread's
  /// main mod. Mirrors the card's `_targetLlmMod`.
  static ForumLlmMod? _resolveLlmMod(CatalogMod? mod, ForumModIndex? index) {
    final llm = index?.llm;
    if (llm == null) return null;
    if (mod != null && mod.isPartOfThread) {
      final key = mod.name.toLowerCase().trim();
      return llm.mods.firstWhereOrNull(
            (m) => m.name.toLowerCase().trim() == key,
          ) ??
          llm.mainMod;
    }
    return llm.mainMod;
  }
}
