# How the in-game Codex works

A reference for building the TriOS Codex, written from the Starsector 0.98a-RC8 API
sources and decompiled game code. Plain-English throughout. File and class names are the
game's; the last section maps them onto TriOS.

---

## 1. There are two Codex systems. Only copy the new one.

The game ships two separate Codex implementations:

- **Old Codex** — package `com.fs.starfarer.codex` (`CodexData.java`). A fixed tree of
  five sections (Ship Hulls, Ship Variants, Fighter Wings, Weapons, Ship Systems). Simple,
  hard-coded, no unlocking. It is dead code kept for reference; the live game does not use it.
- **New Codex ("V2")** — package `com.fs.starfarer.api.impl.codex` (the data) plus
  `com.fs.starfarer.codex2` (the dialog UI). This is what F2 opens in-game. It is the one
  to model TriOS on.

Everything below describes V2 unless it says otherwise.

Key files (all in `sources-api/impl.codex.java` in the starsector-knowledge skill):

| File | Role |
|---|---|
| `CodexDataV2.java` | Builds the whole entry tree at startup. The heart of it. |
| `CodexEntryPlugin.java` | Interface every entry (and every category) implements. |
| `CodexEntryV2.java` | Default implementation of that interface. |
| `CodexDialogAPI.java` | Tiny interface the UI hands to entries so they can navigate. |
| `CodexUnlocker`, `CodexIntelAdder`, `CodexUpdateIntel`, `CodexTextEntryLoader` | Campaign-only extras (unlocking, "new entry" notifications, text articles). TriOS can ignore all of these. |
| `com.fs.starfarer.codex2.CodexDialog.java` | The three-panel window, search, history, keyboard nav. |

---

## 2. The core idea: one tree of entries

There is no database. The Codex is a **tree** built fresh in memory each time it opens,
held in two static fields on `CodexDataV2`:

```java
public static CodexEntryPlugin ROOT;                       // the tree root
public static Map<String, CodexEntryPlugin> ENTRIES;       // flat id -> entry lookup
```

- Every node — a category *or* a leaf item — is a `CodexEntryPlugin`.
- A node is a **category** if it has children or has no backing data object; otherwise it is
  a **leaf** (`isCategory()` returns `!children.isEmpty() || param == null`).
- `param` holds the backing game object (a `ShipHullSpecAPI`, `WeaponSpecAPI`, etc.).
  `param2` is a second optional slot (ships use it to stash a built `FleetMemberAPI`).
- `ENTRIES` is a flat map from entry id to node, rebuilt by walking the tree
  (`rebuildIdToEntryMap()`). It is what search, links, and "open this entry" use.

An entry carries: `id`, `title`, `sortTitle`, `searchString`, `icon`, `parent`,
`children`, `relatedEntries` (a set of ids), plus flags for locking/visibility and a set of
non-player-facing `tags`.

### The build sequence (`CodexDataV2.init()`)

1. Tell every enabled mod plugin `onAboutToStartGeneratingCodex()`.
2. Create each **category** node (empty shells): ships, stations, fighters, weapons,
   hullmods, ship systems, special items, industries, stars & planets, planetary
   conditions, commodities, skills, abilities, gallery. (Factions and terrain exist in the
   code but are commented out.)
3. Add categories to `ROOT` in display order.
4. `rebuildIdToEntryMap()` then `setCatSort()` (assigns each category a sort tier).
5. **Populate** each category — one `populateX()` per category — turning game specs into
   leaf entries and adding them under the right category.
6. Add the hidden "unknown entry" fallback.
7. `rebuildIdToEntryMap()` again (leaves now exist).
8. `onAboutToLinkCodexEntries()` for mods.
9. `sortSkillsCategory()`, then **`linkRelatedEntries()`** — the cross-reference pass.
10. `onCodexDataGenerated()` for mods.

Rebuilds are cheap enough to do on demand: in dev mode Ctrl+Shift+R (`reloadCodexData()`)
throws the whole tree away and calls `init()` again.

---

## 3. The categories and what fills them

Each category is created by a `createXCategory()` method and filled by a `populateX()`
method. The populate methods all follow the same shape: ask `Global.getSettings()` for all
specs of a kind, skip the hidden ones, wrap each survivor in a `CodexEntryV2`, add it to
the category.

