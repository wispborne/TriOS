# Tasks: Better Catalog search

## 1. Data the search needs

- [x] 1.1 Add `nicknames` and `isTool` to `ForumLlmMod`, and `canAdd` and `aiUse` to `ForumLlmExtras`, with new `CatalogAiUse` and `CatalogAiUseEntry` classes holding the whole AI-use record (`lib/catalog/models/forum_llm_data.dart`, `lib/catalog/models/catalog_extras.dart`). The later catalog changes reuse these.
- [x] 1.2 Run `build_runner` and check the details file still loads (`test/catalog/mod_catalog_files_test.dart`).
- [x] 1.3 Add `catalogNicknames` to `lib/trios/constants.dart`, copied from Starmodder's `site/nicknames.js`.
- [x] 1.4 Add the `CatalogMod` getters the search reads: nicknames, other author names, `isTool`, `canAddToSave`, `usesAi`, and the list of every link.

## 2. The search engine

- [x] 2.1 Create `lib/catalog/catalog_text_search.dart` with `normalizeSearchText` and `editDistance`. Test both against the cases in the spec.
- [x] 2.2 Add `CatalogSearchFacts`, with the facts and costs from the spec, cached in an `Expando` on `CatalogMod`. Include the description and links at cost 45. Include the AI sentence only when asked to.
- [x] 2.3 Add the scoring for one word: exact, starts with, word starts with, contains, and the initials bonus.
- [x] 2.4 Add word-start shorthand, with its limits.
- [x] 2.5 Add close spellings, with their limits.
- [x] 2.6 Add reading the typed text into comma groups of pieces: words, phrases, fields and flags, with minus pieces, the plus sign and unclosed quotes.
- [x] 2.7 Add `field:value` matching for the fields in the spec, plus the plural and old spellings.
- [x] 2.8 Add the `has:` / `is:` flags, reading the `CatalogMod` getters.
- [x] 2.9 Add whole-search scoring: the best group wins, minus-only groups remove mods, and the name bonus applies.
- [x] 2.10 Add `searchCatalogMods`, returning a `CatalogSearchResult` with the mods and their scores. Ties go by name, then catalog id.

## 3. Tests ported from Starmodder

- [x] 3.1 Create `test/catalog/catalog_text_search_test.dart` with small hand-made mods. Cover:
  - "indevo" → Industrial Evolution; "kol" → Knights of Ludd; "swp" → Ship/Weapon Pack ranked first.
  - "faction" does not reach Fleet Action History by shorthand, or "Action" by spelling.
  - "nexerlin" → Nexerelin; "lazt" finds no LazyLib.
  - "graphics lib" → GraphicsLib, through the split at the capital.
  - "pirate -junk"; "-portrait"; "portrait, faction"; `"unknown contact"`.
  - "author:wisp", including an alias; "from:discord"; "category:weapons"; "foo:bar" read as words.
  - "-is:wip"; "has:source"; "is:noai" leaving out mods that say nothing.
  - A description-only match ranks below a name match.
  - The AI sentence is not searched when AI text is off.
  - Two mods with the same name keep their own facts.

## 4. Best match sort

- [x] 4.1 Add `CatalogSortKey.bestMatch` and make `sortCatalogMods` sort by score for it (`lib/utils/catalog_search.dart`).
- [x] 4.2 Add `sortBeforeSearch`, `sortAscendingBeforeSearch` and `sortChosenWhileSearching` to `CatalogPageState`. Run `build_runner`.
- [x] 4.3 In `updateSearchQuery`, switch to Best match when typing starts, and restore the kept sort when the search is cleared. In `setSort`, record a sort picked while searching.
- [x] 4.4 Make `_processAllFilters` call the new search and pass its scores to the sort.
- [x] 4.5 Pass the AI-text flag from `effectiveCatalogAiSummaryModeProvider` into the search.
- [x] 4.6 Create `test/catalog/catalog_best_match_sort_test.dart`: typing picks Best match; clearing restores the sort and direction; a hand-picked sort survives more typing.
- [x] 4.7 Nothing to save here. `catalog-filters-and-sort` lands later and skips saving the sort while it is Best match, so the saved sort stays the one from before the search.

## 5. SmartSearchBar options

- [x] 5.1 Add `useFieldPills` (default true) to `SmartSearchBar`. When false: no pills, the query is the text as typed, and the piece being completed starts after the last space or comma.
- [x] 5.2 Add `helpBuilder` to `SmartSearchBar`. When set, the info button shows it.
- [x] 5.3 Add tests next to `test/widgets/smart_search_bar_navigation_test.dart`: with pills off, "kol, author:wisp" reaches `onChanged` unchanged, and "kol, auth" suggests `author:`. With the default, fields still become pills.

## 6. Catalog page

- [x] 6.1 Build the Catalog's `SearchFieldMeta` list in the controller, with the value suggestions in the design.
- [x] 6.2 Replace the `SearchBar` in `buildSearchBox` (`lib/catalog/catalog_page.dart`) with `SmartSearchBar`: pills off, no history, and the Catalog help content.
- [x] 6.3 List Best match in the sort dropdown only while there is search text. Key the dropdown on the selected sort so it redraws when the sort switches by itself.
- [x] 6.4 Disable the direction button for Best match, with a tooltip.
- [x] 6.5 Show the user every new visible string for sign-off: the field descriptions, the Best match label and the direction-button tooltip. Apply their changes. The help panel text is already approved (`design.md`).

## 7. Clean-up and checks

- [x] 7.1 Remove the old `searchCatalogMods`, `getCatalogModSearchTags`, `createCatalogModSearchTags` and their cache from `lib/utils/mod_search.dart`.
- [x] 7.2 Run `flutter analyze` and the tests.
- [x] 7.3 Ask the user to try the Catalog search by hand, including the speed of typing.
