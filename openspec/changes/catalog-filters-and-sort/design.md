# Design: New Catalog filters, sorts and card badges

## What already exists

| Piece | Where | Note |
| --- | --- | --- |
| Catalog filter groups | `lib/catalog/catalog_page_controller.dart` `_buildFilters` | Status, Attributes, Game Version, Category |
| Attribute chip keys | `lib/catalog/models/catalog_mod.dart` `_buildAttributeKeys` | `download`, `sourceCode`, `discord`, `index`, `forum`, `wip`, `archived` |
| Range slider | `RangeFilterGroup` in `lib/widgets/filter_engine/filter_group.dart`, drawn by `lib/widgets/range_filter_widget.dart` | Prints numbers, with an optional `suffix` |
| Chip counts | `GridFilterWidget.showCounts` in `lib/widgets/filter_widget.dart` | Counts over the same `items` it builds chips from. The Catalog panel passes all mods and leaves counts off |
| Saved page state | `CatalogPageStatePersisted` in `Settings.catalogPageState` | Holds only `showFilters` |
| Sort | `CatalogSortKey` and `sortCatalogMods` in `lib/utils/catalog_search.dart` | Default Popular, most first. Not saved |
| Extras record and fallbacks | `catalog-extras-data` change | `CatalogMod.extras`, and the getters `categories`, `requiredMods`, `optionalMods`, `canAddToSaveAnswer`, plus `catalogExtrasAvailableProvider` |

## 1. Values on `CatalogMod`

`catalog-extras-data` adds the getters above. This change adds four more, next to them, in the same style: the extras record first, then a fallback.

| Getter | From the extras | Fallback |
| --- | --- | --- |
| `isTool` | `extras.isTool` | AI answer `isTool` |
| `aiUse` | `extras.aiUse` | AI answer `extras.aiUse` |
| `postedDay` | `extras.addedOn` | `postDate` |
| `editedDay` | `extras.editedOn` | `postedDay` |
| `lastReleaseDay` | `extras.lastReleaseDate` | none |

- **The AI answer fields.** `ForumLlmMod` doesn't read `isTool`, and `ForumLlmExtras` doesn't read `aiUse`, so `catalog-search` adds both to `lib/catalog/models/forum_llm_data.dart`, with the full `CatalogAiUse` class. This change reuses them.
- **Day numbers.** The three date getters return a whole day number: days since 1970-01-01, in UTC. A slider over day numbers has one stop per day that some mod actually has.
- **Before `catalog-extras-data` lands.** If this change lands first, it adds the `extras` field as null, and every getter uses its fallback.

## 2. Filter engine additions

All three are optional. Pages that don't use them don't change.

**Date labels on range sliders.** `RangeFilterGroup` gets `valueLabel: String Function(num)?`. `RangeFilterWidget._format` calls it when set, and drops the suffix. The Catalog passes a formatter that turns a day number into "14 Mar 2024" (`DateFormat.yMMMd()`). The existing "and above" rule (`allowGreater`) means a handle at the far right keeps mods posted after the data was loaded.

**An excluded chip that means "said no".** `ChipFilterGroup` gets two parameters:
- `explicitNoValues: Set<String>`: chip values that have a "said no" meaning.
- `explicitNoGetter: List<String> Function(T)?`: for an item, the values it said no to.

When one of those chips is excluded, `matches` keeps only items whose `explicitNoGetter` lists it. The usual exclude veto would show "no" and "unknown" together, and 9 in 10 mods are unknown. Pages that don't set these parameters behave exactly as before.

**Counts from a second list.** `FilterGroupRenderer` and `GridFilterWidget` get `countItems: List<T>?`. When set, `_valueCounts` is counted from it. The chip list itself is still built from `items`, so a chip doesn't vanish when another filter takes its count to 0.

**A page-defined group.** `CustomFilterGroup<T>` joins the sealed `FilterGroup` family. The page supplies these callbacks:
- `matches`, `isActive`, `activeCount`
- `serialize`, `restore`, `clear`
- `buildBody(BuildContext, VoidCallback onChanged)`

`FilterGroupRenderer` draws it in the same card as a composite group, with a lock button, and puts the page's widget inside. The controller treats it as a non-chip group, so `applyNonChipFilters` already covers it. The AI use filter needs this group type. Its rule reads the preset, mode, parts, level and optional switch together. A `CompositeFilterGroup` can't express that, because it ANDs independent fields.

## 3. The new Catalog groups

All of these are in `_buildFilters` in `catalog_page_controller.dart`. Panel order: Status, Attributes, Game Version, Category, Requires, AI use, Posted, Last edited, Last release.

**Attributes.** Two new keys:
- `safeToAdd`, added when `canAddToSaveAnswer` is "yes".
- `tool`, added when `isTool` is true.

