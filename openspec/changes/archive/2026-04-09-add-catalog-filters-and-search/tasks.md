## 1. Standalone Search Utility

- [x] 1.1 Create `lib/utils/catalog_search.dart` with `compareVersions()` function ported from Starmodder3's `app.js:123-184` (tokenizer, suffix ranking, segment comparison)
- [x] 1.2 Add `normalizeBaseVersion()` function with version alias map (e.g., "0.9.5" → "0.95") and RC/suffix stripping
- [x] 1.3 Add `nameCompare()` function that sorts bracket/symbol-prefixed names to the end
- [x] 1.4 Add `extractCategories(List<ScrapedMod>)` helper returning sorted unique non-empty categories
- [x] 1.5 Add `extractVersionGroups(List<ScrapedMod>)` helper returning `Map<String, Set<String>>` of base version to raw versions, filtered to 3+ mods, sorted newest-first
- [x] 1.6 Add sort function `sortScrapedMods(List<ScrapedMod>, String sortKey)` supporting name-asc, name-desc, date-desc, date-asc, version-desc

## 2. Catalog Page State

- [x] 2.1 Add state fields to `_CatalogPageState`: `String selectedCategory`, `String selectedVersion`, `String selectedSort` (default "name-asc")
- [x] 2.2 Add computed fields for dropdown options: category list, version group map (rebuilt when `allMods` changes)

## 3. Toolbar Dropdowns

- [x] 3.1 Add Category `DropdownButton<String>` to the toolbar Row, after existing tristate filters and before the search box. Default: "All Categories"
- [x] 3.2 Add Game Version `DropdownButton<String>` to the toolbar Row. Default: "All Versions"
- [x] 3.3 Add Sort `DropdownButton<String>` to the toolbar Row with 5 sort options (Name A-Z, Name Z-A, Newest, Oldest, Game Version)
- [x] 3.4 Wire each dropdown's `onChanged` to update state and call `updateFilter()`

## 4. Filter Pipeline Integration

- [x] 4.1 Update `updateFilter()` to apply category filter after search (filter `displayedMods` by `selectedCategory`)
- [x] 4.2 Update `updateFilter()` to apply version filter after category (filter using version group map)
- [x] 4.3 Update `updateFilter()` to apply sort as the final step using `sortScrapedMods()`

## 5. Verification

- [x] 5.1 Run `dart analyze` to ensure no errors
- [x] 5.2 Build and verify the Catalog page renders with all three dropdowns visible in the toolbar
- [x] 5.3 Test category filter: select a category, verify mod list filters correctly
- [x] 5.4 Test version filter: select a version, verify normalization groups variants correctly
- [x] 5.5 Test sort: verify each sort option reorders the list as expected
- [x] 5.6 Test combined filters: apply search + category + version + sort simultaneously
