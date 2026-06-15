## Context

`flutter_context_menu` is vendored under `lib/thirdparty/flutter_context_menu/`. Its rendering pipeline:

1. `ContextMenuRegion` wraps a child and listens for right-click / secondary-tap.
2. On trigger, it calls `showContextMenu(context, contextMenu: ...)` which pushes a route hosting `ContextMenuWidget`.
3. `ContextMenuWidget` renders the menu inside a `Positioned` at `state.position`.
4. After the first frame, `state.verifyPosition(context)` calls `calculateContextMenuBoundaries` to nudge the menu back on-screen if it overflows.
5. `_buildMenuContent` either returns a plain `Column` of entries or, if `state.maxHeight` is set, wraps the column in `FadedScrollable(SingleChildScrollView(column))`.

The bug: step 4 only translates the menu; it does not constrain its height. Step 5 only scrolls when an explicit `maxHeight` is supplied, which no callsite does.

The WispGrid weapons page header menu has ~20 entries (sort options + grouping + "Then By" submenu marker + 15+ visibility toggles + dividers). On a small window, this menu is taller than the screen. Repositioning to the top still leaves bottom entries clipped.

## Goals / Non-Goals

**Goals:**
- Every context menu, root or submenu, fits on screen by default
- When a menu is capped, it scrolls via the existing `FadedScrollable` infrastructure
- Existing explicit `maxHeight` on `ContextMenu(...)` keeps working (override path preserved)
- Zero churn at callsites
- Fade indicators only show when content is actually clipped

**Non-Goals:**
- Changing the look of context menus (animations, padding, decoration)
- Changing where menus spawn (positioning logic stays the same)
- Reflowing menu entries (e.g. multi-column when tall) — scroll only
- Vertical resizing of submenus to match parent height — each submenu computes its own cap independently

## Decisions

### Where the cap is applied: render layer, not positioning layer

Two candidate locations:

- **A. `calculateContextMenuBoundaries` mutates `menu.maxHeight`** alongside `position`. The render layer reads it and the existing scroll branch in `_buildMenuContent` activates.
- **B. `ContextMenuWidget._buildMenuContent` reads `state.position` + `MediaQuery` and computes the cap inline at render time.**

**Decision: B (render layer).**

`calculateContextMenuBoundaries` is named for its purpose — it returns a `({Offset pos, AlignmentGeometry alignment})` record. Mutating `menu.maxHeight` from inside it is a side effect at a distance and couples positioning to rendering. The render layer already knows the position (after `verifyPosition` has run) and has direct access to `MediaQuery`. Adding the cap there keeps responsibilities cleanly separated.

**Alternative considered**: pass `availableHeight` through `ContextMenuState` as a non-mutating computed field. Equivalent in behavior to B, more plumbing, no extra benefit.

---

### How `MediaQuery` is read after `verifyPosition`

`verifyPosition` runs in a post-frame callback and updates `menu.position`. The render layer's `_buildMenuView` rebuilds when `notifyListeners` fires. By the time the user sees the final positioned menu, `MediaQuery.sizeOf(context)` and `state.position` are both correct. Using `MediaQuery.sizeOf` (not `.of`) avoids unnecessary rebuilds.

---

### The cap formula

```
availableHeight = screenHeight - state.position.dy - safetyMargin
effectiveMax    = state.maxHeight ?? availableHeight
```

`safetyMargin` matches the existing `safeScreenRect.deflate(8.0)` constant in `calculateContextMenuBoundaries` — so 8 logical pixels.

For submenus, `state.position.dy` is already set to the parent-relative spawn point, so the same formula applies without special-casing.

**Edge case: menu spawns near the very bottom of the screen.** `verifyPosition` will already have nudged the menu upward. After that nudge, `state.position.dy` reflects the new top, and the cap remains correct. Tested mentally against `utils.dart:95-104` — the `else if (!isSubmenu)` branch sets `y = max(safeScreenRect.top, menuRect.top - menuRect.height)`, which can leave `y == 0`. The cap then becomes `screenHeight - 8`, which is the correct ceiling.

---

### Fade indicator only when actually clipped

`FadedScrollable` (under `lib/thirdparty/faded_scrollable/`) needs verification. Two possibilities:

- **It already adapts** — fades only when the underlying `ScrollController` reports overflow. Then we wrap unconditionally and we're done.
- **It always draws fades** — wrapping a short menu in a tall constraint would show a top/bottom gradient on every menu. Visually wrong.

If the second case holds, the render layer compares the column's intrinsic height to `effectiveMax` and only wraps when intrinsic > cap. Two paths:

1. `LayoutBuilder` + `IntrinsicHeight` to measure first — adds a layout pass. Acceptable since menus are small.
2. A simpler heuristic: count entries × estimated entry height (~32dp) as an approximation. Cheaper, less correct.

**Decision pending verification of `FadedScrollable`.** Default to (1) if needed. Verification step is task 1.1.

---

### Preserving the override

A callsite that explicitly passes `maxHeight: 200` wants exactly 200, not the screen-fit value. The formula above already handles this — `effectiveMax = state.maxHeight ?? availableHeight` short-circuits when `maxHeight` is set.

A callsite that wants to *opt out* of the screen-fit cap (allow an unbounded menu that overflows) is not supported. No current callsite does this, and it would defeat the bug fix. If a real use case appears, add a sentinel like `maxHeight: double.infinity`.

---

### What about width?

Width has the same theoretical problem — a menu wider than the screen would clip. The current code defaults `maxWidth = 350` which is narrow enough that no callsite hits this. Out of scope; revisit if it ever becomes a real bug.

---

### Submenu interaction

Submenus get their own `ContextMenuState.submenu(...)` and render through the same `ContextMenuWidget._buildMenuContent`. The fix applies uniformly. A long submenu spawning to the right of a near-bottom parent will cap to its own available space.

## Risks / Trade-offs

- **Over-eager scrolling on tall windows.** If a menu is borderline-tall and the window is borderline-short, the user may see a small fade and a tiny scroll region instead of a slightly-taller menu repositioning. Mitigation: the existing `verifyPosition` already does its best to reposition; the cap kicks in only when repositioning is insufficient.

- **Visual regression on existing menus.** If `FadedScrollable` always renders fades, every menu in the app suddenly grows fade gradients. Mitigated by the conditional-wrap path. Must be verified before this lands.

- **Touch / scroll-wheel interaction.** Inside a context menu, scroll-wheel events should scroll the menu, not the underlying page. `SingleChildScrollView` handles this by default; verify with manual test on a long menu.

## Migration

None. Behavior change is invisible to callers. No deprecations.
