## Context

`AppShell` picks between `AppSidebar` (sidebar layout) and `FullTopBar` (top-bar layout) based on `appSettings.useTopToolbar`. Both currently hard-code the order of the 11 main navigation icons as separate blocks: a "core" group (Dashboard, Mod Manager, Mod Profiles, Catalog, Chipper) and a "viewers" group (Ships, Weapons, Hullmods, Portraits, VRAM Estimator, Tips). The grouping is reflected in `TriOSToolsUI.group` (`NavGroup.core`/`.viewers`) in `lib/trios/navigation.dart`.

Other buttons on the bars — sidebar toggle, launcher, April-Fools chatbot, `rules.csv` hot-reload, layout toggle, `Settings`, and the action-button cluster (`GameFolderButton`, `LogFileButton`, `BugReportButton`, `DebugToolbarButton`, `ChangelogButton`, `AboutButton`, `DonateButton`, permission shields) — are structural and out of scope for reordering.

Settings are a dart_mappable `@MappableClass` and persist via existing Riverpod providers (`appSettings`). No network or background work is involved; all changes are local.

## Goals / Non-Goals

**Goals:**
- One source of truth for nav order, shared between sidebar and top-bar.
- Drag mode is opt-in (right-click menu) so normal clicks still navigate reliably.
- Users can move icons freely across the core/viewers divider, and can reposition the divider itself.
- Order survives app restarts and new-tool additions without data loss.
- Keeps existing visual grouping (small divider between sections) so the UI doesn't feel "flatter" than today.

**Non-Goals:**
- Rearranging the `Settings`, action buttons, launcher, rainbow bar, chatbot, or rules.csv hot-reload button.
- Hiding or removing icons (out of scope; can be a follow-up).
- Separate orders for sidebar vs. top-bar (explicitly rejected — shared order chosen for simpler UX/storage).
- Per-profile / per-game nav layouts.
- Keyboard-only reordering (tab/arrow keys) — defer to a future accessibility pass.

## Decisions

### Decision 1: Model the order as `List<NavOrderEntry>` where entries are either a tool or the divider

```dart
@MappableClass()
sealed class NavOrderEntry { ... }

@MappableClass()
class NavToolEntry extends NavOrderEntry {
  final TriOSTools tool;
}

@MappableClass()
class NavDividerEntry extends NavOrderEntry {
  const NavDividerEntry();
}
```

**Why:** The divider must be reorderable ("Keep divider, icons flow freely") yet distinguishable from a tool. A sealed dart_mappable hierarchy serializes cleanly and matches existing project conventions (see `lib/utils/dart_mappable_utils.dart` for hooks). Using a sentinel enum value on `TriOSTools` would pollute the domain enum used everywhere else.

**Alternatives considered:**
- `List<TriOSTools?>` with `null` = divider — rejected; null-as-sentinel fights dart_mappable and is fragile.
- Store only the tool order and keep a separate `int dividerIndex` — rejected; two fields must stay in sync under reorder operations.

### Decision 2: Persist only the order, not the drag-mode flag

`navIconOrder: List<NavOrderEntry>?` goes in `Settings`. The `isInDragMode` flag lives only in the `NavOrderController` (Riverpod `Notifier`) and resets to `false` on every app launch.

**Why:** Drag mode is a transient UI state. Persisting it risks trapping a user in drag mode across launches if they quit without exiting, and it's not a "setting" in any meaningful sense.

### Decision 3: Default order falls out of the existing hard-coded layouts

`defaultNavOrder` in `lib/trios/navigation.dart`:
```
dashboard, modManager, modProfiles, catalog, chipper,
<divider>,
ships, weapons, hullmods, portraits, vramEstimator, tips
```

This matches today's sidebar exactly (top-bar has the same core order and a slightly different viewer order starting with VRAM — we pick the sidebar's viewer order as canonical since both layouts now share).

