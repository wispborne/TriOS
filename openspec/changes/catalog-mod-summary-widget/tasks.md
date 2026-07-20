# Tasks — Catalog Mod Summary Widget

## 1. Data model

- [x] Add `saveCompatibility` (`String?`) to `ForumLlmExtras` in `lib/catalog/models/forum_llm_data.dart`
- [x] Run `dart run build_runner build --delete-conflicting-outputs` and confirm the field decodes from the cached bundle (spot-check one topic with save-compat text)

## 2. Summary data + widget

- [x] Create `lib/catalog/widgets/mod_summary/mod_summary_data.dart` with `ModSummaryData`, `fromCatalog()`, and `fromDetails()` factories (port the merge logic from `ForumPostHeaderData`)
- [x] Create `lib/catalog/widgets/mod_summary/mod_summary_widget.dart` with `ModSummaryConfig` (per-field flags, `tooltip` and `dialogHeader` presets) and `ModSummaryWidget`
- [x] Build the header row: `ModImage` with fallback, title, author chip (avatar, forum title, post count, profile link when interactive), category + posted/edited dates, views/replies stats
- [x] Build the summary section honoring `catalogAiSummaryMode` (author text vs. AI text, AI-disclosure line)
- [x] Build the save-compatibility line
- [x] Build the changelog section (up to `maxChangelogEntries`, external link when present)
- [x] Build the support-links chip row with per-type icons
- [x] Add `MovingTooltipWidget.text` tooltips to every new icon
- [x] Draft all user-facing strings and get user sign-off

## 3. Card tooltip

- [x] Wrap the catalog mod card content in `MovingTooltipWidget.framed` showing `ModSummaryWidget` with the `tooltip` config
- [x] Remove the description text's AI-paragraph tooltip in `buildDescription` (now redundant)
- [x] Verify inner tooltips (buttons, badges) still take precedence over the card tooltip

## 4. Dialog headers

- [x] Refactor `ForumPostHeader`: replace the info portion with `ModSummaryWidget` (`dialogHeader` config), keep action buttons and download section; delete `ForumPostHeaderData`
- [x] Update `forum_post_dialog.dart` to build `ModSummaryData.fromDetails(...)`
- [x] Update `catalog_mod_details_dialog.dart` to build `ModSummaryData.fromCatalog(...)` and slim `_Body` (drop image + AI paragraph now shown in the header; keep author text / empty-state)

## 5. Setting

- [x] Add `catalogShowDialogHeaderSummary` (default `true`) to `Settings` and regenerate mappers
- [x] Honor the setting in both dialogs: when off, show the slim bar (title + action buttons + downloads)
- [x] Add the toggle to the catalog overflow menu near the AI-summary-mode setting

## 6. Verify

- [x] `fvm flutter analyze` clean (no new issues; two pre-existing warnings in `catalog_mod_card.dart` remain)
- [x] `fvm flutter test` passes (400 tests)
- [ ] User verifies manually: card hover tooltip, both dialogs with header on/off, a mod with changelog + support links + save compat (e.g. the Gun Runners topic), and a sparse mod with none of them
