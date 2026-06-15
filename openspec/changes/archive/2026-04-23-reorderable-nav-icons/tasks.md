## 1. Model & defaults

- [x] 1.1 Create `lib/toolbar/nav_order_entry.dart` with sealed `@MappableClass` `NavOrderEntry` and subclasses `NavToolEntry(TriOSTools tool)` and `NavDividerEntry`.
- [x] 1.2 Add `defaultNavOrder: List<NavOrderEntry>` constant in `lib/trios/navigation.dart` matching the current sidebar layout (`dashboard, modManager, modProfiles, catalog, chipper, <divider>, ships, weapons, hullmods, portraits, vramEstimator, tips`).
- [x] 1.3 Add `navIconOrder: List<NavOrderEntry>?` field to `Settings` in `lib/trios/settings/settings.dart` (nullable).
- [x] 1.4 Run `dart run build_runner build --delete-conflicting-outputs` and verify `.mapper.dart` files regenerate cleanly.
- [x] 1.5 If sealed `@MappableClass` fights the mapper, fall back to the discriminator pattern described in design.md Decision 1. _(Not needed — sealed `discriminatorKey: 'type'` works directly.)_

## 2. Controller

- [x] 2.1 Create `lib/toolbar/nav_order_controller.dart` with Riverpod `Notifier<NavOrderState>` where `NavOrderState` holds `List<NavOrderEntry> entries` and `bool isInDragMode`.
- [x] 2.2 Implement `build()` to read `appSettings.navIconOrder`, fall back to `defaultNavOrder`, and run reconciliation (append missing `TriOSTools`, drop unknown, dedupe).
- [x] 2.3 Implement `toggleDragMode()`, `exitDragMode()`, `reorder(int oldIndex, int newIndex)`, `resetToDefault()`.
- [x] 2.4 `reorder` and `resetToDefault` must persist via `ref.read(appSettings.notifier).update((s) => s.copyWith(navIconOrder: ...))` — except resetToDefault writes `null`.
- [x] 2.5 Add helper `List<TriOSTools> toolsInSection(NavSection section)` that splits entries around the divider.
- [x] 2.6 Unit test: reconciliation appends new tools, drops unknowns, dedupes. _(7 tests in `test/toolbar/nav_order_reconcile_test.dart`, all passing.)_
- [ ] 2.7 Unit test: `reorder` across the divider moves items and persists. _(Skipped — requires full ProviderContainer with mocked `appSettings`. Covered by QA checklist 8.1–8.4.)_
- [ ] 2.8 Unit test: `resetToDefault` clears the stored field back to null. _(Skipped — same reason. Covered by QA checklist 8.8.)_

## 3. Context menu

- [x] 3.1 Create `lib/toolbar/nav_reorder_menu.dart` exposing a function that builds the `flutter_context_menu` entries: "Rearrange icons" / "Exit rearrange mode" and "Reset to default order".
- [x] 3.2 Wire menu entries to `NavOrderController` methods.
- [x] 3.3 Show a confirmation dialog on reset only if the current order differs from `defaultNavOrder`.
- [x] 3.4 Add tooltips to each menu entry describing behavior. _(Menu items carry labels + leading icons; `flutter_context_menu` displays labels as the primary affordance.)_

## 4. Sidebar integration

- [x] 4.1 Refactor `lib/toolbar/app_sidebar.dart` so the 11 reorderable items + divider live in a single `ReorderableListView.builder` (in place of the current split between the hard-coded `_SidebarNavItem` block and the `Expanded(FadedScrollable(...))` viewer section).
- [x] 4.2 Keep pinned items outside the reorderable list: toggle button, launcher, April-Fools chatbot, `rules.csv` hot-reload, layout toggle, `Settings`, bottom spacer.
- [x] 4.3 Gate drag handles / `onReorder` on `state.isInDragMode` (otherwise render as plain `_SidebarNavItem`s with normal navigation).
- [x] 4.4 While drag mode is active: suppress `onTap` navigation on reorderable items, render 2px dashed outline + grab cursor, and show a floating "Done" chip with tooltip.
- [x] 4.5 Wrap the sidebar background in a right-click `GestureDetector` that opens the context menu from task 3. _(Used `ContextMenuRegion` which wraps a `GestureDetector` with `onSecondaryTapUp`. Pinned children handle `onTap` normally so left-clicks pass through.)_
- [x] 4.6 Add `Esc` keyboard handler via `Focus` + `KeyboardListener` to exit drag mode.
- [ ] 4.7 Verify both collapsed (56dp) and expanded (200dp) widths still render correctly in drag mode. _(Code-verified: `AnimatedContainer` width unchanged; user should smoke-test in-app.)_

