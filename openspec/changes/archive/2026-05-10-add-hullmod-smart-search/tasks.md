# Tasks: Add Smart Search to Hullmods Viewer

- [x] Add `hullmodsSearchHistory` field to `Settings` in `lib/trios/settings/settings.dart`
- [x] Run `dart run build_runner build --delete-conflicting-outputs` to regenerate mapper
- [x] Add `_searchFields`, `_fieldsByKey`, and `searchFieldsMeta` getter to `HullmodsPageController`
- [x] Add `_buildSearchFields()` method with hullmod-appropriate fields (tier, tech, mod, tag, uitag, rarity, value, costs)
- [x] Initialize search fields in `build()` (same spot as `_filters` init)
- [x] Replace `_filterBySearch()` with `_applyParsedQuery()` using `SearchField.applyQuery()`
- [x] Add `submitSearchQuery()` to persist history to `appSettings.hullmodsSearchHistory`
- [x] In `hullmods_page.dart`: replace `ViewerSearchBox` with `SmartSearchBar`, remove `SearchController` field and disposal
- [x] Verify the app builds and smart search works on the hullmods page
