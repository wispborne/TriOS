# Tasks: Ships Smart Search

- [x] Add `shipsSearchHistory` field to `Settings` in `lib/trios/settings/settings.dart` (mirroring `weaponsSearchHistory`)
- [x] Run `build_runner` to regenerate `settings.mapper.dart`
- [x] Add `_buildSearchFields()` to `ShipsPageController` defining all `SearchField<Ship>` entries
- [x] Add `searchFieldsMeta` getter that converts fields via `toMeta()` with the current ship list
- [x] Replace `_filterBySearch()` with DSL-aware `_applyParsedQuery()` using `SearchDslParser`
- [x] Add `submitSearchQuery()` to persist search history to settings
- [x] In `ships_page.dart`, replace `ViewerSearchBox` with `SmartSearchBar` and remove `SearchController`
- [x] Wire `SmartSearchBar` props: `fields`, `recentHistory`, `initialValue`, `onChanged`, `onSubmitted`
- [ ] Test: verify free-text search still works (backward compat) — needs manual UI testing
- [ ] Test: verify field queries like `size:capital_ship`, `op:>100`, `shield:phase`, `-tag:restricted` — needs manual UI testing
