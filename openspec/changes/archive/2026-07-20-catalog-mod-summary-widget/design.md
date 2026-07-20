# Design — Catalog Mod Summary Widget

## Data model change

`ForumLlmExtras` (`lib/catalog/models/forum_llm_data.dart`) gains:

```dart
final String? saveCompatibility;
```

The raw QB bundle already has this key inside the `extras` block (verified in the cached `forum_data_bundle.json`: `"saveCompatibility": "Should be fully save compatible with 1.05"`). It's free-form text. Requires `dart run build_runner build --delete-conflicting-outputs`.

Changelog (`ForumLlmChangelog`: `entries` map + optional `link`) and support links (`ForumLlmSupportLink`: `url` + `type`) are already modeled — they're just never displayed.

## New files

### `lib/catalog/widgets/mod_summary/mod_summary_data.dart`

A plain data class that merges the three sources into one view model, mirroring the pattern of `ForumPostHeaderData` (which it replaces):

```dart
class ModSummaryData {
  final String title;
  final String author;            // deduplicated authors, or index author
  final String? authorTitle;      // from ForumModDetails only
  final int? authorPostCount;     //   "
  final String? authorAvatarPath; //   "
  final String? category;         // "where it's posted" — index.category
  final DateTime? postDate;       // details.postDate ?? index.createdDate
  final DateTime? lastEditDate;   // details.lastEditDate
  final int? views;               // index
  final int? replies;             // index
  final String? authorText;       // mod.description ?? mod.summary
  final ForumLlmSummary? aiSummary;
  final ForumLlmChangelog? changelog;
  final List<ForumLlmSupportLink> supportLinks;
  final String? saveCompatibility;
  final CatalogMod? catalogMod;   // for ModImage
  final String? fallbackImageUrl; // llm mainMod imageUrl
  final String? topicUrl;         // author profile / open-in-browser targets
}
```

Two factories, matching the two existing dialog paths:

- `ModSummaryData.fromCatalog(CatalogMod mod, ForumModIndex? index)` — card tooltip and catalog details dialog.
- `ModSummaryData.fromDetails(ForumModDetails details, ForumModIndex? index, CatalogMod? mod)` — forum post dialog.

Both pull LLM extras from `index.llm.mainMod` (same logic the card uses via `_targetLlmMod`: match by mod name, fall back to `mainMod`).

### `lib/catalog/widgets/mod_summary/mod_summary_widget.dart`

`ModSummaryWidget extends ConsumerWidget` taking `ModSummaryData data` and `ModSummaryConfig config`.

```dart
class ModSummaryConfig {
  final bool showImage;
  final bool showAuthor;
  final bool showTitle;
  final bool showCategory;
  final bool showDates;
  final bool showStats;
  final bool showSummary;
  final bool showChangelog;
  final bool showSupportLinks;
  final bool showSaveCompatibility;
  final int maxChangelogEntries; // tooltip: 1, header: 3
  final bool interactive;        // false in tooltip: no buttons/links
  // const presets:
  static const tooltip = ModSummaryConfig(...);
  static const dialogHeader = ModSummaryConfig(...);
}
```

Layout (top to bottom, each section only when its flag is on AND data exists):

1. **Header row**: image (left, capped ~120px in tooltip / ~160px in header, via existing `ModImage` with `fallbackImageUrl`), then a column with title (`TextTriOS`, bold), author chip (reuses the avatar/profile-link presentation from `ForumPostHeader`; non-clickable when `interactive` is false), category + "Posted … • Edited …" line, and stats row (views/replies icons — reuse `_Stats` logic).
2. **Summary text**: same source-selection rules as the card (`AiSummaryMode` from `appSettings`; author text vs. AI sentence/paragraph, with the existing AI-disclosure line when AI text is shown). Tooltip shows the paragraph; header shows it too (it already appears in the dialog body today — see Open questions).
3. **Save compatibility**: one line, save icon + text, e.g. label "Saves:" + the free-form text.
4. **Changelog**: "Latest changes" section header, up to `maxChangelogEntries` newest entries (`entries` map keys are version strings — take them in map order, which follows the post order), each as "version — text" clamped to a few lines; "Full changelog" link when `changelog.link` exists and `interactive`.
5. **Support links**: row of small chips, icon per known `type` (patreon/kofi/paypal/boosty/other), opening the URL; hidden when not `interactive`.

All new icons get `MovingTooltipWidget.text` tooltips. 8dp grid, `spacing` params, dot shorthands per project conventions.

**User-facing strings to review before finalizing** (per feedback memory): "Posted", "Edited", "Saves:" (or "Save compatibility:"), "Latest changes", "Full changelog", "Support the author".

## Changed files

### `lib/catalog/catalog_mod_card.dart`

Wrap the card's main content in `MovingTooltipWidget.framed` with `ModSummaryWidget(config: .tooltip)` (constrained to ~500px wide). Remove the description text's own AI-paragraph tooltip (`MovingTooltipWidget.framed` around `buildDescription`'s text) so tooltips don't stack — the card tooltip now carries the paragraph. Inner tooltips on buttons/icons still win because they're deeper in the tree (`MovingTooltipWidget` at the closest ancestor takes over hover); verify this during implementation.

### `lib/catalog/forum_post_dialog/forum_post_header.dart`

`ForumPostHeader` keeps: the container/bar styling, the action buttons (embedded browser, system browser, full screen, close), and the download section. The info portion (author card, title, dates, `_Stats`) moves into `ModSummaryWidget`. `ForumPostHeader` takes `ModSummaryData` instead of `ForumPostHeaderData` (which is deleted; its factories become the `ModSummaryData` factories).

When the new setting hides the summary: show a slim row of just title + action buttons, downloads below — nothing else.

### `lib/catalog/forum_post_dialog/forum_post_dialog.dart` and `catalog_mod_details_dialog.dart`

Pass `ModSummaryData` to the header. The catalog details dialog's `_Body` currently shows image + description/AI paragraph — with the header now showing image and summary, slim `_Body` down to just the author text (and drop it entirely when it duplicates what the header shows; keep "No description...yet!" for the empty case when the header is off).

### `lib/trios/settings/settings.dart`

New field, following existing catalog-setting naming:

```dart
final bool catalogShowDialogHeaderSummary; // default true
```

Regenerate mappers. Add a toggle on the Settings page next to the existing catalog settings (AI summary mode), label draft: "Show mod info header in dialogs" — string to be reviewed.

## Decisions

- **One widget, two configs** instead of two widgets: the field set is identical; only visibility, sizing, and interactivity differ.
- **Setting only toggles the dialog header summary**, not the card tooltip — that's what was asked; the tooltip is passive and cheap to ignore.
- **`saveCompatibility` as plain string**: the bundle data is free-form prose; no value in parsing it.
- **Changelog entries in map order**: JSON object order in the bundle follows the forum post (newest first in practice); don't try to version-sort free-form keys.

## Open questions (defaults chosen, flag during implementation)

- The dialog body (catalog details) already shows the summary paragraph. Default: header owns image + summary when enabled; body keeps only author description text. If that reads as duplicated, drop summary text from the header config instead.
- Whether the card tooltip should appear over the whole card or exclude the button row (hovering "Install" showing a big tooltip could be noisy). Default: whole card except the actions row.
