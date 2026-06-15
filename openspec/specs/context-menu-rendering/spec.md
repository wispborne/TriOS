## ADDED Requirements

### Requirement: Screen-fit height cap by default
A `ContextMenu` rendered without an explicit `maxHeight` SHALL be capped to the vertical space available between its final spawn position and the bottom of the screen, minus an 8 logical-pixel safety margin. This applies uniformly to root menus and submenus, after `verifyPosition` has resolved the spawn position.

#### Scenario: Menu shorter than available space
- **WHEN** a context menu's intrinsic content height is less than `screenHeight - position.dy - 8`
- **THEN** the menu renders at its intrinsic height with no scrollbar and no fade indicator

#### Scenario: Menu taller than available space
- **WHEN** a context menu's intrinsic content height exceeds `screenHeight - position.dy - 8`
- **THEN** the menu renders at exactly `screenHeight - position.dy - 8` and is vertically scrollable, with fade indicators at clipped edges

#### Scenario: Submenu capped independently
- **WHEN** a submenu spawns at a position lower than its parent and its content exceeds the remaining space
- **THEN** the submenu caps and scrolls based on its own spawn position, not the parent's

#### Scenario: Menu repositioned then capped
- **WHEN** a menu is initially positioned near the bottom of the screen and `verifyPosition` shifts it upward
- **THEN** the cap is computed from the post-shift position, ensuring the visible menu fits within the screen

---

### Requirement: Explicit `maxHeight` overrides the screen-fit cap
A `ContextMenu` constructed with an explicit non-null `maxHeight` SHALL render at exactly that height regardless of available screen space. Existing callsites that opt into a custom cap retain their previous behavior.

#### Scenario: Explicit cap smaller than screen space
- **WHEN** a `ContextMenu(maxHeight: 200, entries: [...])` is rendered on a window where `screenHeight - position.dy - 8 == 600`
- **THEN** the menu renders at 200dp, scrollable if content exceeds 200dp

#### Scenario: Explicit cap larger than screen space
- **WHEN** a `ContextMenu(maxHeight: 1200, entries: [...])` is rendered on a window where `screenHeight - position.dy - 8 == 600`
- **THEN** the menu renders at 1200dp (per the explicit override) — the caller has opted out of screen fit

---

### Requirement: Fade indicators only when content is clipped
The fade gradient at the top and bottom of a scrollable context menu SHALL render only when the menu's content actually exceeds the effective max height. A short menu spawning near the screen edge MUST NOT show fade gradients.

#### Scenario: Short menu near screen edge
- **WHEN** a menu with 3 entries (~96dp tall) spawns 50dp above the screen bottom (available height ~42dp)
- **THEN** the menu either repositions upward (existing behavior) or caps and shows a fade — but a short menu that fits in its available space MUST render with no fade

#### Scenario: Long menu in tall window
- **WHEN** a menu with 30 entries spawns near the top of a tall window with plenty of space
- **THEN** the menu renders at its full intrinsic height with no fade and no scrollbar