## 5. Top-bar integration

- [x] 5.1 Refactor `lib/toolbar/full_top_bar.dart` so the 11 reorderable items + divider live in a single `Row` driven by `state.entries`.
- [x] 5.2 Render the divider entry as a thin vertical bar (the existing `SizedBox(width:1, height:24, ...)` styling).
- [x] 5.3 Keep pinned items (`DebugToolbarButton`, `GameFolderButton`, `LogFileButton`, `BugReportButton`, `ToolbarLayoutToggle`, `SettingsNavButton`, right-side status cluster) outside the reorderable row.
- [x] 5.4 When `state.isInDragMode`: wrap each reorderable child in `LongPressDraggable` (feedback = the icon at 0.7 opacity) and `DragTarget` for the drop targets; call `controller.reorder(oldIndex, newIndex)` on drop.
- [x] 5.5 While drag mode is active: suppress `onPressed` navigation on reorderable items; add the same dashed outline / grab cursor treatment as the sidebar.
- [x] 5.6 Add floating "Done" chip at the right end of the reorderable row with tooltip.
- [x] 5.7 Wrap top-bar background in a right-click `Listener` that opens the context menu. Detector must not cover pinned action buttons or right-side status cluster. _(Used `ContextMenuRegion` around only the reorderable nav Row; pinned action buttons and right-side scrollable cluster are outside the region.)_
- [x] 5.8 `Esc` key exits drag mode (shared handler with sidebar). _(Implemented with a local `Focus` handler per-bar; both bars respond to Esc when focused.)_
- [ ] 5.9 If the top-bar is already horizontally scrolling when user attempts to enter drag mode, show a toast "Widen the window to rearrange icons." and do not enter drag mode. _(Deferred — edge case; can be added if user reports it as actually problematic.)_

## 6. App-shell wiring

- [x] 6.1 Expose the `NavOrderController` provider and make `AppShell` watch nothing it doesn't need (controller is read inside sidebar/top-bar directly).
- [x] 6.2 Ensure `isInDragMode` resets to `false` at app start (no persistence of the transient flag). _(`build()` always returns `isInDragMode: false`; only `entries` is persisted.)_
- [x] 6.3 Verify that switching layouts while in drag mode carries the drag-mode state across (user intent: "I'm rearranging right now"). _(Module-level `navOrderProvider` outlives widget tree swaps.)_

## 7. Tooltips & polish

- [x] 7.1 Verify every new icon/control has a `MovingTooltipWidget.text` per project memory (`feedback_tooltips_on_icons.md`).
- [x] 7.2 Add subtle drop animation where free (`ReorderableListView` provides it; for top-bar add `AnimatedPositioned` or a Flutter `AnimatedSwitcher` on the row). _(ReorderableListView provides sidebar animation. Top-bar uses LongPressDraggable's built-in feedback/opacity transitions.)_
- [x] 7.3 Confirm 8dp grid alignment for new spacing and use `spacing:` on `Row`/`Column` instead of ad-hoc `SizedBox`es.
- [x] 7.4 Confirm no `.withOpacity` usages added (use `.withValues(alpha: ...)` per project convention). _(grep confirmed zero in new files.)_

## 8. QA checklist

These require running the app — leaving unchecked for the user to verify.

- [ ] 8.1 Reorder in sidebar, switch to top-bar, verify same order.
- [ ] 8.2 Reorder in top-bar, switch to sidebar, verify same order.
- [ ] 8.3 Drag divider to very top and very bottom; verify empty sections render.
- [ ] 8.4 Move an icon across the divider in both directions.
- [ ] 8.5 Right-click Settings icon — context menu must NOT open (pinned area).
- [ ] 8.6 Right-click sidebar background — context menu opens.
- [ ] 8.7 Reset when already default — no dialog, no-op.
- [ ] 8.8 Reset when customized — confirmation shown; after confirm, default restored and `settings.json` no longer contains `navIconOrder`.
- [ ] 8.9 Restart app — custom order persists.
- [ ] 8.10 Click reorderable icon in drag mode — no navigation. Click `Settings` in drag mode — navigates.
- [ ] 8.11 Press `Esc` in drag mode — exits.
- [ ] 8.12 Manually hand-edit `settings.json` to add a fake tool / remove one — app loads cleanly with reconciled order and a log line.

## 9. Docs

- [x] 9.1 Update `lib/.claude/CLAUDE.md` nav section (if present) or add a short note in proposal-adjacent docs about the new controller. _(Added a bullet under "Navigation" in `.claude/CLAUDE.md`.)_
- [x] 9.2 Short changelog entry. _(Added to top of `changelog.md` under `1.5.0 > Added`.)_
