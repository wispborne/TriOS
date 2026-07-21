# Design

## Current architecture (what makes this hard)

`FactionListNotifier` (`lib/faction_viewer/faction_manager.dart`) extends
`CachedStreamListNotifier<Faction, FactionsCachePayload>`. As it scans vanilla +
every installed mod (enabled or not — `resolveEnabledVariants()` in
`lib/viewer_cache/cached_stream_list_notifier.dart:77` uses
`findFirstEnabledOrHighestVersion`), it merges faction JSON **during the scan**
using two module-level mutable maps (`_vanillaFactionJsonCache`,
`_factionListOwnership`). Only the merged `Faction` objects survive; the
per-mod raw data is thrown away. The per-variant disk cache therefore stores
*merged* factions, which also means one variant's cache slice contains data
from other mods — already a bit unsound.

Spawn weights have the same issue independently: `mergedShipRolesProvider`
(`lib/faction_viewer/spawn_weights/ship_roles_manager.dart:62`) merges
`default_ship_roles.json` across all installed mods.

## Approach

### 1. Scanner keeps raw files; merge moves to a provider

- New model `FactionFileData` (dart_mappable): `mergeKey` (relative path under
  `data/world/factions`, the game's merge key), raw `json` map,
  `registersFaction` (whether this source's `factions.csv` lists the key).
  The owning source (vanilla or which `ModVariant`) is implied by which cache
  slice it sits in; `rehydratePayload` attaches the `ModVariant` reference
  after cache decode.
- `FactionsCachePayload` becomes a list of `FactionFileData` instead of merged
  `Faction`s. Bump `schemaVersion` 5 → 6; old cache files are treated as
  misses and rebuilt automatically (no migration).
- `FactionListNotifier` becomes
  `CachedStreamListNotifier<FactionFileData, FactionsCachePayload>`. `itemId`
  includes the source (e.g. `smolId|mergeKey`) so the base class's
  first-occurrence dedup never drops a file. Delete `_vanillaFactionJsonCache`,
  `_factionListOwnership`, and the in-scan merge; `_parseFactionFolder` just
  parses files and the csv keys. `providesItemContext` can go back to false.
- The notifier's yielded list is now raw files in load order (vanilla slice
  first, then mods in game load order — the base class already guarantees
  this), which is exactly the order the merge needs.

### 2. Merged faction list as a family provider

New in `faction_manager.dart`:

```dart
final mergedFactionListProvider =
    Provider.family<List<Faction>, bool>((ref, onlyEnabledMods) { ... });
```

- Watches `factionListNotifierProvider` (raw files) and, when
  `onlyEnabledMods` is true, `AppState.mods` for enabled state.
- Filters: keep vanilla files always; keep a mod's files only if the mod has
  an enabled variant (`Mod.hasEnabledVariant`) when the toggle is on.
- Groups by `mergeKey`, merges in order with the existing `mergeFactionJson`
  (`lib/faction_viewer/faction_merge.dart`), builds `Faction`s with the
  existing `_buildFactionFromJson` + attribution logic (moves largely as-is).
- A faction is kept only if at least one included source has
  `registersFaction == true` — this is how factions from disabled mods
  disappear, and it matches the game's `factions.csv` rule already in place.
- Pure in-memory map merging — cheap enough to recompute on toggle or when
  mods are enabled/disabled. No cache invalidation needed; the cache holds raw
  files that are valid for both toggle states.

Consumers migrate from `factionListNotifierProvider` to the family:

| Consumer | Flag |
|---|---|
| `faction_viewer_controller.dart:114` | page's persisted toggle |
| `codex_index.dart:117` | `codexEnabledModsOnly` setting |
| `spawn_weight_calculator.dart:151,164` | threaded flag (see below) |
| `sector_map_manager.dart:62,73` | `false` (unchanged behavior) |
| `context_menu_items.dart:517` | `false` (unchanged behavior) |

Loading/refresh stay on the notifier: `isLoadingFactionsList`,
`codexCategoryLoadingProvider`, and `ref.invalidate(factionListNotifierProvider)`
(`faction_viewer_page.dart:86`) all keep working.

### 3. Spawn weights respect the toggle

- `mergedShipRolesProvider` → `FutureProvider.family<MergedShipRoles, bool>`;
  when true, filter the variant list to mods with an enabled variant before
  merging `default_ship_roles.json`.
- Thread the flag through `_spawnWeightContextProvider` and the two public
  spawn-weight providers in `spawn_weight_calculator.dart` (make them
  families too), and through their watch sites in `spawn_weights_view.dart`
  (including the `mergedShipRolesProvider` watch at line 419) and
  `vanilla_share_bar.dart`.
- The ship list used for hull/variant lookups (`shipListNotifierProvider`,
  `variantHullIdMapProvider`) stays unfiltered — it only resolves names and
  sizes for ids the (already filtered) faction data references.

### 4. UI wiring

- **Dedicated page**: add `onlyEnabledMods` (default false) to
  `FactionViewerStatePersisted` (`faction_viewer_controller.dart:32`); run
  build_runner for the mapper. Add a `TriOSToolbarCheckboxButton` to the
  toolbar in `faction_viewer_page.dart` with a `MovingTooltipWidget.text`
  tooltip. Remove the now-redundant `showEnabled` `BoolField` from
  `_buildFilters()` (`faction_viewer_controller.dart:151-164`).
- **Codex page**: no new UI. `codexIndexProvider` watches
  `mergedFactionListProvider(codexEnabledModsOnly)`. The existing per-entry
  `_matchesEnabledMods` filter stays for other entry types; for factions it
  becomes a harmless no-op when the toggle is on (filtered factions only have
  vanilla/enabled sources).
- **Faction profile dialog** (`faction_profile_dialog.dart`): takes a
  `Faction` object from its caller (dedicated page at
  `faction_viewer_page.dart:551`, codex at `codex_detail_panel.dart:198`), so
  it automatically shows the data matching that page's toggle.

## Key decisions

1. **Filter at merge time, not display time.** Attributions can tell you who
   added a list item, but a scalar overwritten by a disabled mod (e.g. a
   doctrine number) can't be un-overwritten after the fact. Re-merging from
   raw files is the only correct way, and it also fixes the cache storing
   cross-mod merged data per variant.
2. **Keep scanning all installed mods.** The raw data for disabled mods must
   be on hand so the toggle is instant in both directions. Cache pruning
   (`pruneExcept`) is unchanged.
3. **Reuse the existing checkboxes' meaning** instead of adding a second
   "enabled mods" control per page. On the dedicated page the control moves
   from the filter panel to the toolbar since it now changes the data, not
   just the visible rows.
4. **Schema bump instead of cache migration** — caches rebuild in seconds
   (established project practice).

## Files that change

- `lib/faction_viewer/faction_manager.dart` — scanner refactor + new provider
- `lib/faction_viewer/models/factions_cache_payload.dart` — raw-file payload
- `lib/faction_viewer/models/faction.dart` — add `FactionFileData` (+ mapper regen)
- `lib/faction_viewer/faction_viewer_controller.dart` (+ `.mapper.dart`) — persisted flag, drop `showEnabled` field
- `lib/faction_viewer/faction_viewer_page.dart` — toolbar checkbox
- `lib/faction_viewer/spawn_weights/ship_roles_manager.dart` — family
- `lib/faction_viewer/spawn_weights/spawn_weight_calculator.dart` — thread flag
- `lib/faction_viewer/spawn_weights/spawn_weights_view.dart`, `vanilla_share_bar.dart` — pass flag
- `lib/codex/codex_index.dart` — watch the family
- `lib/sector_map/sector_map_manager.dart`, `lib/trios/context_menu_items.dart` — switch to family with `false`
- Tests under `test/faction_viewer/`
