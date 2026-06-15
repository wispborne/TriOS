# Proposal: Unify Mods Page Search with SmartSearchBar

## Problem

The Mods page uses a basic Material `SearchBar` with a separate `text_search`-based engine (`FilterModsSearchBar` + `mod_search.dart`). Meanwhile, the Ships, Weapons, and Hullmods pages all use the `SmartSearchBar` widget with field-specific DSL queries, autocomplete, visual pills, and search history.

This means:
- Mods page users can't do field-specific queries like `author:wisp` or `version:0.97`
- No autocomplete, no search history, no visual feedback (pills)
- Two completely different search UX paradigms in the same app
- The existing mod search has useful features (fuzzy matching, author aliases, comma-OR) that aren't accessible through the smart search pattern

## Proposed Solution

Migrate the Mods page to use `SmartSearchBar`, following the same controller pattern already established by Ships, Weapons, and Hullmods. Define mod-specific `SearchField` definitions for fields like name, author, ID, game version, mod version, and enabled status.

## Scope

- Replace `FilterModsSearchBar` with `SmartSearchBar` on the Mods page
- Add a mods page controller (or extend existing state management) to hold search fields, search indices, and history
- Define mod-specific search fields
- Add search history persistence to app settings
- Preserve author alias resolution as part of the `author` field matching
- Plain-text fallback uses the existing search index approach (substring matching on all fields)

## Non-Goals

- Porting the `text_search` fuzzy/penalty-based scoring into SmartSearchBar (the other viewer pages don't have it and users haven't needed it)
- Changing how the Mods page grid filtering works beyond the search box swap
- Changing the SmartSearchBar widget itself
- Adding smart search to the Catalog page (separate effort)

## Fuzzy Matching Preservation

The current mods search uses `text_search` with penalty-based fuzzy scoring (slugified names, acronyms, name parts). SmartSearchBar uses exact substring matching for plain-text queries. To preserve fuzzy-like behavior, we'll enrich the mod search index with the same extra terms that `createSearchTags()` currently generates:
- Slugified mod name (e.g., "Grand Sector" → "grand-sector")
- Name parts split by hyphens (e.g., "grand", "sector")
- Name acronym (e.g., "gs")
- Author aliases from `Constants.modAuthorAliases`

These get added to the search index as additional lowercased values, so plain-text queries like "gs" still match "Grand Sector" via substring matching on the acronym entry.
