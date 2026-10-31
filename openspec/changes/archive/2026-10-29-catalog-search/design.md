# Design: Better Catalog search

The rules are in `specs/catalog-search/spec.md`. This file covers where the code goes and the choices behind it.

## The search engine

A new file, `lib/catalog/catalog_text_search.dart`, holds a straight port of Starmodder's `site/search.js`. It keeps the same parts, so the two are easy to compare when one of them changes:

- `normalizeSearchText` — the clean-up.
- `editDistance` — spelling distance, with the early stop at a limit.
- `CatalogSearchFacts` — the facts for one mod: the list of scored terms, the cleaned names, the name word lists used for shorthand, and the words used for close spellings.
- `CatalogSearchQuery` — the typed text, read once into comma groups of wanted and unwanted pieces. It has `isEmpty`, `hasWanted`, and `score(CatalogMod)`, which is below zero when the mod should not be listed.
- `searchCatalogMods(mods, text)` — returns a `CatalogSearchResult` with the matching mods and a score for each. It replaces today's function of the same name in `lib/utils/mod_search.dart`.

The pieces are small classes, not records, per the project rule. A piece is one of `WordPiece`, `PhrasePiece`, `FieldPiece` or `FlagPiece` under a sealed `SearchPiece`.

Facts are kept in an `Expando<CatalogSearchFacts>` on the `CatalogMod`. That matches Starmodder's `WeakMap` keyed on the mod itself. It is better than today's cache keyed on the mod's name, which mixes up two mods that share a name. When the catalog is rebuilt, the new `CatalogMod` objects get new facts.

The Mods page search (`searchMods`, `createSearchTags`) in `mod_search.dart` is not touched. The old catalog-only functions, `getCatalogModSearchTags` and `createCatalogModSearchTags`, are removed with their cache once nothing uses them.

### Where facts come from

| Fact | Source today | Source once `catalog-extras-data` lands |
|---|---|---|
| Shown name | `CatalogMod.title` | `displayName` from the extras file |
| Catalog name | `entry.name` | same |
| Nicknames | `ForumLlmMod.nicknames` (new field) plus `catalogNicknames` (new constant) | same |
| Authors | `entry.authorsList` | same |
| Other author names | `getModAuthorAliases` | `otherAuthorNames` from the extras file, falling back to `getModAuthorAliases` |
| Categories | `entry.categories` | the cleaned categories plus the raw ones |
| Versions | `entry.gameVersionReq`, `entry.modVersion` | same |
| Summary | `summaryText`, plus `aiSentence` while AI summaries can show | same |
| Description | `entry.description` | same |
| Links | `entry.urls` values plus `downloads[].url` | same |

`catalogNicknames` is a `Map<String, List<String>>` keyed by catalog mod id. It goes in `lib/trios/constants.dart` next to `modAuthorAliases`, with the four entries from Starmodder's `nicknames.js`.

The search code asks `CatalogMod` for these through getters, not by reaching into the models. When `catalog-extras-data` lands, it changes the getters and the search picks the new data up without changes.

### The has: / is: flags

Each flag reads one `CatalogMod` getter:

- `source` → `sourceCodeUrl != null`. This is the same rule as the "Has Source Code" filter.
- `download` → `attributeKeys.contains(kAttrDownload)`. This is the same rule as the "Has Download Link" filter. Starmodder also counts AI-found direct links. TriOS keeps its own rule so the search and the filter agree.
- `wip` → `isWip`.
- `addable` → new `canAddToSave` getter: true when `extras.canAdd` is "yes".
- `tool` → new `isTool` getter, from `ForumLlmMod.isTool`.
- `ai` / `noai` → new `usesAi` getter (`bool?`), from `extras.aiUse.usesAi`.

**Decision: the last three work from the details file now.** The facts are already in `mod-catalog-details.json`, which TriOS downloads. They are not read today only because the models have no field for them. Adding three fields is a small change, and it means the flags work as soon as this change ships, instead of matching nothing until `catalog-extras-data` lands. When that change lands, it makes these getters prefer the extras file.

