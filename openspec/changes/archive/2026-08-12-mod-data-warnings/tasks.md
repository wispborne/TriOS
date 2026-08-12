# Tasks: Mod data warnings

- [x] Create `lib/mod_manager/mod_data_issues.dart` with `ModDataIssueType`, `ModDataIssue`, and `checkModDataIssues()` implementing the Version Checker vs `mod_info.json` mismatch check.
- [x] Write unit tests in `test/mod_data_issues_test.dart` covering mismatch, equal-but-formatted-differently, missing `.version` info, and exact match. Run them.
- [x] Create `lib/mod_manager/mod_data_warning_icon.dart`: the warning icon with `MovingTooltipWidget.text` tooltip and click-to-open `AlertDialog` showing issue details.
- [x] Wire the icon into `buildNameCell` in `lib/mod_manager/mods_grid_page.dart`, at the start of the cell before the color bar.
- [x] Verify the icon's tooltip shows instead of the cell's `ModSummaryWidget` tooltip when hovering the icon; fix nesting if both appear. (Nesting is already handled: the inner tooltip blocks its ancestor while showing.)
- [x] Get sign-off on the user-facing text (tooltip line, dialog title, detail text) from the design doc.
- [x] Add `Settings.modsGridShowDataWarnings` (default true) and a "Show Mod Data Warnings" checkbox in the mods page three-dot menu; skip the check in `buildNameCell` when it's off.
- [x] Run `flutter analyze` and the full test suite; have the user check the grid by hand with a mod that has mismatched versions, and check that the menu toggle hides the icon.
