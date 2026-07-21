# Tasks

## Data layer

- [x] Add `FactionFileData` model (mergeKey, raw json, registersFaction) with dart_mappable, and change `FactionsCachePayload` to hold a list of them. Run build_runner.
- [x] Rework `FactionListNotifier`: parse and cache raw per-source faction files (keep the factions.csv registration check per file), bump `schemaVersion` to 6, delete the `_vanillaFactionJsonCache` / `_factionListOwnership` globals and in-scan merging, attach `ModVariant` references in `rehydratePayload`.
  - Each file stores its own `sourceName` / `sourceSmolId` instead, so nothing needs rehydrating and the mod variant is looked up once during the merge.
- [x] Add `mergedFactionListProvider` family (bool `onlyEnabledMods`): group raw files by mergeKey in load order, filter out non-enabled mods' files when the flag is on (vanilla always kept), merge with `mergeFactionJson`, build `Faction`s with attributions, drop factions with no included registering source.
  - Source order is worked out from the mod list rather than the scan order, so a vanilla cache miss can't shuffle the merge.
  - Files that *no* source claims in factions.csv are kept, so the toggle-off result matches the old behavior exactly.
- [x] Migrate consumers off the notifier's item list: `faction_viewer_controller.dart`, `codex_index.dart`, `sector_map_manager.dart` (flag false), `context_menu_items.dart` (flag false). Confirm loading states and the refresh button still work.

## Spawn weights

- [x] Make `mergedShipRolesProvider` a family (bool): filter to enabled mods when on.
- [x] Thread the flag through `_spawnWeightContextProvider` and the spawn-weight providers in `spawn_weight_calculator.dart`, and their watch sites in `spawn_weights_view.dart` and `vanilla_share_bar.dart`.
  - `vanilla_share_bar.dart` only holds formatting helpers, so it needed no change.

## UI

- [x] Add persisted `onlyEnabledMods` (default false) to `FactionViewerStatePersisted`; run build_runner.
- [x] Add "Only Enabled Mods" toolbar checkbox (`TriOSToolbarCheckboxButton` + `MovingTooltipWidget.text` tooltip) to the dedicated faction page; wire it to the persisted flag and the data providers.
- [x] Remove the old `showEnabled` `BoolField` from the faction viewer filter panel.
- [x] Wire the codex: `codexIndexProvider` uses `mergedFactionListProvider(codexEnabledModsOnly)`.
  - The codex faction card and hover tooltip take the same flag, so their spawn numbers match the list.
- [ ] Get user sign-off on the checkbox label and tooltip text.
  - Shipped as: label `Only Enabled Mods`, tooltip `Show faction data from enabled mods only. / Ships, weapons, and spawn weights added by disabled mods are hidden.` Awaiting confirmation.

## Verification

- [x] Unit tests: (a) faction registered only by a disabled mod disappears when the flag is on; (b) vanilla faction patched by a disabled mod reverts to vanilla values (including an overwritten scalar like a doctrine number); (c) ship-role weights from a disabled mod are excluded; (d) flag off matches current behavior.
  - `test/faction_viewer/merged_faction_list_test.dart` (7 tests), `test/faction_viewer/merged_ship_roles_test.dart` (3 tests).
- [x] `fvm flutter analyze` and `fvm flutter test` pass.
  - Analyze: no new errors. Tests: 469 passed.
- [ ] User manually verifies both pages: toggle on/off, spawn weights view, faction profile dialog from each page, and that toggling is instant (no rescan).
