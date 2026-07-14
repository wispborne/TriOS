# Design

## Background

The helper-button row already exists but is wired up two ways that block this
feature:

1. **It only renders for turned-on mods.** The Mods Page feeds it the *enabled*
   variant — `item.findFirstEnabled` ([mods_grid_page.dart:484](../../../lib/mod_manager/mods_grid_page.dart#L484)).
   For a turned-off mod that is `null`, so the lookup
   `modCompatibility[enabledVersion?.smolId]` returns `null`, the unmet list is
   empty, and `buildMissingDependencyButtons` returns an empty `Container`
   ([mods_grid_page.dart:2366](../../../lib/mod_manager/mods_grid_page.dart#L2366)).

2. **A missing requirement only offers "Search."** `MissingDependencyButton`
   opens a Google search rather than checking the catalog
   ([mods_grid_page.dart:2470](../../../lib/mod_manager/mods_grid_page.dart#L2470)).

Good news for the off-mod case: `AppState.modCompatibility` is computed over
**all** variants on disk, not just enabled ones
([app_state.dart:173](../../../lib/trios/app_state.dart#L173)). So the dependency
data already exists for turned-off mods — we just need to look it up with a
variant that exists when the mod is off.

## Key decisions

### 1. Resolve the row's variant with a fallback

Change the call site from `item.findFirstEnabled` to
`item.findFirstEnabledOrHighestVersion`
([mod.dart:58](../../../lib/models/mod.dart#L58)). This returns the enabled
variant when on, or the highest installed version when off — so
`modCompatibility[smolId]` resolves either way.

### 2. Pass the parent's on/off state into the button

`buildMissingDependencyButtons` and `MissingDependencyButton` need to know
whether the parent mod is on, to decide whether the "Enable" button is allowed.
Add an `isParentEnabled` flag (derived from `item.hasEnabledVariant` at the call
site) and thread it through.

### 3. Button selection logic

Inside `MissingDependencyButton`, pick the button from the requirement's state
and the parent's on/off state:

```
requirement is Disabled (present, off):
    parent on   -> [Enable {dep}]      (existing behavior)
    parent off  -> render nothing (SizedBox)

requirement is Missing / VersionInvalid (absent or wrong major version):
    catalog has a direct download link -> [Install {dep}]   (new)
    otherwise                          -> [Search {dep}]    (existing fallback)
```

`VersionWarning` and `Satisfied` requirements are already filtered out upstream
by `!isCurrentlySatisfied`, so no button is needed for them.

### 4. Catalog lookup — match by name, not id

The first attempt looked the requirement up in the mod-records store by id
(`lookupByModId(dep.id)`). **That does not work for a missing mod.** The catalog
has no mod IDs — a record only gains a `modId` when it is matched to an
*installed* mod ([mod_records_store.dart:164](../../../lib/mod_records/mod_records_store.dart#L164)).
A missing requirement isn't installed, so its catalog entry is a "catalog-only"
record with `modId: null` ([mod_records_store.dart:198](../../../lib/mod_records/mod_records_store.dart#L198)),
and a by-id lookup never finds it.

Instead, match the requirement to a catalog entry **by name**, the same way the
records store fuzzy-matches installed mods to the catalog
([mod_records_store.dart:150](../../../lib/mod_records/mod_records_store.dart#L150)):
lower-case and strip everything but letters and digits, then compare. For
example `crew_replacer` and `Crew Replacer` both normalize to `crewreplacer`.

```
dep.name / dep.id  --normalize-->  compare against normalized ScrapedMod.name
                                    in browseModsNotifierProvider's catalog
                   -->  ScrapedMod.getUrls()[ModUrlType.DirectDownload]
```

We read the catalog directly from `browseModsNotifierProvider`
([mod_browser_manager.dart:19](../../../lib/catalog/mod_browser_manager.dart#L19))
and use the same `ModUrlType.DirectDownload` link the catalog card's download
button uses. Both `dep.name` and `dep.id` are tried (both nullable —
[mod_info_json.dart:50](../../../lib/models/mod_info_json.dart#L50)). If neither
matches, or the matched entry has no direct download link, fall back to "Search."

### 5. Download with the existing flow

The Install button reuses the same download path as the catalog page:

```dart
confirmAndDownloadModViaManager(
  context, ref,
  modName: dep.nameOrId,
  downloadUrl: directDownloadUrl,
  activateVariantOnComplete: false,
);
```

([download_confirm.dart:42](../../../lib/catalog/download_confirm.dart#L42)).
`activateVariantOnComplete` stays `false` — we install the file but let the
user turn it on (turning the requirement on without its own requirements met
could just move the problem). The existing post-install "Enable" notification
already nudges them.

## Files changed

- `lib/mod_manager/mods_grid_page.dart`
  - Call site (~line 484): pass `findFirstEnabledOrHighestVersion` and the
    parent's enabled state.
  - `buildMissingDependencyButtons` (~line 2366): accept and forward
    `isParentEnabled`.
  - `MissingDependencyButton` (~line 2407): add the Install branch and the
    parent-on/off gate for the Enable branch.

## Risks / edge cases

- **Newest-version-only.** The catalog knows only the latest version, so Install
  offers the newest. Usually fine; can't satisfy an old pinned `VersionInvalid`
  requirement. Acceptable (see proposal non-goals).
- **No direct link.** Many catalog mods only have a forum/page link, not a direct
  download. Those keep the "Search" fallback rather than a broken Install.
- **Records still loading.** `modRecordsStore` is async; before it loads,
  `lookupByModId` returns null and we show "Search." It corrects itself once
  records load (the widget watches the store).
- **Noise on big libraries.** Turned-off mods now show buttons too, but only
  when a requirement is truly missing/wrong-version (the only states left after
  the `!isCurrentlySatisfied` filter for an off mod), so present-but-off
  requirements stay quiet.