Both go after `sourceCode` in `_kAttributeOrder`. The group sets `explicitNoValues: {kAttrSafeToAdd}`, and its `explicitNoGetter` returns `[kAttrSafeToAdd]` when `canAddToSaveAnswer` is "no". `_buildAttributeKeys` takes the two new values as parameters, the way it already takes `sourceCodeUrl`.

**Category.** `valuesGetter` changes from `m.entry.categories` to `m.categories`.

**Requires.** A `ChipFilterGroup`, collapsed by default.
- A new pure function, `requiresChipKeys(CatalogMod)`, in `lib/catalog/catalog_requires.dart`:
  - It returns one key per required mod: the catalog id when there is one, otherwise the name with case, spaces and punctuation removed.
  - It returns `kRequiresStandalone` when the mod has an AI answer or an extras record and no required mods.
  - It returns nothing otherwise.
- The controller rebuilds two maps whenever `allMods` changes:
  - key to label: the catalog entry's name for an id, otherwise the most common spelling
  - key to how many mods need it
- `sortComparator` puts Standalone first, then sorts by count (highest first), then by label.

**AI use.** A `CustomFilterGroup`.
- **The rules** go in a new `lib/catalog/ai_use_filter.dart`, a direct port of Starmodder's `site/ai_filter.js`:
  - the enums `AiUsePreset`, `AiUseMode` and `AiUseLevel`
  - an `AiUseFilterSettings` class: preset, mode, parts, level, `skipOptional`, `wholeOnly`
  - the functions `withPreset`, `isOn` and `keepsForAi`
  - the area list and groups
  - It's pure Dart with no Flutter imports, so the Starsector JS tests can be ported one for one.
- **The controls** go in `lib/catalog/widgets/ai_use_filter_controls.dart`:
  - the presets as a `TriOSRadioTile` list
  - and, for Custom only:
    - the two mode radios
    - the parts as `CheckboxWithLabel`s, with a tristate checkbox per group
    - the level radios
    - the optional switch
- **Saving.** It's saved under its lock as a plain map: preset, mode, part list, level, `skipOptional`.
- **No counts.** The group has no counts in this change.
- **The AI switch.** It's not gated on `enableAiFeatures`.

**Dates.** Three `RangeFilterGroup`s, `posted`, `edited` and `released`, with `valueGetter`s `postedDay`, `editedDay` and `lastReleaseDay`.
- The controller calls `_filters.updateRanges(allMods)` on each build, as the ships page does.
- Last release is left out of the list when `catalogExtrasAvailableProvider` is false. The controller watches that provider, and rebuilds the group list when it changes.
- Last release and Last edited have a tooltip next to their name. If the range header can't take a tooltip, add one, the same way `BoolField.tooltip` works.

## 4. Live counts

`_processAllFilters` already runs search, then chips, then non-chip filters. After the search, it now also builds a count list for each of the three chip groups (Attributes, Category, Requires): the searched mods that pass every *other* group.

- The lists go in a new `CatalogPageState.countItemsByGroup` field, marked `SkipSerializationHook`.
- `CatalogFiltersPanel` passes `showCounts: true` and `countItems: state.countItemsByGroup[g.id]` to each renderer.
- That's three extra passes over about 3,000 mods per change. That's small next to the search itself. If it shows up as slow, only rebuild the count lists after the search text stops changing.

## 5. Sort

**Remembered.**
- `CatalogPageStatePersisted` gets `String? sortKey` and `bool? sortAscending`.
- The key is stored by enum name and read back with `CatalogSortKey.values.asNameMap()`. An unknown name falls back to Popular, most first.
- `setSort` and `toggleSortDirection` call `_persistUiState`, which gets wider.
- `build` reads the saved sort into the first `CatalogPageState`.
- `_persistUiState` skips writing while the sort is "Best match", which `catalog-search` adds. If `catalog-search` hasn't landed, there's nothing to skip yet.

**Random.**
- `CatalogSortKey.random('Random')`.
- The controller holds `_shuffleSeed`, picked from `Random()` the first time the controller builds. The controller lives for the whole app run, so the order holds across tab switches.
- `sortCatalogMods` takes an optional `shuffleSeed`. For Random, it sorts by `Object.hash(shuffleSeed, mod.entry.id)`, then by name.
  - A hash per mod, rather than shuffling a list, means filtering or a data refresh never moves one mod relative to another.
  - A new mod lands at a random spot.
- `shuffle()` on the controller picks a new seed and re-sorts.
- In `catalog_page.dart`, the direction arrow is swapped for a Shuffle `IconButton` (`Icons.shuffle`) while Random is picked. Direction means nothing for Random.

## 6. Card

