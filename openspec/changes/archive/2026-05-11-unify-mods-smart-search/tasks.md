# Tasks: Unify Mods Page Search with SmartSearchBar

- [x] Add `modsSearchHistory` field to settings model (`lib/trios/settings/settings.dart`) and run `build_runner`
- [x] Create `mods_grid_page_controller.dart` with `ModsGridPageController` Notifier — search fields, search indices, query state, history
- [x] Define `_buildSearchFields()` with mod-specific fields (name, id, author with alias support, version, gameversion, enabled)
- [x] Build custom search index that includes slugified name, name parts, acronym, and author aliases (preserving fuzzy matching)
- [x] Replace `FilterModsSearchBar` with `SmartSearchBar` in `mods_grid_page.dart`, wiring to the new controller
- [x] Remove `modsGridSearchQuery` StateProvider and `FilterModsSearchBar` widget (now unused)
- [x] Verify plain-text search, field-specific queries, negation, autocomplete, and history all work on the Mods page
