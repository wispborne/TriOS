# Design — Optional Minimum Dependency Version

## Context

- Parser: `lib/trios/deep_link/deep_link_parser.dart`. `DeepLinkModEntry.modVersion`
  already holds an optional version string; `parseDeepLink` already separates
  `mainMod` from `dependencies`. No format/parse change is needed.
- Handler: `lib/trios/deep_link/deep_link_handler.dart`. `_drainAndProcess` resolves
  `newPrimaries` and `newDeps` through the **same** `_resolveModEntry`, which decides
  `alreadyInstalled` via `_isModAlreadyInstalled` (`.version` entries) or
  `_isDirectDownloadAlreadyInstalled` (direct entries).
- Dialog: `lib/trios/deep_link/deep_link_confirmation_dialog.dart`. Pre-selects
  entries where `error == null && !alreadyInstalled`; already shows `modVersion` on a
  numbered line.

The two `alreadyInstalled` checks already compare "local vs a provided version":

- `_isDirectDownloadAlreadyInstalled(modId, versionString)` already implements minimum
  semantics — id match + local `>=` versionString ⇒ installed; null version ⇒ installed
  if id matches. **This is already what we want for a dependency.**
- `_isModAlreadyInstalled(versionInfo, linkUrl, modId)` compares the local copy against
  the **remote** `.version` version (link version only a fallback). **This is the part
  that diverges from the desired dependency behavior.**

## Key Decision: branch resolution on role (main vs dependency)

Thread an `isDependency` flag from `_drainAndProcess` into `_resolveModEntry`
(`newPrimaries` → `false`, `newDeps` → `true`). The main-mod path is untouched; the
dependency path uses the link's `modVersion` as a **minimum bar**.

### Dependency satisfaction rule

Given the resolved local match for the dependency (highest installed version, or null):

| Link `version` | Installed?            | Result                          |
|----------------|-----------------------|---------------------------------|
| present (min)  | local `>=` min        | satisfied → `alreadyInstalled`  |
| present (min)  | local `<` min / absent | not satisfied → installable     |
| absent         | installed (any ver)   | satisfied → `alreadyInstalled`  |
| absent         | not installed         | not satisfied → installable     |

A satisfied dependency is **not** offered as an update even if a newer remote version
exists (per the "minimum is the only bar" decision).

### Avoiding an unnecessary fetch for satisfied `.version` dependencies

For a `.version` dependency we only need to fetch the remote file to obtain the
**download URL**, which is only needed when the dependency is *not* satisfied. So:

1. Determine the local match first (by `modId` when present; otherwise, for a
   `.version` entry, by comparing the link URL against local `masterVersionFile`s —
   no network needed).
2. If satisfied by the minimum rule → return `alreadyInstalled: true` immediately,
   no fetch (avoids spurious fetch errors on a dependency the user already has).
3. If not satisfied → fall through to the existing fetch/resolve path to get the
   download URL, with `alreadyInstalled: false`.

Direct-download dependencies need no fetch and reuse
`_isDirectDownloadAlreadyInstalled` unchanged (already minimum-correct).

### Helper

Add a small helper to find the highest locally-installed version of the mod a
dependency entry refers to:

```dart
/// Highest installed version of the mod this dependency entry points to, or null
/// if not installed. Matches by modId when supplied, else (for a .version entry)
/// by link URL vs a local variant's masterVersionFile (fixUrl-normalized).
Version? _installedVersionForDependency(DeepLinkModEntry entry)
```

Reuses `fixUrl` normalization (as `_isModAlreadyInstalled` does) and
`ModVariant.bestVersion` / `versionCheckerInfo.modVersion` for the local version.

The satisfaction decision then is:

```dart
final installed = _installedVersionForDependency(entry);
final min = entry.modVersion?.let((v) => Version.parse(v, sanitizeInput: false));
final satisfied = installed != null && (min == null || installed >= min);
```

## Dialog

In `_modContent`, when an entry is a dependency carrying a minimum version, label its
version line as a requirement (e.g. "Requires ≥ 1.2.3") instead of a bare number, so
a user reading the dialog understands why the dependency is pre-selected or shown as
already installed. Main-mod and version-less entries keep the current bare-version
line. The dialog already routes selection by `alreadyInstalled`, so no selection
logic changes.

## Alternatives considered

- **Always fetch then override `alreadyInstalled`.** Simpler control flow, but fetches
  the `.version` of a dependency the user already satisfies — wasted network and a
  chance to surface a spurious fetch error on something we're going to skip. Rejected.
- **Treat the main mod's version as a minimum too.** The request is specifically about
  *dependency* minimums; the main mod is the thing the user clicked to install, so its
  version stays the version-being-installed fallback. Out of scope.

## Risk / Compatibility

- Backward compatible: existing links without dependency versions behave as before
  (absent version ⇒ install only if missing). Existing direct-download dependency
  behavior is unchanged.
- The only behavior change is for `.version` *dependencies* that carry a version:
  comparison basis moves from remote version to the link's minimum, and a satisfied
  one is no longer offered as an update.
