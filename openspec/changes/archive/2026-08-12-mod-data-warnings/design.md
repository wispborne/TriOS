# Design: Mod data warnings

## Overview

Three pieces:

1. **Check logic** — a pure function that takes a `ModVariant` and returns a list of issues. New file: `lib/mod_manager/mod_data_issues.dart`.
2. **Warning icon widget** — small amber warning icon with tooltip and click-to-open dialog. New file: `lib/mod_manager/mod_data_warning_icon.dart`.
3. **Grid wiring** — `buildNameCell` in `lib/mod_manager/mods_grid_page.dart` runs the check on the displayed variant and puts the icon at the start of the cell when there are issues.

## Check logic (`mod_data_issues.dart`)

```dart
enum ModDataIssueType {
  versionCheckerMismatch,
}

class ModDataIssue {
  final ModDataIssueType type;
  final String summary; // one line, used in the tooltip and dialog
  final String? detail; // optional longer explanation, dialog only
}

// A single check. Returns an issue, or null if the mod passes.
typedef ModDataCheck = ModDataIssue? Function(ModVariant variant);

// checkModDataIssues runs every check in a list and collects the results.
List<ModDataIssue> checkModDataIssues(ModVariant variant) { ... }
```

Plain classes, no `@MappableClass` — nothing is persisted or serialized.

### The version mismatch check

Flag a mismatch when all of these are true:

- `variant.versionCheckerVersion` is not null (the `.version` file exists and has a version).
- `variant.modInfo.version` is not null.
- After re-parsing both version strings with the same sanitize rule (strip letters, keep digits/dots/hyphens — the rule mod_info parsing already uses), their major/minor/patch/build parts differ (`Version.equalsSymbolic`).

Comparing raw strings (`Version.compareTo`) was the first plan, but it warns on `v1.2.3` vs `1.2.3` — a formatting difference, not a disagreement. Sanitizing both sides first means letters and missing trailing zeros (`1.2` vs `1.2.0`) don't warn, while genuinely different numbers like `0.35` vs `0.3.5` still do.

The check runs per displayed variant. `buildNameCell` already receives the variant the row shows (`findFirstEnabledOrHighestVersion`), so the check uses that one. Other installed versions of the same mod are not checked.

The check is cheap (a version comparison per row build), so it runs inline in the cell builder. No provider or caching.

### Draft user-facing text (needs sign-off before shipping)

- Tooltip / summary line: `Version Checker says {0.3.5} but mod_info.json says {0.35}`
- Dialog title: `Data issues in {mod name}`
- Detail: `The mod's .version file and its mod_info.json list different versions. This is a mistake by the mod author. TriOS uses the Version Checker version ({0.3.5}) when comparing versions.`

## Warning icon widget (`mod_data_warning_icon.dart`)

- `Icons.warning_amber_rounded`, about 16px, `ThemeManager.vanillaWarningColor` if that exists, otherwise the theme's amber/warning color. Sized to sit on the 8dp grid next to 16px-tall row content.
- Wrapped in `MovingTooltipWidget.text` with the issue summaries, one per line.
- Wrapped in a click handler (`InkWell` or `GestureDetector`) that opens the details dialog.
- The dialog is a plain `AlertDialog`: title with the mod name, one section per issue (summary bold, detail below), a Close button.

### Tooltip nesting

The whole Name cell is already wrapped in `MovingTooltipWidget.framed` showing `ModSummaryWidget`. The icon's own `MovingTooltipWidget.text` will be nested inside it. Verify during implementation that the inner tooltip wins while hovering the icon; if both show, look at how other nested tooltips in the grid handle it (the update-status cell nests tooltips) and copy that approach.

## Grid wiring (`mods_grid_page.dart`)

In `buildNameCell`, the row currently is: optional color bar, then name text. It becomes: optional warning icon, optional color bar, then name text. The icon only appears when `checkModDataIssues` returns a non-empty list. Spacing stays on the existing 8.0 `Row` spacing.

The cell already uses a `Row` only when the color bar is present. Rework it so the `Row` is used when either the bar or the icon is present, keeping the plain `Text` fast path when neither is.

## Turning it off

`Settings.modsGridShowDataWarnings`, default true. A checkbox in the mods page three-dot menu, next to "Colorful" and the other view options, labeled "Show Mod Data Warnings". When off, `buildNameCell` skips the check entirely and shows no icon.

## Adding checks later

Each check is its own private function matching the `ModDataCheck` typedef, listed in `_allChecks`. A new check is: add an enum value, write a check function, add it to the list. `checkModDataIssues` itself never changes, and no UI changes are needed.

## Tests

Unit tests for `checkModDataIssues` in `test/mod_data_issues_test.dart`:

- Mismatch (`0.35` vs `0.3.5`) → one issue.
- Same version, different formatting that compares equal → no issue.
- No `.version` file (`versionCheckerInfo` null) → no issue.
- Exact match → no issue.

No widget tests; the icon and dialog get checked by hand.
