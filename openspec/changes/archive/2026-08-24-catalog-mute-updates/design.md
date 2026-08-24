# Design: Muting mod updates from the Mod Catalog

## What already exists

| Piece | Where | What it does |
| --- | --- | --- |
| `ModMetadata.areUpdatesMuted` | `lib/trios/mod_metadata.dart:236` | Mute the mod forever. Version checks stop. |
| `ModMetadata.mutedUpdateVersion` | `lib/trios/mod_metadata.dart:244` | Mute one remote version string. Checks keep running. |
| `ModMetadata.isUpdateHidden(remoteVersion)` | `lib/trios/mod_metadata.dart:273` | True when either mute covers this version. |
| `buildMenuItemToggleMuteUpdates(mod, ref)` | `lib/trios/context_menu_items.dart:506` | The shared menu item. Picks whole-mod or per-version wording on its own, and forces a fresh check on unmute. |
| `VersionCheckIcon` | `lib/dashboard/version_check_icon.dart:56` | Renders a bell with hover text when muted; a row of version-check icons otherwise. |
| Mods grid version-check cell | `lib/mod_manager/mods_grid_page.dart:2001` | A nested `ContextMenuRegion` holding "Recheck" plus the shared mute item. The precedent for the bell's menu. |

Nothing new gets stored. The Catalog reads and writes the same
`AppState.modsMetadata` the Mods page uses, keyed on the installed mod's id.

## 1. A shared bell widget

`VersionCheckIcon` has two branches. When muted it returns a bell wrapped in a
tooltip; otherwise it returns a row of version-check icons the Catalog card has
no use for. Rather than call the whole widget and only ever reach one branch,
lift the bell out.

New function, `buildMutedUpdatesIcon`, next to `VersionCheckIcon`. A function
rather than a widget class, because it needs to be able to return nothing:

- Takes a `WidgetRef`, the mod id, and the current remote version string — all
  of which the Catalog card and `VersionCheckIcon` already have.
- Watches `AppState.modsMetadata` and works out which mute applies.
- Returns null when neither mute applies, so callers can drop the result
  straight into a layout with `?`.
- Hover text unchanged, word for word: `"Updates muted"` for the whole-mod
  mute, `"Update <version> is muted. You'll be notified for the next version."`
  for the single-version one.
- Icon unchanged: `Icons.notifications_off` for the whole-mod mute,
  `Icons.notifications_paused` for the single-version one, at 20px in
  `onSurface` at half alpha.

`VersionCheckIcon` then calls it and returns the bell when it gets one, falling
back to its existing row otherwise. Same pixels as today.

## 2. The card

`lib/catalog/catalog_mod_card.dart`.

**Working out the mute.** One lookup near the top of `build`, from
`_catalogMod.installedMod?.id` and
`widget.versionCheckComparison?.remoteVersionString`. When there is no
installed mod there is no mute, and everything below is skipped.

**Hiding the update.** `_statusBarColor` and `CatalogDownloadButton` both key
off `versionCheckComparison?.hasUpdate`. Both need to see a muted update as no
update. Pass the already-computed answer down rather than have each recompute
it: `_statusBarColor` reads it from the state, and `CatalogDownloadButton`
takes a new `isUpdateMuted` flag that makes `_resolveState` fall through to its
`installedEnabled` / `installedDisabled` cases.

That flag also removes the "Update" button. The card's right-click menu still
lists every download candidate, so a muted mod can still be updated on purpose
— it just stops asking.

**Placing the bell.** The button sits in a `Positioned` at the card's
bottom-right corner. The bell goes in the same corner, in a `Row` to the
button's left, so it lines up with the marker.

That corner overlays the card's footer, which keeps clear of it with a fixed
80px right inset. The bell widens the corner by 28px (a 20px icon plus 8px of
spacing), so the inset grows to 108px while the bell is showing — otherwise the
bell lands on top of the tag line.

**The bell's menu.** Wrapped in its own `ContextMenuRegion` holding "Recheck"
and the shared mute item, copied from the Mods grid cell. "Recheck" is left out
when the mod is fully muted, since checks are off then. The card's outer
`ContextMenuRegion` still works everywhere else on the card; the mods grid
already nests these the same way.

**The card menu.** `buildMenuItemToggleMuteUpdates(installedMod, ref)` joins the
existing "Installed Mod" section, under Enable/Disable.

## 3. The filter and the count

`lib/catalog/catalog_page_controller.dart`.

`updatesCount` and the `hasUpdate` `BoolField` predicate both need the same
answer, so the whole question — "does the Catalog present this mod as having an
update?" — moves into one top-level function, `hasUpdateToShowInCatalog`. It
takes a `Mod`, the version-check state, and the mod metadata, so it can be
tested on its own without standing up the controller's Riverpod graph.

The controller's `build()` must `ref.watch(AppState.modsMetadata)` so the count
and the filter recompute when a mute is toggled. It already watches
`AppState.versionCheckResults`, which changes at least as often, so this costs
nothing new.

The predicate reads `mod.installedMod?.id` from the `CatalogMod` directly
rather than going back through `statusForModName`, which matches on display
name.

`mutedUpdatesCount` is the other side of the same sum: mods with an update that
`hasUpdateToShowInCatalog` left out. It feeds a "+ N" and a bell drawn after the
count badge, worded and shaped like the Dashboard's updates header
(`mod_list_basic.dart:876`).

Getting that suffix into the checkbox row needed one small addition to the
shared filter engine: `BoolField.labelSuffix`, an optional builder for an extra
widget after the label and the count badge, which may return null to draw
nothing. A builder rather than a "muted count" field, so the filter engine stays
ignorant of what a mute is and the Catalog owns the wording and the icon. This
pulls `package:flutter/widgets.dart` into `filter_group.dart`, which had no
Flutter import before.

Muting a mod while the "Has Update" filter is on drops its card from the list
straight away. That is the same thing the Mods grid does when a muted row
leaves the Updates section.

## What could go wrong

**The bell's menu swallowing the card's.** Nesting `ContextMenuRegion` is
already done in `mods_grid_page.dart:2001`, so the pattern works — but it means
right-clicking the bell no longer offers the downloads. That is the intent:
the bell is the mute control, and the rest of the card still has the full menu.

**Unmuting a mod with no variants.** `buildMenuItemToggleMuteUpdates` force
-unwraps `mod.findFirstEnabledOrHighestVersion!` when it refreshes after an
unmute. A `CatalogMod`'s `installedMod` always has at least one variant, so
this cannot be null here. Worth knowing rather than worth guarding.

**Stale cached results.** A fully muted mod keeps its last version-check result
in the cache, so `hasUpdate` stays true underneath everything above. Every
place that shows it now filters it out, so it does not surface — but any new
Catalog code reading `hasUpdate` raw will show the update again.
