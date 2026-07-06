# Design: "Last Updated" column

## Definition

**Last Updated** = the `firstSeen` of the **highest-version variant the mod currently has installed**.

Rationale: `ModVariantMetadata.firstSeen` is stamped (`= now`) the first time TriOS sees a given
variant — which, for a mod installed through TriOS, is its install time. Taking the *highest-version*
variant means:

- **First-time install** (one variant): the value is that variant's install time. ✔
- **User installs a newer version**: a new variant appears, `_initializeMissingMetadata` stamps its
  `firstSeen = now` (triggered by the `AppState.smolIds` listener in `ModMetadataStore`), and because it
  is now the highest version, the column advances to that install time. ✔
- **User installs an *older* version alongside the current one**: the highest version is unchanged, so
  the value does not move. This is correct — an older version is not "a newer version." ✔

This intentionally keys off the highest *version*, not the most recent `firstSeen`, so that adding an
old build does not masquerade as an update.

### Why derive instead of persist

The existing **First Seen** and **Last Enabled** columns derive their values from
`ModsMetadata` at render time; nothing is stored specifically for display. The same data
(`ModVariantMetadata.firstSeen` + `Mod.findHighestVersion`) fully determines Last Updated, so a derived
value keeps install/enable code paths untouched and avoids a new persisted field to migrate.

## Key decisions

1. **Highest-version variant, currently installed** — uses `Mod.findHighestVersion` (already cached on
   `Mod`). Its `smolId` keys into `getMergedModVariantMetadata(mod.id, smolId)?.firstSeen`.
2. **Fallback** — if for some reason the highest variant has no variant metadata yet, fall back to the
   mod-level `getMergedModMetadata(mod.id)?.firstSeen` (the same value First Seen uses) rather than
   showing blank. If even that is missing, render an empty cell / `0` sort value, matching the other
   date columns.
3. **Hidden by default** — to avoid crowding the grid, the column's `defaultState.isVisible = false`.
   Users can enable it from the column-visibility menu, like any other column. Position it after
   **Last Enabled**.
4. **Formatting** — reuse `Constants.dateTimeFormat` and `WispGrid.lightTextOpacity` /
   `theme.textTheme.labelLarge`, identical to First Seen / Last Enabled, for visual consistency.

## Known edge case (accepted, documented)

If a user updates 1.0 → 2.0 and then **deletes** the 2.0 variant (leaving only 1.0 on disk), the highest
*currently installed* variant becomes 1.0 again, so Last Updated reverts to 1.0's install time. This is
acceptable: the column describes the mod as it currently sits on disk. Persisting an all-time-high
timestamp would be the only alternative and is out of scope (it would require a new stored field).

## File changes

- `lib/mod_manager/homebrew_grid/wisp_grid_state.dart`
  - Add `lastUpdated` to `enum ModGridHeader` (after `lastEnabled`).
  - Add `lastUpdated` to `enum ModGridSortField` (after `lastEnabled`).

- `lib/mod_manager/mod_manager_extensions.dart`
  - Add `getSortValueForLastUpdated(ModsMetadata?)` returning the highest-version variant's `firstSeen`
    (with the mod-level `firstSeen` fallback), `?? 0`.

- `lib/mod_manager/mods_grid_page.dart`
  - Add a `WispGridColumn<Mod>` for `ModGridHeader.lastUpdated` (name `"Last Updated"`, sortable,
    `getSortValue` → `getSortValueForLastUpdated`, cell + CSV formatted like First Seen),
    `defaultState: WispGridColumnState(position: 13, width: 150, isVisible: false)`.
  - Add `ModGridHeader.lastUpdated => ModGridSortField.lastUpdated` to the sort-field `switch`.
  - Add `ModGridHeader.lastUpdated => Text('Last Updated', style: headerTextStyle)` to the
    header-text `switch`.

## Out of consideration

Code generation (`dart run build_runner build`) is required after editing the `@MappableEnum`s, since
`wisp_grid_state.mapper.dart` is generated.