| Category | Source (`Global.getSettings()...`) | Notable skip rules |
|---|---|---|
| Ships | `getAllShipHullSpecs()` | skip fighters (unless tagged `SHOW_IN_CODEX_AS_SHIP`), `HIDE_IN_CODEX` hint, `HIDE_IN_CODEX` tag, default D-hulls, `shuttlepod`. Stations (hint `STATION`) go to the Stations category instead. |
| Stations | same list, split out by the `STATION` hint | — |
| Fighters | `getAllFighterWingSpecs()` (wings) | skip restricted/hidden |
| Weapons | `getAllWeaponSpecs()` | skip `restricted`; skip system weapons unless `SHOW_IN_CODEX` |
| Hullmods | `getAllHullModSpecs()` | skip hidden/restricted |
| Ship systems | `getAllShipSystemSpecs()` | must have a description with a `text2` "type" line |
| Special items, Industries, Stars & planets, Conditions, Commodities, Skills, Abilities, Gallery | matching spec lists | category-specific |

For TriOS only the first six matter (ships, weapons, hullmods, ship systems, fighters —
plus factions, which TriOS adds and the game omits).

### Ships also build their modules

When a ship has a variant (`<hullId>_Hull`, or an explicit `getCodexVariantId()`), the
populate step also creates entries for its station modules and stashes a built
`FleetMemberAPI` on `param2`. TriOS does not need this unless it wants multi-module
stations.

---

## 4. Entry ids — the naming convention

Ids are just the category prefix plus the game id. This is the whole scheme
(`CodexDataV2.getXEntryId()`):

```
codex_hull_<hullId>        codex_weapon_<weaponId>     codex_fighter_<wingId>
codex_system_<systemId>    codex_hullmod_<hullModId>   codex_planet_<planetId>
codex_condition_<id>       codex_item_<id>             codex_industry_<id>
codex_commodity_<id>       codex_faction_<id>          codex_skill_<id>
codex_ability_<id>         codex_gallery_<id>
```

Two consequences worth copying:

- The `(type, id)` pair is the stable key for everything — links, history, "open this
  entry." TriOS's `CodexEntry` already keys on `(type, id)`, which matches this exactly.
- Because ids are prefixed by type, the same raw game id (say a weapon and a ship sharing a
  name) never collides.

---

## 5. Related entries — the cross-reference graph

This is the Codex's best feature and the one worth getting right. After all leaves exist,
`linkRelatedEntries()` walks the tree and wires up "see also" links. Links are stored as a
**set of ids** per entry (`related`), resolved to live entries on demand. `makeRelated(a,b)`
adds the link both ways.

The rules it applies:

- **Ships that share a base hull** (skins, D-variants) link to each other.
- **Ship ↔ its ship system** (`spec.getShipSystemId()`), and ↔ its defensive system
  (shields/phase) via `getShipDefenseId()`.
- **Ship system ↔ its drones** — if a system spawns a drone variant, the ship, the system,
  and the drone's hull all link together.
- **Ship ↔ its built-in hullmods** — read from the ship's variant `getHullMods()`. (Special
  case: a ship with `VAST_HANGAR` also links to `CONVERTED_HANGAR`.)
- **Ship ↔ its built-in weapons** — from the variant's fitted weapon slots, skipping
  decorative and system slots.
- **Ship ↔ its built-in fighters** — from the variant's wings.
- **Fighters** repeat the system / hullmod / weapon linking against the wing's own variant.
- **Weapons**: all DEM missiles (tagged `DAMAGE_SOFT_FLUX` + `DAMAGE_SPECIAL`) link to each
  other.
- **Planets/stars**: grouped by shared description; gas giants, pulsars, black holes, nebula
  centers each form a linked group. (Not relevant to TriOS's six types.)

Related entries are shown in the right-hand panel of the detail view, sorted by their
parent category's sort tier (`CAT_SORT_RELATED_ENTRIES`: ship systems first, then hullmods,
weapons, fighters, ships, …). That tier is why a ship's "related" list reads systems →
hullmods → weapons → fighters in a consistent order.

For TriOS the reusable subset is: ship↔system, ship↔built-in hullmods, ship↔built-in
weapons, ship↔built-in fighters, fighter↔its ship. TriOS already reads variants for the
fighter→ship link, so the data is in reach.

---

## 6. The window (the `CodexDialog` UI)

The dialog is a fixed-max-size window (`1280×900`, or smaller on small screens) laid out as
**three regions**:

```
+-----------------------------------------------------------+
| [<] [>] [^] [random]        [ Ctrl-F search box........ ] |   toolbar
+----------------+------------------------------------------+
| category title |  detail title                            |
|                |                                          |
|  ITEM LIST     |   DETAIL PANEL          RELATED ENTRIES  |
|  (290px)       |   (game-style tooltip)  (list, 290px)    |
|                |                                          |
|                +------------------------------------------+
|                |  TAG FILTER BAR (checkable tag groups)   |
+----------------+------------------------------------------+
```

- **Left — item list** (`LIST_WIDTH = 290`). A single-column `UITable` of the current
  category's children. Selecting a category drills in; selecting a leaf shows its detail.
  If the category has a parent, a synthetic "go up" row is inserted at the top.
- **Middle — detail panel** (`CodexDetailPanel`). Renders the selected entry: either a
  built game-style tooltip (title, designation, stats grid, description) or, for entries
  that override `hasCustomDetailPanel()`, a fully custom panel the entry draws itself
  (`createCustomDetail(panel, relatedEntries, codex)`).
- **Right — related entries** (also 290px). The clickable "see also" list from §5.
- **Bottom — tag filter bar** (`M` tag widget in a scroller). Only shown when the current
  category `hasTagDisplay()`. See §7.

### List vs. related rendering

`createTitleForList(info, width, mode)` draws a row differently depending on `ListMode`:

- `ITEM_LIST` — how it looks in the left list (name + designation/subtitle).
- `RELATED_ENTRIES` — how it looks in the right "see also" list (often adds a type hint like
  "Station").

TriOS's card widgets already are the detail panel; the list-row styling is the second thing
to build.

---

## 7. Filtering: the tag bar

Categories that set `hasTagDisplay() = true` build a bar of **checkable tag groups** via
`configureTagDisplay(TagDisplayAPI tags)`. Each group is one facet, each tag a value with a
live count. Examples:

- **Ships**: group "All designs" (one tag per manufacturer, counted), group "All sizes"
  (Frigates/Destroyers/Cruisers/Capitals/Stations), group "All types" (Warships/Phase
  ships/Carriers/Civilian).
- **Weapons**: manufacturer, size (Small/Medium/Large/Fighter), mount type
  (Ballistic/Missile/Energy/Hybrid/…/Beam), damage type (HE/Kinetic/Frag/Energy).
- **Hullmods**: manufacturer, plus type tags incl. D-mods and Intrinsic.
- **Fighters**: manufacturer, role (Fighters/Bombers/Interceptors/Other).
- **Ship systems**: the system "type" text as tags.

The mechanic: each group starts fully checked. When the selection changes, the list keeps
only entries whose `matchesTags(selectedTags)` returns true. Each leaf implements
`matchesTags()` against its own spec (e.g. a ship checks its size tag, phase/civilian/carrier
type, and manufacturer). Counts come from a `CountingMap`.

This is a per-category, multi-facet, "all on by default, uncheck to narrow" filter. TriOS's
three-state filter engine (`FilterGroup`/`FilterScopeController`) is a natural fit; the
game's model is simpler (two-state check, implicit AND across groups, OR within a group).

---

## 8. Search

`Ctrl-F` (or `/`) focuses the search box. On each keystroke `updateSearchResults()` runs:

- It searches **within the current category**, recursively (`getChildrenRecursive(true)`).
- Match test: `entry.getSearchString().toLowerCase().contains(query)` — a plain
  case-insensitive substring match. No DSL, no fielded queries.
- Matches are collected into a throwaway category `"search_results"` and shown in the left
  list using `RELATED_ENTRIES` rendering (so results show their type).
- Locked and invisible entries are excluded.
- Sorting nudges entries whose search string *starts with* the query above mere
  substring matches.
- Clearing the box (or pressing up/escape) calls `abortSearch()` and restores the category.

`getSearchString()` defaults to the title but entries can extend it — e.g. stations append
`" Station"` so "station" finds them.

TriOS's current plan (plain substring over `displayName + id`, across the whole combined
list rather than per-category) is a reasonable simplification. The only game behavior worth
keeping is the "starts-with ranks above contains" nicety.

---

## 9. Navigation and history

The toolbar has four buttons, all with keyboard shortcuts:

| Button | Keys | Action |
|---|---|---|
| Up | E / Up | Go up one category, or cancel a search. |
| Back | Q / Left | Previous history snapshot. |
| Forward | W / Right | Next history snapshot. |
| Random | R | Open a random unlocked, visible leaf (`WeightedRandomPicker`, current entry excluded). |

