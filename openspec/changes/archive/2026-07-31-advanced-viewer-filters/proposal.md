# Advanced filtering for viewer pages

## The problem

The ship, weapon, hullmod, and other viewer pages have tri-state chip filters
(include / exclude / ignore) and a search DSL. Those cover the simple cases
well — "show me frigates", "hide utility mods". But they can't express the
query people actually reach for when comparing loadouts:

- "Ships with both a large ballistic *and* a large missile mount." The chips
  are OR-only, so picking two slots means "has either one", not "has both".
- "Ships between 10 and 30 deployment points." There's no numeric range
  control at all — you'd have to type a DSL query and know the syntax.
- In groups with many values (weapons by hullmod, ships by faction), the chip
  list is long and there's no way to search or collapse it.

The filter panel also has a fixed width in the sidebar and no way to get more
room when you're doing serious filtering work.

## The solution

Add numeric range sliders, a search box, and a few shortcuts to the existing
filter panel, plus an Advanced mode toggle. Advanced mode only adds the
per-group logic controls — the one part that raises a question for casual
use. Everything else is on show all the time.

### Per-group include logic

Each chip group gets a button that cycles between:

- **any** (default) — the item must have at least one of the included values.
  This is the current behavior.
- **all** — the item must have every included value. This is the new query
  that's currently impossible.

The button only appears when Advanced mode is on, *unless* the group is set to
a non-default mode. If someone picks "all", turns Advanced off, and the group
keeps behaving differently with no visible reason, that's a bug. Non-default
controls stay visible regardless of the toggle.

Exclude logic stays as-is: any excluded value vetoes the item. No per-group
mode for excludes — see "Decisions" below for why.

### Numeric range filters

New filter group type for numeric stats (deployment points, armor, hull, flux
dissipation, speed, OP, range, damage, etc.). Each renders as a two-handle
slider. Features:

- Snap to values that actually exist in the data, so the stops are meaningful.
- The top handle means "and above" — capitals with 60 DP don't fall off the
  end of a slider that stops at 60.
- Collapsed summary shows the selected range as text (e.g. "10–40" or
  "20+").
- Always visible — sliders are self-explanatory and hiding them behind a
  toggle hurts discoverability.

### Search inside the filter panel

A search box at the top of the panel that filters the chips themselves and
hides groups with no matching chip. Necessary when a group has dozens of
values. The All / Clear buttons should respect the search — only touch chips
that match the current search term. Shift-click ignores the search and touches
everything.

### Expand to dialog

A button in the panel header opens the same filter widget in a dialog. Same
live updating — the grid keeps filtering as you click. No Save/Cancel; changes
apply immediately in both views. The dialog just gives more room.

### Collapsible groups with count badges

Groups can be collapsed to a single header line. When collapsed, the header
shows counts: how many values are included and how many are excluded. This
keeps the panel short while still showing that a group is doing something.

Chip groups already support `collapsedByDefault`. This extends that with the
badge counts.

### Shift-click to solo

Shift-clicking a chip clears every other chip in that group and sets the
clicked one to "include". One-click "only this" shortcut.

## Decisions

**Include mode only, no exclude mode.** Exclusion is a veto — "never show me
those." That's OR, and it's what everyone assumes. The other exclude modes
(AND: "drop it only if it has every red tag"; XOR: "drop it if exactly one
matches") are hard to predict and almost never useful. For the one case where
exclude-AND helps — hiding a combination like "low tech frigate" — the two
properties live in separate filter groups, so a per-group exclude mode couldn't
express it anyway.

**Words, not operator names.** The logic button says "any" / "all" rather than
OR / AND. "Weapon slots: all" reads correctly without knowing boolean algebra.

**No cross-group custom combine mode.** 5e.tools has a top-level AND / OR /
Custom selector for how groups combine. TriOS groups combine as AND (every
group must pass), which is what people expect. A custom mode that lets you mark
some groups as OR adds a dialog, more state, and covers a rare edge case.
Skip it.

**No "exactly one" (XOR) at first.** The same button can cycle through three
modes later if anyone asks. Start with two.

**Advanced only controls the logic buttons.** Range sliders, search, badges,
shift-click, and expand-to-dialog are always visible — they're all
self-explanatory. The logic button is the only control where seeing it without
context raises a question. Advanced is per-page and remembered.

**Range sliders and the search DSL.** The DSL already supports `damage:>100`.
Range sliders are a different entry point for the same query. They should feed
the same filter pipeline, not duplicate it. Whether a range was set by slider
or by DSL, the result is one filter predicate. The DSL doesn't need to learn
new syntax — it already handles comparisons.

## In scope

- Advanced mode toggle in the filter panel header, per page, persisted.
- Per-group "any" / "all" logic button for chip groups.
- New `RangeFilterGroup` type with two-handle slider, snap-to-data, and
  "and above" top stop.
- Search box inside the filter panel that filters chips and hides empty groups.
- Expand-to-dialog button that shows the same filter widget in a roomy dialog.
- Collapsed group count badges (include count, exclude count).
- Shift-click to solo a chip.
- Ships and weapons pages as the first two adopters (they benefit most from
  range filters and multi-value slot queries).

## Out of scope

- Exclude logic modes (AND / XOR per group for red chips).
- Cross-group combine mode (AND / OR / Custom across all groups).
- "Exactly one" (XOR) include mode.
- Named filter presets / snapshots (useful, but a separate change).
- Resizable panel width via drag handle (worth exploring separately).
- Changes to the search DSL syntax.
- Viewer pages beyond ships and weapons in this change (hullmods, factions,
  fighters, ship systems, portraits, catalog can adopt later).