The model changes, in `lib/catalog/models/forum_llm_data.dart`:

- `ForumLlmMod`: add `List<String>? nicknames` and `bool? isTool`.
- `ForumLlmExtras`: add `String? canAdd` and `CatalogAiUse? aiUse`.
- New `CatalogAiUse` (in `lib/catalog/models/catalog_extras.dart`) holding the whole AI-use record: `usesAi`, `uses` (as `CatalogAiUseEntry`: area, how, extent, optional), `tools` and `quote`. The search only reads `usesAi`, but the AI filter in `catalog-filters-and-sort` needs the rest, and the extras file uses the same shape.

These are `@MappableClass` models, so `build_runner` must run. This change lands before `catalog-extras-data` and `catalog-filters-and-sort`, so it owns these fields. The later changes reuse them.

### AI text and the AI switch

The AI sentence is searched only while `effectiveCatalogAiSummaryModeProvider` is not `AiSummaryMode.never`. The controller already watches settings. It passes a `searchAiText` flag into fact building, and facts are rebuilt when that flag changes. Otherwise turning AI off would leave matches that the user cannot see the reason for.

## Best match sort

`CatalogSortKey` gets a new value, `bestMatch('Best match')`. Its `defaultAscending` is false.

`CatalogPageState` gets three new fields:

- `sortBeforeSearch` (`CatalogSortKey?`) and `sortAscendingBeforeSearch` (`bool`) — the sort kept aside when Best match took over.
- `sortChosenWhileSearching` (`bool`) — true once the user picks a sort by hand while there is text.

`updateSearchQuery` follows the spec's switching rules. It compares the old and new text, as Starmodder's `browse.js` does (around line 507). `setSort` sets `sortChosenWhileSearching` when the search box has text.

`sortCatalogMods` gets the scores from the search result. For `bestMatch` it sorts by score, then by `nameCompare`, then by catalog id. `_processAllFilters` keeps its order: search, then chips, then other filters, then sort. It just keeps the scores from the search step for the sort step.

The page:

- The sort dropdown lists `bestMatch` only while the search box has text.
- `TriOSDropdownMenu` is built with `initialSelection`, which does not follow later changes. The dropdown gets a key based on the selected sort, so it redraws when the controller switches the sort.
- The direction button is disabled for Best match, with the tooltip "Best match is always best first".

**The remembered sort (`catalog-filters-and-sort`):** it saves the sort only when it is not `bestMatch`. When the sort is Best match, it saves `sortBeforeSearch` instead. On load, a saved `bestMatch` (which should never happen) is treated as the default sort. This change does not save anything. It only adds a note to that change's tasks.

## The search box

### How SmartSearchBar fits

`SmartSearchBar` and Starmodder's search both read `key:value`, `-key:value` and `key:"two words"`. Plain words and quotes also work the same way. Two things in `SmartSearchBar` break Starmodder's rules:

1. **Pills move fields to the front.** The bar takes every `key:value` piece out of the text, shows it as a pill, and rebuilds the query as all pills followed by the remaining text (`_fullQuery`). Commas make order matter. "kol, author:wisp" would become "author:wisp kol,", which asks a different question.
2. **Commas are not separators.** The bar splits only on spaces. In "kol,author:wisp" it would read the field name as "kol,author".

**Decision: add an option to turn pills off, rather than teaching pills about commas.** With pills off, the text is passed through as typed. Suggestions still work. The bar's parser stays as it is for every other page. The Catalog's own reader, in `catalog_text_search.dart`, does the real reading.

The new `SmartSearchBar` parameters, in `lib/widgets/smart_search/smart_search_bar.dart`:

