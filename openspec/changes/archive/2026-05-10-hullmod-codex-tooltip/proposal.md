# Hullmod Codex Tooltip

## Problem

The ship and weapon viewer pages show rich, game-style codex tooltips when hovering over item names in the grid. The hullmod viewer has no equivalent — its info is only accessible via a dialog triggered by clicking the info icon. This is inconsistent and requires an extra click.

## Proposed Solution

Create a `HullmodCodexCard` widget that follows the exact same pattern as `ShipCodexCard` and `WeaponCodexCard`:

- A `tooltip()` static method wrapping grid items in `MovingTooltipWidget.starsector()`
- A `create()` static method for standalone use (e.g. in the split pane)
- A private `_buildHullmodContent()` that uses the shared `ingame_tooltip_shared.dart` utilities (section headers, stat grids, formatting)

Attach the tooltip to the hullmod name column in the grid, matching how ships and weapons do it.

## Scope

- New file: `lib/hullmod_viewer/widgets/hullmod_codex_card.dart`
- Modify: hullmod name column in `hullmods_page.dart` to use the tooltip
- Optionally replace the info icon's `_buildInfoPane` with `HullmodCodexCard.create()`

## Non-Goals

- Redesigning the hullmod grid layout or columns
- Adding new data fields to the hullmod model
- Changing tooltip behavior for ships or weapons
