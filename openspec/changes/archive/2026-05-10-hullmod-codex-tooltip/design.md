# Design: Hullmod Codex Tooltip

## Approach

Follow the established codex card pattern exactly: `ShipCodexCard` and `WeaponCodexCard` both use a private-constructor class with `tooltip()`, `create()`, and a private `_build*Content()` method. The hullmod version will mirror this.

## New File

**`lib/hullmod_viewer/widgets/hullmod_codex_card.dart`**

```
class HullmodCodexCard {
  HullmodCodexCard._();

  static const _maxWidth = 450.0;

  static Widget tooltip({ required Hullmod hullmod, required Widget child, ... })
    → MovingTooltipWidget.starsector wrapping child

  static Widget create({ required Hullmod hullmod, ... })
    → Consumer wrapping _buildHullmodContent

  static Widget _buildHullmodContent(Hullmod, BuildContext, {DescriptionEntry?})
    → Column of sections
}
```

## Tooltip Content Layout

Modeled after the weapon tooltip structure (simpler than ships, similar density):

1. **Title** — `tooltipTitleWithDesignType(name, techManufacturer, true, theme)`
2. **Short description** — italic, dimmed (if present)
3. **Section: "Hullmod data"** — `tooltipSectionHeader`
   - Sprite (left, 40px) + stats grid (right) via a row layout
   - Stats: OP costs per hull size (Frigate/Destroyer/Cruiser/Capital)
   - Tags row (if present)
4. **Section: "S-Mod bonus"** — only if `sModDesc` is non-null
   - `DescriptionWithSubstitutions` for the S-Mod text
5. **Description** — from `desc` field via `DescriptionWithSubstitutions`
6. **CSV description** — from `descriptionProvider` (descriptions.csv lookup)

Uses shared utilities: `tooltipTitle`, `tooltipTitleWithDesignType`, `tooltipSectionHeader`, `tooltipStatsGrid`, `tooltipRow`, `tooltipFmt`.

## Max Width

450px — slightly wider than weapons (400px) to give OP cost labels room, much narrower than ships (780px).

## Grid Integration

In `hullmods_page.dart`, change the `'name'` column's `itemCellBuilder` from plain `TextTriOS` to:

```dart
HullmodCodexCard.tooltip(
  hullmod: item,
  child: MouseRegion(
    cursor: SystemMouseCursors.none,
    child: TextTriOS(item.name ?? item.id, ...),
  ),
)
```

This matches the ship/weapon pattern exactly.

## Info Icon Column

Keep the existing info icon column but switch its tooltip content to use `HullmodCodexCard.create()` instead of `_buildInfoPane()`. This avoids duplicating the layout. The `_buildInfoPane` method and its helpers (`_kv`, `_chip`, `_fmtNum`, `section`) can then be removed.

## Data Dependencies

Unlike ships (which need weapon/system/hullmod maps), hullmods are self-contained — only the `Hullmod` object and its `descriptionProvider` lookup are needed. No controller state maps required.

## Key Decisions

- **Max width 450px**: OP costs have 4 labeled rows that need room, but hullmods have no sprite/stat density like ships.
- **Reuse shared utilities**: All formatting goes through `ingame_tooltip_shared.dart` for visual consistency.
- **SingleChildScrollView**: Wrap content in scroll view (like weapons) since some hullmods have long descriptions.
- **Remove `_buildInfoPane`**: After the codex card replaces it, the private helpers become dead code.
