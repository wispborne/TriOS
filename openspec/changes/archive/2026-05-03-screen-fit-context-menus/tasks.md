## 1. Verify `FadedScrollable` behavior

- [x] 1.1 Read `lib/thirdparty/faded_scrollable/faded_scrollable.dart` — determine whether fade gradients render only on overflow or always
- [x] 1.2 If it always renders fades: plan the conditional-wrap path (intrinsic height check); if it adapts: plan the unconditional-wrap path

  **Result:** `FadedScrollable` adapts. It listens for `ScrollUpdateNotification`/`ScrollMetricsNotification` and sets `_isScrollable = (maxScrollExtent > 0)`. When content fits, `_isScrollable` is false, `gradientConfig.colors` is empty, and the widget returns `widget.child` unchanged (no `ShaderMask`). Wrap unconditionally.

## 2. Apply the screen-fit cap

- [x] 2.1 In `lib/thirdparty/flutter_context_menu/widgets/context_menu_widget.dart`, modify `_buildMenuView` and/or `_buildMenuContent` to compute `availableHeight = MediaQuery.sizeOf(context).height - state.position.dy - 8`
- [x] 2.2 Compute `effectiveMax = state.maxHeight ?? availableHeight` and apply it to the `BoxConstraints.maxHeight`
- [x] 2.3 Wrap content in `FadedScrollable(SingleChildScrollView(...))` when capped (conditional or unconditional per task 1) — unconditional, except when `effectiveMaxHeight == double.infinity` (explicit opt-out)
- [x] 2.4 Preserve the explicit-`maxHeight` override path — callsites that pass `maxHeight: N` still get exactly `N`

## 3. Manual verification

- [ ] 3.1 Open the weapons page on a small window — right-click a column header — confirm the menu fits on screen and scrolls to all entries including bottom column toggles
- [ ] 3.2 Open the same menu on a tall window — confirm no fade gradients appear and the menu renders at its natural height
- [ ] 3.3 Open a short menu (e.g. mod row context menu) on any window — confirm no visual change
- [ ] 3.4 Open a submenu (e.g. "Group By" or "Then By") — confirm it also caps and scrolls when it would otherwise overflow
- [ ] 3.5 Spawn a menu near the bottom edge of the screen — confirm the existing upward-reposition still happens and the cap then kicks in correctly
- [ ] 3.6 Scroll inside a long open menu using the scroll wheel — confirm the menu scrolls, not the underlying page

## 4. Spec & docs

- [x] 4.1 Update spec under `openspec/changes/screen-fit-context-menus/specs/context-menu-rendering/spec.md` (already authored as part of the proposal)
- [x] 4.2 No CHANGELOG update (per project convention)
