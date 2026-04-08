## Why

The Mod Catalog page currently only has tristate icon filters (source/installed/update) and basic text search. It lacks category and game version filtering, sort options, and uses a less discoverable search box. Starmodder3 (a companion web app) already implements these features — category dropdown, version dropdown, sort dropdown, and a tag-based search algorithm. Porting these to the Mod Catalog will bring feature parity and improve mod discovery.

## What Changes

- Add a **Category dropdown** filter populated dynamically from mod categories
- Add a **Game Version dropdown** filter with version normalization (grouping variants like "0.97a-RC11" under "0.97")
- Add a **Sort dropdown** with options: Name A-Z, Name Z-A, Newest, Oldest, Game Version
- Extract and create a **standalone search utility** (`lib/utils/catalog_search.dart`) porting the Starmodder3 search algorithm, including version comparison and normalization helpers
- Integrate the new filters and sort into the existing `updateFilter()` pipeline in `mod_browser_page.dart`

## Capabilities

### New Capabilities
- `catalog-dropdowns`: Category, game version, and sort dropdown filters for the Mod Catalog toolbar
- `catalog-search-utility`: Standalone search utility with tag-based search, version comparison, version normalization, and sort logic — ported from Starmodder3

### Modified Capabilities

## Impact

- `lib/catalog/mod_browser_page.dart` — toolbar UI (add dropdowns), `updateFilter()` (add category/version/sort logic), state fields
- `lib/utils/search.dart` — existing scraped mod search functions may be refactored or replaced by the new utility
- `lib/catalog/models/scraped_mod.dart` — no changes expected (already has `categories`, `gameVersionReq`)