History is a list of **snapshots** (`CodexDialog.Oo`), capped at `MAX_HISTORY_SIZE = 100`.
Each snapshot records: the current category, the selected detail entry, the search text, and
scroll offsets for the list, the detail panel, and the tag bar. Back/forward restore a
snapshot fully — list, detail, filters, and scroll positions. `takeHistorySnapshot()` is
called on every selection; the standard back/forward truncation applies (going back then
navigating elsewhere drops the forward stack).

The game also remembers `prevEntryId` across opens, and a campaign can force a specific entry
open (`SetCodexEntryId`) — e.g. clicking a ship in the fleet screen opens its Codex page.

For TriOS: a simple back/forward stack of `(type, id)` (plus maybe scroll) covers the useful
part. Random and up-a-level are cheap bonuses.

---

## 10. Locking / unlocking (campaign only — TriOS can skip)

In a campaign, some entries are hidden until the player encounters the thing. This is driven
by tags on the backing spec, checked in `CodexEntryV2`:

- `INVISIBLE_IN_CODEX` — never shown.
- `CODEX_UNLOCKABLE` — shown but **locked** until unlocked (unlock state comes from
  `SharedUnlockData`, e.g. `isPlayerAwareOfShip(hullId)`).
- `CODEX_REQUIRE_RELATED` — visible/unlocked only if a related entry is.
- `allCodexEntriesUnlocked` setting (and dev mode) unlocks everything.

Locked entries can still be listed (greyed, sorted last) if the `showLockedCodexEntries`
setting is on; `CodexUnlocker` / `CodexIntelAdder` / `CodexUpdateIntel` handle unlocking and
the "new Codex entry" notification.

**TriOS has no campaign and no player**, so every entry is simply always visible and
unlocked. Drop this entire subsystem — it removes a lot of complexity.

---

## 11. Where the detail text comes from

The middle panel's description is not stored in the Codex. It is looked up from the game's
`Description` registry by `(id, Description.Type)` — e.g. ship systems use
`getDescription(spec.getId(), Type.SHIP_SYSTEM)` and read `getText1()` (long text) and
`getText2()` (the short "type" line). Ships, weapons, and hullmods have their own
description types.

TriOS already mirrors this: `descriptionProvider((id, DescriptionEntry.typeShipSystem))` is
the same lookup, and `ShipCodexCard` already uses it. So the detail content is a solved
problem in TriOS — the Codex just needs to route each entry type to the right card.

---

## 12. Mapping to TriOS

What to keep, what to drop, and what already exists.

### Reuse directly

- **Model shape.** TriOS's `CodexEntry` (sealed, `(type, id)` key, `modIds` for filtering)
  is the right analogue of `CodexEntryPlugin`. Keep it Flutter-free as done. The game's
  `type` prefix on ids maps to TriOS's `CodexEntryType`.
- **Data sources.** The six per-type managers/notifiers (ships, weapons, hullmods, ship
  systems, wings, factions) are the equivalent of the game's `populateX()` — they already
  load and cache the specs. The combined-index provider flattening them is the equivalent of
  the `ENTRIES` map.
- **Detail cards.** The existing `*CodexCard` widgets are the detail panel. Description
  lookup is already wired.
- **Filtering.** Map the game's per-category tag facets onto TriOS's filter engine
  (category filter + mod filter + per-type facets like size/manufacturer/damage type).

### Build (small)

- **Combined index + substring search** (already planned; per-type DSL not worth reusing).
- **Left list rows** with the two rendering modes (list vs. related), i.e. a compact row
  widget per entry type.
- **Related-entries panel + the linking pass** — the subset from §5 (ship↔system,
  ship↔built-in hullmods/weapons/fighters, fighter↔ship). This is the highest-value feature
  to port.
- **Back/forward history** keyed on `(type, id)`; optionally up-a-level and random.

### Drop entirely

- Locking/unlocking, `SharedUnlockData`, intel notifications, "seen station modules,"
  campaign "open this entry" hooks.
- Old `com.fs.starfarer.codex` package.
- Categories TriOS doesn't cover (planets, conditions, commodities, industries, skills,
  abilities, gallery, special items) — unless later wanted.
- The custom-detail-panel plugin mechanism (`hasCustomDetailPanel`) — TriOS cards cover the
  detail rendering already.

### One difference to note

The game **omits factions** from its Codex (the code is commented out). TriOS adds factions
as a seventh type. That is a TriOS extension, not something to copy — its `modIds` returning
a *set* (a faction can come from several mods) is the right call and has no game equivalent.
