## Context

The Mod Catalog (`lib/catalog/mod_browser_page.dart`) displays mods from a scraped JSON repository. It currently has 6 tristate icon filters and a text search box. Starmodder3 (`F:\Code\Starsector\Starmodder3\app.js`) is a web app with richer filtering: category dropdown, game version dropdown (with version normalization), sort dropdown, and a tag-based search. The goal is to port these capabilities into the existing Catalog toolbar.

The existing search in `lib/utils/search.dart` already has `searchScrapedMods()` with tag-based matching, positive/negative queries, and author aliases — closely matching Starmodder3's `searchMods()`. What's missing: version comparison, version normalization, sort logic, and the dropdown filter integration.

## Goals / Non-Goals

**Goals:**
- Add Category, Game Version, and Sort dropdowns to the Catalog toolbar
- Create a standalone search/filter utility with version comparison and normalization
- Integrate category/version filtering and sorting into the existing `updateFilter()` pipeline
- Dynamically populate dropdown options from mod data

**Non-Goals:**
- Changing the existing tristate icon filters
- Modifying the scraped mod card layout or right-pane webview
- Adding persistence for filter/sort state (can be added later)
- Fuzzy search — Starmodder3 uses substring matching, not fuzzy

## Decisions

### 1. New file `lib/utils/catalog_search.dart` for version + sort utilities

**Rationale:** Keep `search.dart` focused on tag-based search (shared with mod manager). The new file holds catalog-specific logic: `compareVersions()`, `normalizeBaseVersion()`, `nameCompare()`, sort helpers, and filter population helpers. This avoids bloating the existing search utility.

**Alternative considered:** Adding everything to `search.dart` — rejected because version comparison and sort logic are catalog-specific concerns.

### 2. Use `DropdownButton<String>` widgets in the toolbar

**Rationale:** Flutter's built-in `DropdownButton` matches the existing toolbar style (compact, no extra dependencies). Category and Version dropdowns use `""` as the "All" sentinel value.

**Alternative considered:** `PopupMenuButton` — less appropriate for selection-type filters where the current value should be visible.

### 3. Port version comparison as a standalone Dart function

**Rationale:** Starmodder3's `compareVersions()` handles Starsector's versioning scheme (e.g., `0.97a-RC11`, pre-release suffixes). This logic doesn't exist anywhere in TriOS yet and is needed for both version dropdown grouping and version-based sorting.

### 4. Filter pipeline order: search → category → version → tristate filters → sort

**Rationale:** Matches Starmodder3's pipeline. Category and version filters go before existing tristate filters to reduce the working set early. Sort is always last.

### 5. Version filter groups variants with 3+ mods threshold

**Rationale:** Directly from Starmodder3 — avoids cluttering the version dropdown with obscure version strings that only 1-2 mods target. Uses `normalizeBaseVersion()` to group `0.97a`, `0.97a-RC11`, etc. under `0.97`.

## Risks / Trade-offs

- **Toolbar width**: Adding 3 dropdowns may crowd the toolbar on smaller windows → Mitigation: Use compact `DropdownButton` styling with short labels, wrap if needed
- **Version normalization edge cases**: Starsector version strings can be unusual → Mitigation: Port the exact normalization logic from Starmodder3 which has been battle-tested
- **Performance**: Rebuilding filter options on every data refresh → Mitigation: Only rebuild when `allMods` changes (Riverpod will handle this naturally)
