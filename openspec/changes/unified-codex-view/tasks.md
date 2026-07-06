# Tasks — Unified Codex view

## Data: ship systems (light)

- [ ] Turn on the commented-out fields in `lib/ship_systems_manager/ship_system.dart`.
      Their `@MappableField` CSV keys are already written and match the real header
      (`flux/use`, `max uses`, `cooldown`, `toggle` and the other TRUE/FALSE flag
      columns, `tags`, `icon`) — except `regen flat`, which is not in the vanilla CSV;
      keep that field nullable or drop it.
- [ ] Update the ship-systems manager to read those fields from
      `data/shipsystems/ship_systems.csv`, and stamp each `ShipSystem` with the mod it
      came from (the model has no mod field today; the Codex mod filter needs one).
- [ ] Run build_runner to regenerate `ship_system.mapper.dart`.
- [ ] Add `ShipSystemCodexCard` (name, key stats, and description via
      `descriptionProvider((system.id, DescriptionEntry.typeShipSystem))` — the same
      lookup `ShipCodexCard` already uses).

## Data: fighters / wings (new)

- [ ] Add `lib/fighter_viewer/models/wing.dart` (`@MappableClass`) mapping the
      `data/hulls/wing_data.csv` columns. Map `num` (craft count), not the separate
      `number` column (a plain row counter at the far end of the header, after a run of
      blank columns); skip `attackRunRange` / `attackPositionOffset`. Give the model a
      `late ModVariant? modVariant` field like `Weapon` has (null = vanilla), so the
      mod filter works.
- [ ] Add a wings cache payload type (mirror `WeaponsCachePayload` in
      `lib/weapon_viewer/models/weapons_cache_payload.dart`).
- [ ] Add `WingListNotifier` extending `CachedStreamListNotifier`, declaring
      `String get domain => 'wings';` (the domain is just a cache folder name — no
      registry to update), reading each folder's `data/hulls/wing_data.csv`. This is
      one CSV per mod folder — simpler than the weapon loader (which also reads `.wpn`
      files). For the `.variant` read below, follow `ShipListNotifier`'s variant
      parsing in `lib/ship_viewer/ship_manager.dart`.
- [ ] Resolve a wing's `variant` column to its `.variant` file (vanilla fighter variants
      live in `data/variants/fighters/`) and read the `hullId` so the wing can link to
      its ship. Degrade gracefully if the variant/hull is missing.
- [ ] Run build_runner for the new mapper files.
- [ ] Add `WingCodexCard` (role, points, tier/rarity, number of craft, link to the
      ship). There is no wing entry type in `descriptions.csv`, so the card has no
      long description — use the `role desc` column and the ship link.

## Shared codex model

- [ ] Add `lib/codex/models/codex_entry.dart`: sealed `CodexEntry` with `id`, `type`,
      `displayName`, `modId`, `icon`, and one subclass per category wrapping the existing
      data object. The models store their mod source differently, so each subclass maps
      `modId` its own way: `ship.modId`; `weapon.modVariant?.modInfo.id`;
      `hullmod.modVariant?.modInfo.id`; ship system's new mod field; the wing's new
      `modVariant`; factions use `faction.sources` and match if any source matches.
- [ ] Add `CodexEntryType` enum (ship, weapon, hullmod, shipSystem, wing, faction).

## Combined index + search

- [ ] Add a provider that watches all six sources — the four `CachedStreamListNotifier`
      loaders, the ship-systems `StreamProvider`, and the wings loader — and flattens
      them into `List<CodexEntry>`. Duplicate ids within a category are already handled
      (each loader keeps the first one it saw); different categories can reuse the same
      id, so key links and history by `(type, id)`. Read ship systems as its own
      `List<ShipSystem>`; it does not share the cached loaders' payload interface.
- [ ] Add search over the combined list (default: `displayName` + `id`; reuse the
      per-type `SearchField` lists where available — each viewer page controller builds
      them in a `_buildSearchFields()` method, e.g.
      `lib/ship_viewer/ships_page_controller.dart`).
- [ ] Add category and mod filters (plain `where` over `type` and `modId`).

## The Codex tab

- [ ] Add `lib/codex/codex_page.dart` — three-panel `ConsumerStatefulWidget` with
      `AutomaticKeepAliveClientMixin` (category rail + mod filter, results, detail).
- [ ] Left panel: a plain fixed-width list of category tiles plus the mod filter. Do
      not use `SideRail` (built as a right-side rail) or `ViewerSplitPane` (splits
      top/bottom only). For results vs. detail, use `MultiSplitView` directly with
      `axis: Axis.horizontal`, copying the divider theming from
      `lib/widgets/viewer_split_pane.dart`.
- [ ] Detail panel: `switch (entry.type)` → render the matching existing card
      (ship / weapon / hullmod / faction) or the new ship-system / wing card.

## Clickable cross-references + history

- [ ] Add an optional `onEntitySelected` callback to `ShipCodexCard`, `WeaponCodexCard`,
      `HullmodCodexCard`, and the wing/ship-system cards. Thread it through the private
      helpers that currently build the references (e.g. `_armamentWrap` in
      `ShipCodexCard`, which wraps built-in weapons in `WeaponCodexCard.tooltip`).
      All three cards have `.tooltip()` factories with existing call sites that must
      keep their current hover behaviour (callback stays null there):
      `WeaponCodexCard.tooltip` in `faction_profile_dialog.dart`, `weapons_page.dart`,
      `ship_codex_card.dart`; `HullmodCodexCard.tooltip` in
      `faction_profile_dialog.dart`, `hullmods_page.dart`; `ShipCodexCard.tooltip` in
      `faction_profile_dialog.dart`, `ships_page.dart`. Default null = current hover
      behaviour, existing tabs unchanged.
- [ ] In the Codex detail panel, wire references (system, built-in weapons, wings, hull
      mods) to call the callback and select that entry. The `Ship` model exposes these as
      ids: `systemId`, `builtInWeapons`, `builtInMods`, `builtInWings`.
- [ ] Add a back/forward history stack in the page so links can be walked. References to
      missing/disabled-mod items fall back to plain text, not broken links.

## Register the tab

- [ ] Add `codex` to the `TriOSTools` enum in `lib/trios/navigation.dart`.
- [ ] Add it to `defaultNavOrder` and `reorderableTools`.
- [ ] Add its `label`, `tooltip`, `icon`, and `group` cases (group is
      `NavGroup.viewers`, an enum value).
- [ ] Regenerate `navigation.mapper.dart` with build_runner.
- [ ] In `lib/app_shell.dart`: add the next integer key to `tabToolMap` and add
      `CodexPage` at the matching position in the `tabChildren` list — the two must
      stay in the same order (`toolToIndexMap` is derived automatically).

## Wrap-up

- [ ] Add a tooltip to the new tab icon (project rule: every new icon needs one).
- [ ] `flutter analyze` and `dart run custom_lint` clean.
- [ ] Draft the user-facing tab name and any visible labels, and confirm wording before
      finalizing.
