# New Catalog filters, sorts and card badges

Status: ready-for-agent

## The problem

Starmodder can narrow the mod list in ways the TriOS Catalog can't:

- There is no way to find mods that need a given library, or mods that need nothing.
- There is no "safe to add mid-game" filter, although the scraper reads that answer from most posts that give one.
- There is no "Tool" filter for programs that run outside the game.
- There are no date filters. "Newest" and "Recently active" sorts can't answer "updated since March".
- There is no way to hide mods by what the author says AI was used for.
- Chips show no counts, so you can't tell how many mods a chip will leave before you click it.
- Categories are the raw names from the forum index and Discord tags: 26 overlapping names.

The sort is also forgotten on every restart, and there is no Random sort for browsing.

## The solution

**New filters on the Catalog page:**

- **Requires.** Three-state chips. "Standalone" comes first, then one chip per required mod, most-needed first. Name spellings of the same mod share one chip.
- **Safe to add mid-game** and **Tool.** Two new chips in the Attributes group. Excluding "Safe to add mid-game" keeps the mods the author said *no* for. Mods whose author said nothing are not shown either way.
- **Dates.** Three sliders: Posted, Last edited, Last release.
- **AI use.** Starmodder's presets, plus a Custom mode. It stays visible when AI features are off, because it reads what authors said, not AI-written text.
- **Live counts** on every chip.
- **Categories** become the 13 cleaned names from the extras file.

**Cards** get mod version, WIP and Tool badges on the name line. The tags line uses the cleaned categories.

**Sort:**
- The chosen sort and its direction are remembered between sessions.
- A new Random sort, with a Shuffle button.

## Depends on

`catalog-extras-data` supplies the extras record for each mod and the fallback getters on `CatalogMod`. Before it lands:

- Safe to add, Tool, Requires and AI use work from the details file, through the fallbacks in this change and in `catalog-extras-data`.
- Posted and Last edited work from the dates TriOS has today.
- Last release is hidden.
- Categories stay raw.
- The card badges, live counts and both sort changes need nothing new.

`catalog-search` adds the "Best match" sort. Best match is never the sort that gets saved. `catalog-search` lands first, so this change wires that up: when the current sort is Best match, it saves `sortBeforeSearch` instead.

## In scope

- The filters, counts, badges and sort changes above.
- Three small additions to the shared filter engine:
  - a way for a range slider to show dates
  - a way for an excluded chip to mean "the item said no"
  - a filter group type whose matching and controls are supplied by the page
- Delta specs for `catalog-filter-panel` and `filter-engine`.
- Tests for the AI-use rules, the Requires chip values, the date values and the Random order.

## Out of scope

- Named saved filters, and a "K hidden by your filters" line.
- Counts on dropdowns (Game Version, Installed).
- Calendar date pickers on the date sliders.
- Search changes. Those are in `catalog-search`.
- The details dialog. That is `catalog-details-dialog`.
- Any change to the AI Features settings text.

## Overlap

`advanced-viewer-filters` built `RangeFilterGroup`, shift-click and the group count badges. All its tasks are ticked, but it is not archived yet. Its proposal left Catalog adoption for later. This change is that adoption, plus the three engine additions above.