**Migration for existing users:** no stored order ⇒ use default. Stored order present but missing a tool (e.g., we add `TriOSTools.foo` later) ⇒ append missing tools to the end of the list after the divider (or at the end if no divider), and log via `Fimber.i`. Stored order contains an unknown enum value (dart_mappable's `SafeDecodeHook` returns null) ⇒ drop that entry silently.

### Decision 4: Controller API — toolkit, not framework

```dart
class NavOrderController extends Notifier<NavOrderState> {
  void toggleDragMode();
  void exitDragMode();
  void reorder(int oldIndex, int newIndex);
  void resetToDefault();
  List<TriOSTools> toolsInSection(NavSection section); // core | viewers, split by divider
}
```

The widgets (`AppSidebar`, `FullTopBar`) read `state.entries` and `state.isInDragMode`, and call `reorder(...)` on drop. This mirrors `FilterScopeController` style from the existing codebase — expose primitive ops, let pages compose.

### Decision 5: Drag UI — use Flutter's `ReorderableListView`/`ReorderableListView.builder` in sidebar and a custom `Row` with `Draggable`/`DragTarget` in top-bar

**Sidebar:** the existing `SingleChildScrollView` + `Column` for viewers is already a vertical list — swap to `ReorderableListView` only while drag mode is active, keeping the collapsed-width (56dp) and expanded-width (200dp) behavior. Core items need to be in the same reorderable too (they currently sit above the divider in a non-scrolling section). To unify, move all 11 items + divider into a single `ReorderableListView` that lives where the existing `Expanded(child: FadedScrollable(...))` lives, but extended to also include core items above. The non-reorderable bottom items (`rules.csv`, layout toggle, `Settings`) stay outside the reorderable list.

**Top-bar:** `ReorderableListView` doesn't fit a horizontal `AppBar` cleanly. Use `Row` + per-item `LongPressDraggable`/`DragTarget` when `isInDragMode`, wrapping each `_coreTabButton` / `_viewerIconButton` (and a new `_DividerNub` widget).

**Why not custom for both?** Sidebar reorder is vertical and matches ReorderableListView's design exactly. Top-bar needs horizontal drag in a cramped `AppBar`; ReorderableListView doesn't support being embedded in a Row cleanly.

**Alternatives considered:**
- `reorderables` package for both — adds a dep for marginal benefit.
- Mouse-drag even without drag mode — rejected; would make navigation feel fragile (accidental drags on click-and-drag-to-scroll pages).

### Decision 6: Right-click menu uses the existing `flutter_context_menu`

The codebase already imports `package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart` in `app_shell.dart`. Reuse that for the new menu rather than adding a dependency or rolling our own. The menu attaches to a `GestureDetector` (or `Listener`) wrapping the sidebar/toolbar background area — but NOT the action-button cluster (so right-clicking a "Bug Report" button doesn't pop this menu).

Menu items:
- **Rearrange icons** (toggles drag mode; label becomes **Exit rearrange mode** while active)
- **Reset to default order** (with confirmation via a lightweight dialog if custom order is non-default)

### Decision 7: Drag-mode visual affordances

While `isInDragMode`:
- Reorderable items get a subtle 2px dashed border + grab cursor.
- Clicks on icons are consumed by the drag handler (no navigation).
- A small floating **Done** chip appears in a consistent location (top of sidebar / right end of top-bar's nav section).
- Pressing `Esc` exits drag mode (wire via a `Focus` + `KeyboardListener` on the toolbar).

## Risks / Trade-offs

- **[Risk] Top-bar horizontal drag is fiddly at small window widths** → Mitigation: disable drag-mode entry if the top-bar is already horizontally scrolled; show a toast "Widen window to rearrange icons." Also: `LongPressDraggable` with ~150ms delay avoids accidental drags during window-size changes.
- **[Risk] Divider becomes confusing if user drags all items to one side** → Mitigation: allow empty sections — divider renders as a thin line even with no items above/below. Document in the reset tooltip.
- **[Risk] Settings migration when `TriOSTools` gains a new value** → Mitigation: `NavOrderController` runs a reconcile step on load that appends missing tools and drops unknown ones. Covered by a unit test.
- **[Risk] dart_mappable sealed-class support gotcha** → Mitigation: follow the existing pattern in the codebase for sealed `@MappableClass` (verify at build time via `dart run build_runner build`). If the sealed approach fights the mapper, fallback to a single `@MappableClass` with `String kind; TriOSTools? tool;` discriminator.
- **[Trade-off] Shared order means top-bar layout can't diverge** → Accepted per product decision. If users complain, adding a per-layout override later is additive (new settings field) and doesn't break this design.
- **[Trade-off] Keeping the divider as a draggable entry adds a model concept** → Accepted; alternative (hidden fixed divider) loses the "move section boundary" capability the user asked for.

## Migration Plan

1. Ship `navIconOrder` as nullable — existing users' `settings.json` remains valid and reads as "use default."
2. First app launch after the update: `NavOrderController` loads, sees null, populates `state.entries` from `defaultNavOrder`, but does NOT write it back to settings until the user makes a change. This keeps settings files clean for users who never customize.
3. Reset to default: clears `navIconOrder` to null (same as fresh install).
4. No rollback concerns — removing the feature in a future release just means the stored `navIconOrder` is ignored.

## Open Questions

- Should the "Reset to default order" confirmation dialog always show, or only when the current order differs from the default? (Leaning: only when different, to avoid an annoying confirm for no-op resets.)
- Do we want a subtle animation on the sidebar when an icon is dropped? `ReorderableListView` provides this free; top-bar custom implementation will need `AnimatedPositioned` or similar. Default to Flutter defaults; revisit if it feels jumpy.
