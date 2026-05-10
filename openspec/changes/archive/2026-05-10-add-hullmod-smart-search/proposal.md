# Add Smart Search to Hullmods Viewer

## Problem

The hullmods viewer uses a basic substring search (`ViewerSearchBox`), while the ships and weapons viewers already have smart search with field-based filtering, autocomplete, operator support, and search history. This inconsistency means users can't filter hullmods by specific fields like tier, cost, tag, or mod name using the DSL syntax they're already familiar with from other viewers.

## Proposed Solution

Replace `ViewerSearchBox` in the hullmods page with `SmartSearchBar`, following the same integration pattern used by the ships and weapons viewers. Define search fields appropriate to hullmod data (tier, costs, tags, mod, tech/manufacturer, etc.) and wire up query parsing, history persistence, and autocomplete.

## Scope

- Replace the search widget in `hullmods_page.dart`
- Add search field definitions and DSL query support to `hullmods_page_controller.dart`
- Add `hullmodsSearchHistory` to the settings model
- Remove the now-unused `SearchController` from the page

## Non-Goals

- Changing the filter panel or chip filters (those stay as-is)
- Adding new data fields to the Hullmod model
- Changing how search indices are built
