# Design: Add Smart Search to Hullmods Viewer

Follows the established pattern from ships/weapons viewers exactly.

## File Changes

### 1. `lib/hullmod_viewer/hullmods_page_controller.dart`

**Add search field infrastructure:**
- `late List<SearchField<Hullmod>> _searchFields` and `late Map<String, SearchField<Hullmod>> _fieldsByKey` — initialized in `build()` alongside `_filters`.
- `List<SearchFieldMeta> get searchFieldsMeta` — converts fields to UI metadata (same as ships controller).
- `_buildSearchFields()` — returns field definitions for hullmod data.

**Search fields to define:**
- String: `tier` (as string — low/mid/high), `tech` (tech/manufacturer), `mod` (mod name substring), `tag` (CSV tags), `uitag` (UI tags)
- Numeric: `rarity`, `value` (baseValue), `costfrigate`, `costdest`, `costcruiser`, `costcapital`

**Replace `_filterBySearch` with `_applyParsedQuery`:**
- Calls `SearchField.applyQuery()` (same as ships controller).
- Falls back to the existing substring index search when query has no DSL operators.

**Add `submitSearchQuery()`:**
- Persists query to `appSettings.hullmodsSearchHistory` (keep last 10, deduped).

### 2. `lib/hullmod_viewer/hullmods_page.dart`

- Replace `ViewerSearchBox` with `SmartSearchBar` in `_buildToolbar`.
- Remove `SearchController _searchController` field and its disposal.
- Pass `controller.searchFieldsMeta`, history, `initialValue`, `onChanged`, `onSubmitted` to `SmartSearchBar`.
- Add import for `SmartSearchBar`.

### 3. `lib/trios/settings/settings.dart`

- Add `final List<String> hullmodsSearchHistory` field (default `const []`).
- Add constructor parameter.

### 4. Code generation

- Run `dart run build_runner build --delete-conflicting-outputs` after editing the settings model (it uses `@MappableClass`).

## Key Decisions

- **Tier as string field, not numeric:** Hullmod tiers are semantically categories (1/2/3), but searching `tier:2` as a string match is simpler and consistent with how users think about tiers. Could be numeric if preferred — trivial to change.
- **No specs needed:** This is a straightforward port of an existing pattern. The proposal and this design cover it fully.
