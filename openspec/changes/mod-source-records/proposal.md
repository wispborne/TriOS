## Why

TriOS currently has mod information scattered across multiple disconnected sources: installed mod folders (ModInfo/ModVariant), version checker files (forum thread IDs, Nexus IDs, download URLs), the remote mod catalog (ScrapedMod from ModRepo.json), and user metadata (favorites, colors). There is no persistent record that links all these sources together for a given mod. This means if a user wants to find the forum page for an installed mod, or check if a catalog mod is already installed, the app must re-derive these connections every time. A unified, persistent mod source record would let any part of the app quickly look up all known information about a mod from any single identifier.

## What Changes

- New `ModRecord` data class that consolidates all known source identifiers and metadata for a single mod: mod ID, forum thread ID, Nexus ID, catalog name, download URLs, install paths, version info, and timestamps.
- New persistent JSON file (`trios_mod_records-v1.json`) storing a map of mod records, managed via `GenericAsyncSettingsManager`.
- Auto-population logic that runs on app startup / mod scan to cross-reference installed mods, version checker data, and the mod catalog, building and updating records automatically.
- Action-triggered enrichment: when the user downloads, installs, or browses a mod, capture additional source info into the record.
- Lookup API (Riverpod providers) to query records by mod ID, forum thread ID, Nexus ID, or catalog name.

## Capabilities

### New Capabilities
- `mod-source-records`: Persistent local database of mod source records linking all known identifiers and URLs for each mod. Includes the data model, persistence layer, auto-population, action-triggered enrichment, and lookup providers.

### Modified Capabilities
<!-- No existing spec-level capabilities are changing. -->

## Impact

- **New files**: `lib/mod_records/` feature directory with model, manager, and provider files.
- **Modified files**: Download manager and mod install logic will be updated to write records on download/install. App startup (app_state.dart) will trigger auto-population.
- **Dependencies**: None new — uses existing dart_mappable and GenericAsyncSettingsManager patterns.
- **Data**: New `trios_mod_records-v1.json` file in the app config directory.
