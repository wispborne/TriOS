# Tasks: Hullmod Codex Tooltip

- [x] Create `lib/hullmod_viewer/widgets/hullmod_codex_card.dart` with `HullmodCodexCard` class following the `ShipCodexCard`/`WeaponCodexCard` pattern (private constructor, `tooltip()`, `create()`, `_buildHullmodContent()`)
- [x] Implement `_buildHullmodContent()` layout: title, short description, hullmod data section (sprite + OP costs grid), S-Mod section, description sections — using shared `ingame_tooltip_shared.dart` utilities
- [x] Wire up `HullmodCodexCard.tooltip()` on the name column in `hullmods_page.dart` (replace plain `TextTriOS` with tooltip-wrapped version + `MouseRegion` cursor)
- [x] Replace info icon column's `_buildInfoPane` call with `HullmodCodexCard.create()`
- [x] Remove dead code: `_buildInfoPane`, `_kv`, `_chip`, `_fmtNum`, and `section` helper from `_HullmodsPageState`
- [ ] Verify tooltip displays correctly by running the app and hovering over hullmod names in the grid