In `lib/catalog/catalog_mod_card.dart`, the name `Row` already has `spacing: 4` and a `Flexible` name.
- **Badges.** After the name come up to three `_CardBadge`s: mod version, WIP, Tool.
  - Each is a small rounded outline, 16 px tall, in `labelSmall` at size 10, inside a `MovingTooltipWidget.text`.
  - The name shrinks first. The badges don't.
- **Height.** The name line is already as tall as a badge, so the card stays 140 px.
- **Tags.** `Tags` takes the `CatalogMod` instead of the `ModRepoEntry`, so it can read `categories`. Its only caller is the card.

## 7. Text for sign-off

All of this is draft. Most of it starts from Starmodder's wording. Nothing here is final until the user approves it.

| Where | Text |
| --- | --- |
| Attributes chip | Safe to add mid-game |
| ⤷ tooltip, included | Only mods the author says are safe to add mid-game. |
| ⤷ tooltip, excluded | Only mods the author says are not safe to add mid-game. |
| Attributes chip | Tool |
| ⤷ tooltip | Programs that run outside the game, like editors and mod managers. |
| Group | Requires |
| ⤷ chip | Standalone |
| ⤷ Standalone tooltip | Mods that need no other mods. |
| Group | AI use |
| ⤷ presets | Show everything · No AI · Absolutely no AI · No AI images · No vibecoded mods · Custom |
| ⤷ No AI tooltip | Hide mods whose author says AI was used. Mods that say nothing are kept. |
| ⤷ Absolutely no AI tooltip | Only show mods whose author says no AI was used. |
| ⤷ No vibecoded mods tooltip | Hide mods whose code was written entirely by AI. |
| ⤷ Custom modes | Don't show AI-gen… · Only show AI-gen… |
| ⤷ Custom parts | Art: Portraits, Illustrations, Sprites, Icons · Sound: Music, Voice · Text: Writing, Translation · Code · Other |
| ⤷ Custom level label | If AI did: |
| ⤷ Custom levels | all of the work · some, but edited by a human · anything at all |
| ⤷ Custom switch | Ignore if AI content is optional |
| Group | Posted |
| Group | Last edited |
| ⤷ tooltip | The last time the author edited the mod's post. A post that was never edited counts from the day it was posted. |
| Group | Last release |
| ⤷ tooltip | Releases are sometimes missed. |
| Sort | Random |
| Shuffle button tooltip | Shuffle |
| Card badge tooltips | Mod version · Work in progress · Tool: runs outside the game |

The chip widget shows "Included" / "Excluded" as its tooltip today. The per-state tooltips for Safe to add need an optional per-value tooltip on `ChipFilterGroup`, or a fixed tooltip that covers both states. Pick one when building. The simpler fixed tooltip is fine if the user agrees to it.

## Files that change

- `lib/widgets/filter_engine/filter_group.dart`: `valueLabel`, `explicitNoValues` / `explicitNoGetter`, `CustomFilterGroup`.
- `lib/widgets/filter_engine/filter_group_renderer.dart`: render `CustomFilterGroup`, pass `countItems`.
- `lib/widgets/range_filter_widget.dart`: use `valueLabel`.
- `lib/widgets/filter_widget.dart`: `countItems`.
- `lib/catalog/models/forum_llm_data.dart`: `ForumLlmMod.isTool`, `ForumLlmExtras.aiUse`. Regenerate the mapper.
- `lib/catalog/models/catalog_mod.dart`: the new getters, and the new attribute keys.
- `lib/catalog/catalog_requires.dart` (new): Requires chip keys.
- `lib/catalog/ai_use_filter.dart` (new): the AI use rules.
- `lib/catalog/widgets/ai_use_filter_controls.dart` (new): the AI use controls.
- `lib/catalog/catalog_page_controller.dart`: new groups, counts, saved sort, Random. Regenerate the mapper.
- `lib/catalog/widgets/catalog_filters_panel.dart`: counts.
- `lib/utils/catalog_search.dart`: `CatalogSortKey.random`, `shuffleSeed`.
- `lib/catalog/catalog_page.dart`: Shuffle button.
- `lib/catalog/catalog_mod_card.dart`: badges, `Tags`.

## Tests

- `test/catalog/ai_use_filter_test.dart`: port Starmodder's AI filter tests, `Mod_Repo_Scraper/test/site/ai_filter_test.mjs` (run by `ai_filter_test.dart`), case for case.
- `test/catalog/catalog_requires_test.dart`: id keys, name keys, spelling variants sharing a key, the Standalone rule, and a mod with no answer.
- Filter engine: an excluded explicit-no chip keeps only "said no" items, and a group without the parameters is unchanged.
- `sortCatalogMods` with Random: the same seed gives the same order, filtering keeps the relative order, and a new seed changes it.
- Saved sort: round trip through `CatalogPageStatePersisted`, and an unknown name falls back.
- Date getters: Last edited falls back to Posted, and Last release has no fallback.
