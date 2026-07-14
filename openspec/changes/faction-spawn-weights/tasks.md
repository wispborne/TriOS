# Tasks — Faction Spawn Weights

## Fixes first (the feature is wrong without these)

- [ ] **Load order.** Sort enabled mod variants by `sortString ?? display name` (case-sensitive `compareTo`) so merges happen in the game's load order. Today `resolveEnabledVariants()` returns mods-folder listing order. Prefer one shared implementation on `CachedStreamListNotifier` over the six copy-pasted ones — but note this also changes the dedup winner in the ship/weapon/hullmod/fighter viewers, so check that before landing.
- [ ] **`1f` float literals.** In `_applyJsonFixups()` (`lib/utils/extensions.dart`), strip a trailing `f`/`F`/`d`/`D` from a number in value position (after `:`, `[`, or `,`). Today `1f` silently becomes the string `"1f"` via the YAML fallback and then parses to null. Add a unit test covering: `"a":1f` → 1, `"a":"1f"` unchanged, `"a":[1f, 2.5f]` → `[1, 2.5]`.
- [ ] **Scalar attribution.** `faction_merge.dart` records attribution only for string items in arrays; the scalar path records none. Add last-write-wins attribution for scalar values, so role weights, `hullFrequency`, and `variantOverrides` can say which mod set them.

## Data layer

- [ ] Add `shipRoles`, `hullFrequency`, and `variantOverrides` fields to the `Faction` model; run build_runner; bump faction cache `schemaVersion` to 3.
- [ ] Populate the new fields in `faction_manager.dart` from the already-merged faction JSON.
- [ ] Create `ship_roles_manager.dart`: load and merge `data/world/factions/default_ship_roles.json` from game core + enabled mods (same ordering and merge rules as faction files), tracking which mod last set each entry's weight.
- [ ] Create `spawn_weight_calculator.dart`: the four-step weight pipeline (role entry → known-ships filter with tag expansion → variant overrides → hull frequency), plus the per-faction summary (vanilla share, per-mod shares, skipped-entry count). `hullFrequency` per-hull and per-tag multipliers **compound** — fold each tag multiplier into the per-hull map (`existing (default 1.0) × tagMult`) before applying, and apply the result on top of any `variantOverrides` weight.
- [ ] Add Riverpod providers wiring the calculator to the faction list, ship list, and variant data; memoize per faction.
- [ ] Unit tests for the merge (append, last-write-wins, `core_clearArray`, scalar attribution) and the calculator (each pipeline step, compounding hull/tag multipliers, zero-weight exclusion, unresolvable loadouts) using small fixture files.

## UI — glance

- [ ] Add the vanilla-vs-mods share bar to the faction gallery card; "—" for factions with no combat roles; tooltip explaining the number.
- [ ] Add a sortable "Vanilla spawn %" column to the faction grid view.

## UI — faction dialog

- [ ] Add a "Spawn weights" section to the faction profile dialog (after Fleet): split bar, top contributing mods with shares, "See all ships" button.
- [ ] Wire "See all ships" to switch the faction viewer to the spawn-weights mode with that faction selected.

## UI — detail view

- [ ] Add `FactionViewMode.spawnWeights`; replace the two-state toolbar toggle with `ModeSwitcher`; run build_runner for the controller mapper.
- [ ] Build the detail view: faction picker, role picker, weight table (ship, size, weight, share, source mod), grouped by hull with expandable loadout rows.
- [ ] Hook the page search box to filter the table by ship name while in this mode.
- [ ] Add "Open file that set this weight" per row (resolves to the source mod's `default_ship_roles.json` or `.faction` file).
- [ ] Empty-role state: when a role has zero entries, do not imply the faction spawns nothing — say the role is empty and name the fallback role the game uses instead.
- [ ] Add the footer note listing blind spots: ships added by mod code, fleet-point filtering, combat-freighter mixing, `restrictToVariants`, and mods using `"replace"` in `mod_info.json`.

## Maybe later

- [ ] Add a `replace` field to `ModInfo` so mods that override a file wholesale (rather than merging) are handled. Rare in practice — check how many real mods use it before spending time here. Until then it's a documented limitation.

## Verification

- [ ] `flutter analyze` and `flutter test` pass.
- [ ] Manual check against a modded install: dialog numbers match the detail table; sorting the grid column works; "Open file" lands on the right file. (User verifies in-app.)
- [ ] Review all user-facing strings with the user before finalizing.