- `useFieldPills` (`bool`, default true). When false:
  - `_tryCommitLastToken` and `_commitAllFieldTokens` do nothing.
  - `_fullQuery` is `_controller.text`.
  - `_updateSuggestions` takes the piece being typed as the text after the last space or comma. Choosing a suggestion replaces only that piece.
- `helpBuilder` (`WidgetBuilder?`). When set, `_showInfoPanel` shows its content instead of the field reference.

The Mods page and the ship, weapon, hullmod and faction viewers don't set either parameter, so they are unchanged.

### The Catalog's fields

`buildSearchBox` in `lib/catalog/catalog_page.dart` builds a `SmartSearchBar` with pills off and an empty `recentHistory`. The `/` key already works, because `SmartSearchBar` wraps itself in `SearchHotkey`.

The fields list is a list of `SearchFieldMeta`, built in the controller from the loaded mods:

| Key | Value suggestions |
|---|---|
| `name` | none |
| `author` | every author |
| `category` | every category |
| `version` | the game-version groups from `extractVersionGroups` |
| `modversion` | none |
| `from` | `forum`, `index`, `discord`, `nexus` |
| `url` | none |
| `summary` | none |
| `has` | `source`, `download`, `ai` |
| `is` | `wip`, `tool`, `addable`, `noai` |

The plural and old spellings (`authors`, `gameversion`, `source`, …) work when typed but are not suggested, to keep the list short.

### Help panel text

The user asked for Starmodder's help panel wording, used as-is. The only change is the first line, which adds "descriptions and links" because TriOS also searches those. The field descriptions shown next to each suggestion still need the user's sign-off.

> Searches mod names and nicknames, authors, categories, versions, summaries, descriptions and links.
>
> **Words** — every word must match, in any order: `battlestar portrait`
> **Exact phrase** — in quotes: `"unknown contact"`
> **OR** — comma-separated: `faction, portrait` matches either term
> **Exclude** — prefix with `-` to hide results, e.g. `pirate -junk` or `faction, -portrait`
> **Abbreviations** — e.g. `swp`, `kol` or `indevo` work
> **Versions** — e.g. `0.98` matches mods for that release
> **Field search** — `key:value` syntax, e.g. `author:Wisp`, `category:weapons`, `version:0.97`, `from:discord`
> **Has / is** — `has:source`, `has:download`, `is:addable`, `is:wip`, `is:tool`, `has:ai`, `is:noai`; add `-` to exclude: `-is:wip`

## Speed

There are about 3,000 catalog mods. Facts are built once per mod. A keystroke scores every mod against a few pieces. Close spellings compare only against name and author words, and stop early once over the limit. Starmodder does the same work in a browser on every keystroke. If typing feels slow on the Catalog, the first fix is to cache the read query and skip mods already ruled out by a cheaper piece. This should be measured before anything is added.

## Files that change

- `lib/catalog/catalog_text_search.dart` — new. The search engine.
- `lib/utils/mod_search.dart` — remove the old catalog search and its cache.
- `lib/utils/catalog_search.dart` — `CatalogSortKey.bestMatch`; `sortCatalogMods` takes the scores.
- `lib/catalog/catalog_page_controller.dart` — Best match switching, the scores passed to the sort, the search field list, the AI-text flag.
- `lib/catalog/catalog_page.dart` — `SmartSearchBar` in place of `SearchBar`, the dropdown key, the help content, disabling the direction button.
- `lib/catalog/models/catalog_mod.dart` — getters for nicknames, other author names, `isTool`, `canAddToSave`, `usesAi` and the link list.
- `lib/catalog/models/forum_llm_data.dart` — new fields, the new `CatalogAiUse` and `CatalogAiUseEntry` classes, and regenerated mappers.
- `lib/trios/constants.dart` — `catalogNicknames`.
- `lib/widgets/smart_search/smart_search_bar.dart` — `useFieldPills` and `helpBuilder`.
- `test/catalog/catalog_text_search_test.dart` — new.
- `test/catalog/catalog_best_match_sort_test.dart` — new.
