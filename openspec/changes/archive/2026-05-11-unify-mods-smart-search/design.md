# Design: Unify Mods Page Search with SmartSearchBar

## Approach

Follow the exact pattern already used by Ships (`ships_page_controller.dart`), Weapons (`weapons_page_controller.dart`), and Hullmods (`hullmods_page_controller.dart`). Each of those pages:

1. Defines `_buildSearchFields()` returning `List<SearchField<T>>`
2. Exposes `searchFieldsMeta` getter converting fields to `SearchFieldMeta` for the widget
3. Maintains `searchIndices` (Map of item ID to lowercased property values) via `updateSearchIndices()`
4. Has `updateSearchQuery()` and `submitSearchQuery()` methods
5. Persists search history in `appSettings`

The Mods page needs the same, but the page currently doesn't have a dedicated controller — it uses inline providers (`modsGridSearchQuery`, `modsGridSortField`, etc.) in `mods_grid_page.dart`. The cleanest path is to add a lightweight controller.

## Search Fields for Mods

| Field Key | Type | Source | Description |
|-----------|------|--------|-------------|
| `name` | string | `modInfo.name` | Mod name |
| `id` | string | `modInfo.id` | Mod ID |
| `author` | string | `modInfo.author` + aliases | Author name (includes alias resolution) |
| `version` | string | `modInfo.version` | Mod version |
| `gameversion` | string | `modInfo.gameVersion` | Game version compatibility |
| `enabled` | string | `mod.isEnabled` | "true" / "false" |
| `source` | string | mod source info if available | Where the mod came from |

The `author` field's `matches` function should check both the literal author value and `Constants.modAuthorAliases`, preserving the existing alias behavior.

## Key Decisions

**Controller**: Create `mods_grid_page_controller.dart` with a `Notifier<ModsGridPageState>` to hold search state, following the viewer page pattern. Move the existing inline providers (`modsGridSearchQuery`, sort, filter state) into this controller.

**Search index**: Use `updateSearchIndices()` from `lib/utils/search_index.dart` — same as other pages. Build index from `ModVariant.toMap()` or manually from key properties.

**History persistence**: Add `modsSearchHistory` field to app settings, same as `weaponsSearchHistory`, `shipsSearchHistory`, `hullmodsSearchHistory`.

**Author aliases**: The `author` SearchField's `matches` callback will call `getModAuthorAliases()` from `mod_search.dart` to check if the query matches any alias of the mod's author.

**Plain-text fallback**: When the user types without a field prefix, `SearchField.applyQuery()` already falls back to substring matching against the search index. This covers the common "just type a name" use case.

**Fuzzy matching preservation**: The standard `updateSearchIndices()` utility builds the index from an object's `toMap()` values. For mods, we'll override/supplement this with a custom index builder that also includes slugified name, name parts, acronym, and author aliases — mirroring what `createSearchTags()` in `mod_search.dart` currently does. This way plain-text queries like "gs" still match "Grand Sector" via the acronym in the index.

## File Changes

| File | Change |
|------|--------|
| `lib/mod_manager/mods_grid_page_controller.dart` | **New** — Controller with search fields, state, query methods |
| `lib/mod_manager/mods_grid_page.dart` | Replace `FilterModsSearchBar` with `SmartSearchBar`, wire to controller |
| `lib/trios/settings/settings.dart` | Add `modsSearchHistory` field |
| `lib/mod_manager/filter_mods_search_view.dart` | Delete (no longer needed) |

## What Stays the Same

- `mod_search.dart` — Keep for `getModAuthorAliases()` and any other callers (catalog page uses `searchScrapedMods`)
- Grid filtering, sorting, grouping — untouched
- All other filter UI (enabled/disabled toggles, etc.) — untouched
- `modsGridSearchQuery` provider can be removed once the controller owns the search state
