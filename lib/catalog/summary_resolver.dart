import 'package:trios/catalog/models/ai_summary_mode.dart';
import 'package:trios/catalog/models/catalog_mod.dart';

/// Where a mod's summary text came from. Shown as a small note under the
/// summary so the reader knows who wrote it.
enum ModSummarySource {
  /// The mod index TriOS downloads, which gathers posts from Discord.
  modIndex,

  /// The `mod_info.json` inside the copy of the mod the user has installed.
  modInfoFile,

  /// Written by AI from the mod's forum post.
  ai,
}

/// Which of the author's own texts to try first.
enum AuthorTextOrder { shortFirst, longFirst }

/// Which length of AI text to use.
enum AiTextLength { sentence, paragraph }

/// A resolved block of text and where it came from.
typedef ResolvedText = ({String text, ModSummarySource source});

/// The one block of text to show, and where it came from.
///
/// The caller watches `effectiveCatalogAiSummaryModeProvider` and passes the
/// mode in — the resolver itself never reads a provider.
ResolvedText? resolveSummaryText(
  CatalogMod mod, {
  required AiSummaryMode aiMode,
  required AiTextLength aiLength,
  required AuthorTextOrder authorOrder,
}) {
  final authorText = _pickAuthorText(mod, authorOrder);
  final aiText = aiMode == AiSummaryMode.never
      ? null
      : trimmedOrNull(
          aiLength == AiTextLength.sentence ? mod.aiSentence : mod.aiParagraph,
        );

  final aiResolved = aiText == null
      ? null
      : (text: aiText, source: ModSummarySource.ai);

  final inOrder = aiMode == AiSummaryMode.always
      ? [aiResolved, authorText]
      : [authorText, aiResolved];

  for (final resolved in inOrder) {
    if (resolved != null) return resolved;
  }
  return null;
}

/// The author's own text on its own, for screens that show both blocks.
ResolvedText? resolveAuthorText(
  CatalogMod mod, {
  required AuthorTextOrder authorOrder,
}) => _pickAuthorText(mod, authorOrder);

/// Whether the AI paragraph should be shown beside the author's own text.
bool shouldShowAiWithAuthorText(
  CatalogMod mod, {
  required AiSummaryMode aiMode,
  required bool hasAuthorText,
}) {
  final hasAi =
      mod.aiParagraph != null && mod.aiParagraph!.trim().isNotEmpty;
  if (!hasAi) return false;
  return switch (aiMode) {
    AiSummaryMode.always => true,
    AiSummaryMode.whenNoAuthorText => !hasAuthorText,
    AiSummaryMode.never => false,
  };
}

/// Picks the best author-written text in the requested order, trying summary,
/// description, and mod_info.json. The `modInfoFile` source is only used as a
/// last resort in both orders.
ResolvedText? _pickAuthorText(CatalogMod mod, AuthorTextOrder order) {
  final fromIndex = ModSummarySource.modIndex;
  final fromFile = ModSummarySource.modInfoFile;
  final candidates = switch (order) {
    AuthorTextOrder.shortFirst => [
        (mod.summaryText, fromIndex),
        (mod.descriptionText, fromIndex),
        (mod.modInfoText, fromFile),
      ],
    AuthorTextOrder.longFirst => [
        (mod.descriptionText, fromIndex),
        (mod.summaryText, fromIndex),
        (mod.modInfoText, fromFile),
      ],
  };
  for (final (text, source) in candidates) {
    final trimmed = trimmedOrNull(text);
    if (trimmed != null) return (text: trimmed, source: source);
  }
  return null;
}
