# Tasks

## 1. Text sign-off

- [x] 1.1 Show the user the draft text table in `design.md` section 7. Settle the Safe to add tooltip question. Record the approved wording here before building the UI.
  - Approved 2026-10-29: the table as written, with these changes:
    - No AI tooltip: "Hide if author says AI was used. Also show mods without an AI disclosure."
    - Last edited tooltip: "The post's last edit time (or, if not edited, the post time)."
    - Last release tooltip: "Note: Release tracking can be unreliable."
    - Tool card badge tooltip: "Tool: anything that runs outside the game"
  - The Requires group is named "Dependencies" on screen. Code names still say "requires".
  - Custom level label: "...if AI did..."
  - Range slider reset button tooltip: "Reset" (was "Reset this range"). This is shared by every viewer page.
  - Every filter group now collapses when you click its name, not only chip groups. A collapsed group card shows its active count.
  - The Game Version dropdown and sort use `compareGameVersionOrder`, which reads the part after "0." as a decimal fraction, so 0.65 sorts before 0.7.
  - Safe to add tooltip: per-state. `ChipFilterGroup` gets an optional per-chip tooltip function that reads the chip's state. Tool and Standalone use it too.
- Cleanup after the /simplify review (2026-10-29):
  - Dependencies chips use the catalog's own name key (`catalogNameMatchKey` in `catalog_links.dart`). A name that exactly one catalog mod uses gets that mod's id, so it joins the id's chip.
  - Last release has no special hiding code. Without the extras file no mod has a release date, so the slider has no data and hides itself (task 4.9).
  - Counts come from `FilterScopeController.applyWithCountItems`, which filters and builds every chip group's count list in one pass.
  - `CustomFilterGroup` is abstract. The AI use filter is `AiUseFilterGroup`, which holds its own settings.
  - `ChipFilterGroup` takes one `explicitNoChecks` map instead of `explicitNoValues` plus `explicitNoGetter`.
  - Composite, custom and range groups share one card and header, `CollapsibleFilterCard` (`lib/widgets/collapsible_filter_card.dart`). Chip groups keep their own header.

## 2. Filter engine

- [x] 2.1 Add `valueLabel` to `RangeFilterGroup`, and use it in `RangeFilterWidget._format` and `_rangeLabel` (dropping the suffix when set).
- [x] 2.2 Add `explicitNoValues` and `explicitNoGetter` to `ChipFilterGroup`, and apply them first in `matches`. Test: an excluded explicit-no chip keeps only "said no" items, and a group without them is unchanged.
- [x] 2.3 Add `countItems` to `FilterGroupRenderer` and `GridFilterWidget`. Count from it when set, and keep building chips from `items`.
- [x] 2.4 Add `CustomFilterGroup` to the sealed family, and render it in `FilterGroupRenderer` as a card with a lock and the page's body. Check that `applyNonChipFilters`, `loadPersisted` and `maybePersist` handle it.
- [x] 2.5 Add an optional tooltip to range groups if the header has no way to show one.

## 3. Data on `CatalogMod`

- [x] 3.1 Check that `ForumLlmMod.isTool` and `ForumLlmExtras.aiUse` (full `CatalogAiUse`) exist, added by `catalog-search`. Test them against a real details-file sample.
- [x] 3.2 Add the `isTool`, `aiUse`, `postedDay`, `editedDay` and `lastReleaseDay` getters with the fallbacks in `design.md` section 1. Test each fallback.
- [x] 3.3 Add `safeToAdd` and `tool` attribute keys in `_buildAttributeKeys`.

## 4. Filters

- [x] 4.1 Add the two chips to `_kAttributeOrder` / `_kAttributeLabels` after `sourceCode`, and set `explicitNoValues` / `explicitNoGetter` on the Attributes group.
- [x] 4.2 Switch the Category group to `CatalogMod.categories`.
- [x] 4.3 Write `requiresChipKeys` in `lib/catalog/catalog_requires.dart`, with tests: id keys, name keys, spelling variants, Standalone, and no answer.
- [x] 4.4 Add the Requires group: label and count maps rebuilt when `allMods` changes, Standalone first, then by count, collapsed by default.
- [x] 4.5 Port `site/ai_filter.js` to `lib/catalog/ai_use_filter.dart`. Port `ai_filter_test.mjs` to `test/catalog/ai_use_filter_test.dart`.
- [x] 4.6 Build `ai_use_filter_controls.dart`: presets, and for Custom the modes, parts with group checkboxes, levels and the optional switch.
- [x] 4.7 Add the AI use `CustomFilterGroup`, saved as a plain map, not gated on `enableAiFeatures`.
- [x] 4.8 Add the Posted, Last edited and Last release range groups with the date `valueLabel`, and call `updateRanges(allMods)` on each build.
- [x] 4.9 Hide Last release while `catalogExtrasAvailableProvider` is false.
- [x] 4.10 Build `countItemsByGroup` in `_processAllFilters`, and pass `showCounts` and `countItems` from `CatalogFiltersPanel`.

## 5. Sort

- [x] 5.1 Add `sortKey` and `sortAscending` to `CatalogPageStatePersisted`. Read them in `build`, and save them from `setSort` and `toggleSortDirection`. Regenerate the mapper. Test the round trip and the unknown-name fallback.
- [x] 5.2 Skip saving while the sort is Best match. Skip this if `catalog-search` hasn't landed, and add a line to its tasks instead. While the sort is Best match, save `sortBeforeSearch` and `sortAscendingBeforeSearch` instead. On load, treat a saved `bestMatch` as the default sort.
- [x] 5.3 Add `CatalogSortKey.random` and the `shuffleSeed` parameter to `sortCatalogMods`. Test: same seed same order, filtering keeps the relative order, new seed changes it.
- [x] 5.4 Add `_shuffleSeed` and `shuffle()` to the controller.
- [x] 5.5 Show a Shuffle button in place of the direction arrow while Random is picked.

## 6. Card

- [x] 6.1 Add `_CardBadge`, and put mod version, WIP and Tool badges after the name, with tooltips. Check that a long name shrinks first and the card height is unchanged.
- [x] 6.2 Change `Tags` to take the `CatalogMod`, and list `categories`.

## 7. Specs and checks

- [x] 7.1 Run `fvm flutter analyze` and `fvm flutter test`.
- [ ] 7.2 Ask the user to try the panel by hand. In particular: excluding Safe to add, a Requires exclude, the Last release slider, and Random across a tab switch and a restart.
- [ ] 7.3 Archive with `/opsx:archive` so the delta specs merge into `catalog-filter-panel`, `filter-engine`, `catalog-sort` and `catalog-card-badges`.
