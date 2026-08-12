# Mod data warnings

## Problem

Some mods ship with bad or inconsistent data. Right now TriOS silently works around it. The user has no way to see that a mod's data has a problem.

The first case to detect: a mod's Version Checker version (from its `.version` file) does not match the version in its `mod_info.json`. Authors sometimes write `0.35` in one file and `0.3.5` in the other. This causes confusing version displays and can make update checks unreliable.

## Solution

Add a small warning icon at the start of the Name cell on the mods grid, shown only for mods with at least one detected data issue.

- Hovering the icon shows a tooltip listing the issues in one line each.
- Clicking the icon opens a dialog with the full details of each issue.
- Issue detection is a plain function that returns a list of issues, so new checks can be added later without touching the UI.

## In scope

- One check: Version Checker version vs `mod_info.json` version disagree.
- The warning icon in the mods grid Name cell, with tooltip and details dialog.
- A structure (issue type + check function) that later checks can slot into.
- A checkbox in the mods page three-dot menu to turn the icon off. On by default.
- Unit tests for the check function.

## Out of scope

- Any other checks (missing dependencies already have their own UI, game-version compatibility already has its own coloring).
- Showing the warning anywhere other than the mods grid (dashboard, mod details dialog, etc.).
- Persisting or dismissing individual warnings.
