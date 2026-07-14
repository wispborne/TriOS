# Design

## Background

- The card's description is built in `buildDescription`
  ([scraped_mod_card.dart:343](../../../lib/catalog/scraped_mod_card.dart#L343)):
  `mod.summary ?? mod.description ?? 'No description...yet!'`, rendered as a
  two-line `TextTriOS` whose tooltip shows the same (full) text on overflow.
- The card already receives `ForumModIndex?`, so after
  `parse-llm-forum-data` the AI text is reachable as
  `forumModIndex?.llm?.mainMod?.extras?.summary` (`sentence` + `paragraph`,
  both always present when `summary` exists; 840 of 848 mods have it).
- Catalog settings live on the main `Settings` model
  ([settings.dart:148](../../../lib/trios/settings/settings.dart#L148)) and
  are surfaced in `buildCatalogOverflowButton`
  ([mod_browser_page.dart:1009](../../../lib/catalog/mod_browser_page.dart#L1009)),
  which already renders a labeled radio-style section for
  `CatalogCardClickAction` — the exact pattern to copy.

## Key decisions

### 1. A three-value enum, persisted on `Settings`

New file `lib/catalog/models/ai_summary_mode.dart`:

```dart
@MappableEnum()
enum AiSummaryMode { always, whenNoAuthorText, never }
```

with `label` and `icon` getters for the menu (same shape as
`CatalogCardClickAction`,
[catalog_card_click_action.dart](../../../lib/catalog/models/catalog_card_click_action.dart)).
`Settings` gains `AiSummaryMode catalogAiSummaryMode`, defaulting to
`whenNoAuthorText` — author text keeps priority unless the user opts in
harder, and empty cards get filled.

Draft menu strings (need user sign-off):

- Section header: `AI mod summaries...`
- `Always show` / `Only when the author didn't write one` / `Never show`

### 2. Description selection in the card

```
authorText = mod.summary ?? mod.description        (null when both missing)
aiSummary  = forumModIndex?.llm?.mainMod?.extras?.summary

always           -> aiSummary?.sentence ?? authorText
whenNoAuthorText -> authorText ?? aiSummary?.sentence
never            -> authorText
(all fall through to 'No description...yet!')
```

The card watches `appSettings.select((s) => s.catalogAiSummaryMode)` so
changing the setting re-renders cards immediately.

### 3. Hover shows the AI paragraph

When the displayed text is the AI sentence, the hover tooltip shows the AI
*paragraph* instead of just echoing the sentence. `TextTriOS`'s built-in
tooltip echoes its own text on overflow, so for the AI case wrap the text in
`MovingTooltipWidget.text` with the paragraph and suppress the `TextTriOS`
overflow tooltip (or pass the paragraph as the tooltip text if `TextTriOS`
supports overriding it — check at implementation time). The author-text case
keeps today's behavior exactly.

## Files changed

- `lib/catalog/models/ai_summary_mode.dart` — new enum (+ generated mapper).
- `lib/trios/settings/settings.dart` — `catalogAiSummaryMode` field
  (+ regenerated mapper).
- `lib/catalog/mod_browser_page.dart` — overflow-menu section.
- `lib/catalog/scraped_mod_card.dart` — description selection + tooltip.

## Risks / edge cases

- **No llm data / no summary** (183 topics + 8 mods): every mode falls back
  to author text or the placeholder — never a blank.
- **`always` with no AI summary** still shows author text; the mode is a
  preference, not a filter.
- **Settings migration:** a missing field decodes to the default via the
  constructor default; no migration needed.
- **Tone mismatch:** AI text isn't labeled as AI on the card (proposal
  non-goal). The setting name makes the tradeoff explicit; revisit if users
  find it misleading.
