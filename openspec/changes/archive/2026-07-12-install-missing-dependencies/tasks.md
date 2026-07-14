# Tasks

## Show the helper row for turned-off mods

- [x] In `mods_grid_page.dart` (~line 484), change the call from
      `item.findFirstEnabled` to `item.findFirstEnabledOrHighestVersion`.
- [x] Pass the parent's on/off state (`item.hasEnabledVariant`) into
      `buildMissingDependencyButtons`.
- [x] Update `buildMissingDependencyButtons` (~line 2366) to accept
      `isParentEnabled` and forward it to each `MissingDependencyButton`.

## Gate the "Enable" button to turned-on mods

- [x] In `MissingDependencyButton`, when the requirement is `Disabled` and the
      parent mod is off, render nothing (`SizedBox.shrink()`).
- [x] Keep the existing "Enable" button for the `Disabled` + parent-on case.

## Add the "Install from catalog" button

- [x] For `Missing` / `VersionInvalid` requirements, match the catalog entry by
      name (the catalog has no mod IDs): normalize `dep.name`/`dep.id` and the
      catalog `ScrapedMod.name` to letters+digits only, then compare against
      `browseModsNotifierProvider`'s items.
- [x] If the record has a `catalog?.directDownloadUrl`, show an "Install {dep}"
      button that calls `confirmAndDownloadModViaManager(...)` with
      `activateVariantOnComplete: false`.
- [x] Give the Install button a download icon and a tooltip explaining it
      installs the missing mod with TriOS (per project rule: tooltips on new
      icons).
- [x] When there is no record, no id, or no direct download link, fall back to
      the existing "Search" button.

## Handle "installed but outdated" requirements

- [x] Detect when the required mod is present (`satisfiedAmount.modVariant`) but
      its version is lower than the required version.
- [x] When outdated and the catalog has a direct download: show an "Update {mod}
      ({version} required)" button that downloads the latest, with a tooltip
      explaining the installed vs required version.
- [x] When outdated and the catalog match has no direct download but has a
      website/forum page: still show "Update {mod} ({version} required)", opening
      the page instead of downloading.
- [x] Only fall back to "Search for newer {mod}" when the outdated mod isn't in
      the catalog at all (no direct download and no page).

## Layout

- [x] Left-align the dependency buttons under each row with a fixed 8dp left
      margin, instead of indenting them to line up under the name column.

## Verify

- [x] Turned-off mod with a missing requirement that IS in the catalog: shows
      "Install"; clicking downloads and installs it.
- [x] Turned-off mod with a missing requirement NOT in the catalog: shows
      "Search" (unchanged behavior).
- [x] Turned-off mod whose only unmet requirement is present-but-off: shows no
      buttons.
- [x] Turned-on mod with a present-but-off requirement: still shows "Enable".
- [x] Turned-on mod with a missing requirement in the catalog: shows "Install".
- [x] After installing a missing requirement, the parent mod's Enable button is
      no longer greyed out.
- [x] Mod needing a newer version of an installed requirement (e.g. old `bmo`):
      shows "Update …" if the catalog has a direct download, else "Search for
      newer …", with a tooltip showing the installed and required versions.
- [x] `flutter analyze` is clean (no new issues from this change).
