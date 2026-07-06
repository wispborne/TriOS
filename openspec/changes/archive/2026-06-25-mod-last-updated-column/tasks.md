# Tasks: "Last Updated" column

- [x] Add `lastUpdated` to `enum ModGridHeader` (after `lastEnabled`) in `lib/mod_manager/homebrew_grid/wisp_grid_state.dart`.
- [x] Add `lastUpdated` to `enum ModGridSortField` (after `lastEnabled`) in the same file.
- [x] Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `wisp_grid_state.mapper.dart`.
- [x] Add `getSortValueForLastUpdated(ModsMetadata?)` to the `Mod` extension in `lib/mod_manager/mod_manager_extensions.dart`, returning the `firstSeen` of `findHighestVersion`'s variant metadata (falling back to the mod-level `firstSeen`), `?? 0`.
- [x] Add the `WispGridColumn<Mod>` for `ModGridHeader.lastUpdated` in `lib/mod_manager/mods_grid_page.dart`, modelled on the `firstSeen` column: name `"Last Updated"`, `isSortable: true`, `getSortValue` → `getSortValueForLastUpdated`, cell + CSV value formatted with `Constants.dateTimeFormat`, `defaultState: WispGridColumnState(position: 13, width: 150, isVisible: false)`.
- [x] Add `ModGridHeader.lastUpdated => ModGridSortField.lastUpdated` to the sort-field `switch` in `mods_grid_page.dart`.
- [x] Add `ModGridHeader.lastUpdated => Text('Last Updated', style: headerTextStyle)` to the header-text `switch` in `mods_grid_page.dart`.
- [x] Run `flutter analyze` and confirm no new warnings.
- [ ] Manually verify: enable the column from the column-visibility menu; confirm it shows a sensible date, sorts correctly, and (if testable) advances after installing a newer version of a mod.
