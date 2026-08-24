# Tasks

## Step 1 — the shared bell

- [x] Add `buildMutedUpdatesIcon` in `lib/dashboard/version_check_icon.dart`:
      takes a ref, a mod id, and the remote version string, watches
      `AppState.modsMetadata`, returns null when neither mute applies.
- [x] Move the icon choice and both hover strings into it unchanged.
- [x] Have `VersionCheckIcon` use it, returning it when non-null and falling
      back to the existing row otherwise.

## Step 2 — the card

- [x] In `catalog_mod_card.dart`, work out once per build whether a mute covers
      this card's update, from `installedMod?.id` and the comparison's remote
      version string.
- [x] Make `_statusBarColor` treat a muted update as no update, so the bar goes
      back to green or grey.
- [x] Add an `isUpdateMuted` flag to `CatalogDownloadButton` and make
      `_resolveState` fall through to `installedEnabled` / `installedDisabled`
      when it is set.
- [x] Place `buildMutedUpdatesIcon`'s bell in the bottom-right corner, to the button's left.
- [x] Wrap it in a `ContextMenuRegion` with "Recheck" plus
      `buildMenuItemToggleMuteUpdates`, copying the Mods grid cell
      (`mods_grid_page.dart:2001`). Leave "Recheck" out when the mod is fully
      muted.
- [x] Add `buildMenuItemToggleMuteUpdates` to the card menu's "Installed Mod"
      section, under Enable/Disable.

## Step 3 — the filter and the count

- [x] Add `hasUpdateToShowInCatalog` in `catalog_page_controller.dart`: a
      top-level function so it can be tested without the controller.
- [x] Use it in `updatesCount` and in the `hasUpdate` `BoolField` predicate.
- [x] `ref.watch(AppState.modsMetadata)` in `build()` so both recompute when a
      mute is toggled.
- [x] Add `BoolField.labelSuffix` to the shared filter engine: an optional
      builder for an extra widget after the label and count badge, allowed to
      return null.
- [x] Add `mutedUpdatesCount` and show it after the "Has Update" count as
      "+ N" with a bell, worded like the Dashboard's updates header.

## Step 4 — writing it down

- [x] Add "Muted mod" and "Muted update" to `CONTEXT.md`.
- [x] Add a test: the Catalog's update count and "Has Update" filter leave out a
      mod whose updates are muted entirely, and one whose current version is the
      muted one — and still include a mod whose muted version is an older one.
- [x] `flutter analyze` and `flutter test`.
- [x] Check by hand: mute from a Catalog card, confirm the bar, button, bell,
      and the filter badge all agree, and that the Mods page agrees too.
