# Tasks — Optional Minimum Dependency Version

## Parser docs (no behavior change)

- [x] In `deep_link_parser.dart`, update the `DeepLinkModEntry.modVersion` doc comment
      and the library-level format comment to state that, on a **dependency** entry,
      `version` is an optional *minimum required version*; on the **main mod** it stays
      the display/fallback version.

## Handler: dependency-minimum logic

- [x] Add `_installedVersionForDependency(DeepLinkModEntry entry)` to `DeepLinkHandler`:
      return the highest locally-installed `Version` of the mod the entry points to, or
      null. Match by `modId` when present; otherwise, for a `.version` entry, match by
      `fixUrl`-normalized link URL vs a local variant's `masterVersionFile`.
- [x] Thread an `isDependency` flag into `_resolveModEntry`; pass `false` for
      `newPrimaries` and `true` for `newDeps` in `_drainAndProcess`.
- [x] In `_resolveModEntry`, when `isDependency`:
      - Compute satisfaction: `installed != null && (min == null || installed >= min)`,
        where `min` is the parsed `entry.modVersion`.
      - If satisfied → return `alreadyInstalled: true` without fetching the `.version`
        file (download URL not needed).
      - If not satisfied → fall through to the existing fetch/resolve path with
        `alreadyInstalled: false`.
- [x] Leave the main-mod path and `_isDirectDownloadAlreadyInstalled` /
      `_isModAlreadyInstalled` behavior unchanged for non-dependency entries.

## Dialog

- [x] In `deep_link_confirmation_dialog.dart` `_modContent`, label a dependency's
      minimum-version line as a requirement (e.g. "Requires ≥ 1.2.3"). Keep the bare
      version line for the main mod and for version-less entries.

## Tests

- [x] Add `test/deep_link_min_dependency_version_test.dart` covering the satisfaction
      table: dependency with min satisfied / unsatisfied / not installed, and
      dependency without a version (installed vs missing). Mirror the guarded style of
      existing tests so it runs without a live game install.

## Verify

- [ ] `flutter analyze` clean. _(Blocked here: installed Flutter SDK 3.44.0 ≠ repo-pinned
      3.44.2, so pub won't resolve. User to run.)_
- [ ] `flutter test` green (let the user manually verify the dialog UI per project
      convention — do not run the app). _(Blocked by same SDK mismatch.)_
