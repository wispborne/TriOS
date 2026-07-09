# Deep-Link: Optional Minimum Dependency Version

## Problem

A `starsector-mod://install` link can carry dependencies (`dep=` params), and each
entry may include a `version`. Today that `version` is only a *display/fallback*
value: for a `.version`-file entry the fetched remote version always wins, and the
"already installed" check compares the local copy against that remote version. So a
link cannot express **"this mod needs at least version X of dependency Y."**

The practical consequences:

- A link author can't pin a dependency to a minimum version. If the user has the
  dependency installed but too old, the link can't tell TriOS to update it; if they
  have it new enough, the link can't tell TriOS to leave it alone.
- A dependency with no version still gets compared against its remote `.version`,
  so an installed-but-older dependency is treated as an available update even when
  the author only cares that it's *present*.

## Proposed Solution

Reinterpret the `version` on a **dependency** entry as an **optional minimum
required version**, while leaving the **main mod** entry's `version` as the existing
display/fallback value.

For a dependency entry:

- **Version present** → it is the minimum required version.
  - A locally installed copy `>=` the minimum ⇒ **satisfied** ("Already installed");
    skip it, even if a newer remote version exists (the minimum is the only bar).
  - A locally installed copy `<` the minimum (or not installed) ⇒ **not satisfied**;
    surface it as installable (pre-selected) so the link's download is fetched.
- **Version absent** → install the dependency **only if missing** (any installed
  version satisfies it).

The main mod entry keeps today's behavior unchanged. `version` remains optional
everywhere.

## Scope

- `deep_link_parser.dart` — clarify the documented meaning of `version` (parsing is
  already version-optional; no format change).
- `deep_link_handler.dart` — dependency resolution: compare an installed dependency
  against the link's **minimum** version instead of the fetched remote version, and
  short-circuit a satisfied dependency without offering an update.
- `deep_link_confirmation_dialog.dart` — show a dependency's minimum requirement
  clearly (e.g. "Requires ≥ 1.2.3") so the user understands why a dependency is or
  isn't selected.
- A unit test for the new dependency-satisfaction logic.

## Non-Goals

- **The in-app link generator form.** `buildMenuItemCopyInstallLink` currently emits
  a single-mod `{url, id}` link with no dependencies and no version. Building a
  multi-dependency link builder with a per-dependency "Require this version or newer"
  checkbox is a separate, larger feature and is **not** part of this change. This
  change only makes the *incoming* URL honor a minimum dependency version; links that
  exercise it are authored externally (or by a future generator).
- No change to the main mod's version semantics.
- No change to the URL format, scheme, or the direct-download vs `.version` detection.
