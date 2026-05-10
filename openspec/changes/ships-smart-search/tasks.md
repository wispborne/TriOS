# Tasks: Ships Smart Search

- [ ] Add `shipsSearchHistory` field to `Settings` in `lib/trios/settings/settings.dart` (mirroring `weaponsSearchHistory`)
- [ ] Run `build_runner` to regenerate `settings.mapper.dart`
- [ ] Add `_buildSearchFields()` to `ShipsPageController` defining all `SearchField<Ship>` entries
- [ ] Add `searchFieldsMeta` getter that converts fields via `toMeta()` with the current ship list
- [ ] Replace `_filterBySearch()` with DSL-aware `_applyParsedQuery()` using `SearchDslParser`
- [ ] Add `submitSearchQuery()` to persist search history to settings
- [ ] In `ships_page.dart`, replace `ViewerSearchBox` with `SmartSearchBar` and remove `SearchController`
- [ ] Wire `SmartSearchBar` props: `fields`, `recentHistory`, `initialValue`, `onChanged`, `onSubmitted`
- [ ] Test: verify free-text search still works (backward compat)
- [ ] Test: verify field queries like `size:capital_ship`, `op:>100`, `shield:phase`, `-tag:restricted`
