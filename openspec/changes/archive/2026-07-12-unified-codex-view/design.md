# Design — Unified Codex view

## Goal

One new tab that pools the existing game-data loaders into a single, searchable,
cross-linked encyclopedia that works like the in-game Codex ("V2"). Reuse everything
possible. `game-codex-reference.md` in this folder is the analysis of the game's
implementation; this design maps it onto TriOS.

## What already exists (reuse, don't rebuild)

- **Loaders** — `shipListNotifierProvider` (`lib/ship_viewer/ship_manager.dart`),
  `weaponListNotifierProvider` (`lib/weapon_viewer/weapons_manager.dart`),
  `hullmodListNotifierProvider` (`lib/hullmod_viewer/hullmods_manager.dart`), and
  `factionListNotifierProvider` (`lib/faction_viewer/faction_manager.dart`). These four
  are cached, mod-aware, and built on `CachedStreamListNotifier`. Ship systems load
  through a different, simpler provider: `shipSystemsStreamProvider`
  (`lib/ship_systems_manager/ship_systems_manager.dart`), a plain
  `StreamProvider<List<ShipSystem>>`. It is mod-aware but does not use the
  `CachedStreamListNotifier` payload/cache interface, so the combined index has to read
  it as its own shape rather than treating all sources the same way.
- **Cards** — `ShipCodexCard` (`lib/ship_viewer/widgets/ship_codex_card.dart`),
  `WeaponCodexCard` (`lib/weapon_viewer/widgets/weapon_codex_card.dart`), and
  `HullmodCodexCard` (`lib/hullmod_viewer/widgets/hullmod_codex_card.dart`) render full
  in-game-style stat panels. All three have a static `.tooltip(...)` factory that wraps
  a child widget in a hover tooltip showing the card. `ShipCodexCard` already nests a
  `WeaponCodexCard` on hover for built-in weapons — proof the cross-reference data is
  present. Factions use `FactionCard`
  (`lib/faction_viewer/widgets/faction_card.dart`), a plain `StatelessWidget` — not a
  codex-styled card and not built to nest or cross-link like the other three. It is
  still reusable in the detail panel, but do not assume it matches the codex cards in
  looks or in the callback wiring below.
- **Cross-link data on the models** — `Ship` already exposes everything the linking
  pass needs: `systemId`, `builtInWeapons` (slot → weapon id), `builtInMods`,
  `builtInWings`, `baseHullId` (set for skins), and `designation`.
- **Descriptions** — `descriptionProvider` (`lib/descriptions/descriptions_manager.dart`),
  a family provider keyed by `(id, type)` that reads `data/strings/descriptions.csv`
  from the game and all enabled mods. The ship card already uses it for ship-system
  text: `descriptionProvider((ship.systemId!, DescriptionEntry.typeShipSystem))`.
- **Filter chips** — the filter engine (`lib/widgets/filter_engine/`). The ships page
  controller (`_buildFilterController()` in
  `lib/ship_viewer/ships_page_controller.dart`, around line 322) already builds
  `ChipFilterGroup<Ship>` instances for hull size, tech/manufacturer (with
  case-insensitive grouping and a most-common-spelling label helper,
  `_techManufacturerLabel`), mod, and more. The Codex facets are the same thing —
  copy those definitions. Decision made (see section 6): use the filter engine
  as-is; do **not** build a custom tag widget.

## How the game does it (short version)

The game builds one in-memory tree of `CodexEntryPlugin` nodes: categories and leaf
entries alike, with a flat id → entry map beside it. Entry ids are the category prefix
plus the game id (`codex_hull_onslaught`), so `(type, id)` is the stable key for links,
history, and navigation. After all entries exist, a linking pass wires two-way
"related" links. The dialog is: toolbar (back/forward/up/random + search), a left list
you drill into, a detail panel, a related-entries list, and a bottom bar of checkable
tag groups with live counts. Full detail in `game-codex-reference.md`.

TriOS keeps the same shape but flattened: no tree object — the six categories are an
enum, the "tree" is only ever two levels deep (category → entries), and the flat list
plus filters produces what the game's tree walk would.

## New pieces

### 1. A shared codex-entry type

A sealed type so one list can hold any category:

```
sealed class CodexEntry {
  String get id;            // the game id; (type, id) is the stable key
  CodexEntryType get type;  // ship | weapon | hullmod | shipSystem | wing | faction
  String get displayName;
  String get sortName;      // what alphabetical sort uses (ships: hull name)
  String? get subtitle;     // grey second line in the list (see table below)
  Set<String> get modIds;   // for the mod filter; empty = vanilla
}
```

One small subclass per category, each wrapping the existing data object
(`ShipCodexEntry(Ship)`, `WeaponCodexEntry(Weapon)`, etc.). No data is copied; the
subclass just points at the underlying model. Keep the model Flutter-free — icons are
keyed off `type` in the page.

**The models do not share a mod-id field**, so each subclass maps `modIds` its own way:

| Category | Where the mod id lives |
| --- | --- |
| Ship | `ship.modId` (a plain field; also has `modName`) |
| Weapon | `weapon.modVariant?.modInfo.id` (`modVariant` is null for vanilla) |
| Hullmod | `hullmod.modVariant?.modInfo.id` (same rule) |
| Ship system | Nothing today — add it while reworking the manager (see Data additions) |
| Wing | New model — give it a `modVariant` field like Weapon's |
| Faction | `faction.sources` — a faction can come from several mods at once, which is why `modIds` is a set. A faction matches the mod filter if **any** source matches. |

**Subtitles** (the grey second line on each list row, copying the game):

| Category | Subtitle (exact expression) |
| --- | --- |
| Ship | `ship.designation` ("Battleship"; null → no subtitle) |
| Weapon | `'${weapon.size?.toTitleCase()} ${weapon.weaponType?.toLowerCase()} weapon'` ("Medium ballistic weapon"; skip if either field is null) |
| Hullmod | `hullmod.uiTags` as-is (null → no subtitle) |
| Ship system | the description's short "type" line (`text2`; null → no subtitle) |
| Wing | `wing.role`, title-cased ("Interceptor") |
| Faction | none |

### 2. Combined index provider

A Riverpod provider that watches all six sources — the four `CachedStreamListNotifier`
loaders, the ship-systems `StreamProvider`, and the new wings loader — and flattens them
into `List<CodexEntry>`. Each source is already cached or cheap, so this rebuilds
reactively when mods change without extra work.

If two mods (or a mod and the base game) both provide the same id, keep whichever the
loader saw first — this is what `CachedStreamListNotifier._flatten()` already does
within each category, so the combined index inherits it for free. Only guard against
the same id appearing in two different categories: every key is `(type, id)`, never a
bare `id`.

### 2b. What's listed vs. what's only linkable

The game skips whole classes of content (`HIDE_IN_CODEX`, `restricted`, fighter-size
hulls in Ships, system weapons). TriOS instead distinguishes **listed** entries from
entries that are **in the index but unlisted**. Unlisted means: not in the left list,
not in search results, never picked by random — but links still resolve to it and its
detail shows normally when navigated to.

- **Fighter hulls** are in the index but never listed in Ships — reachable only
  through their wing. (The game drops them from Ships entirely; keeping them as link
  targets is what makes wing → ship work.)
- **Hidden weapons** (system/decorative — what the weapons page's "show hidden"
  toggle reveals) are unlisted by default, with the same kind of toggle in the
  Codex's always-present controls. With the toggle off they stay in the index, so a
  ship's built-in hidden weapon still appears in its related panel and card refs.
- **D-hulls / skins:** follow the ships page — whatever it lists, the Codex lists.
  The `baseHullId` links keep skins navigable either way.
- **Ship systems without a description** are still included (TriOS is a modding
  tool — seeing everything is a feature); their type facet buckets them as
  "Special", which is what the game's own tag counting does.

### 3. Related-entries linking pass

A second provider, derived from the combined index, that computes a map
`(type, id) → List<(type, id)>` of two-way "see also" links. Links are stored as keys
and resolved to entries on display, so a link to something from a disabled mod simply
resolves to nothing. The rules (the subset of the game's that apply to our six types):

- **Ship ↔ its ship system** — `ship.systemId`.
- **Ship ↔ its built-in hullmods** — `ship.builtInMods`.
- **Ship ↔ its built-in weapons** — `ship.builtInWeapons.values`.
- **Ship ↔ its built-in wings** — `ship.builtInWings`.
- **Wing ↔ its ship** — the hull id resolved from the wing's `.variant` file.
- **Ships sharing a base hull** — every ship with the same `baseHullId` (skins) links
  to the others and to the base.

Every rule adds the link in both directions — that is what makes a weapon's page list
all the ships that mount it. Factions get no links in v1 (the game's Codex has no
factions at all; linking a faction to its known ships is a possible follow-up).

The related panel sorts links by category, in the game's order:
ship systems → hullmods → weapons → fighters → ships → factions, alphabetical within
each.

### 4. Search

Game behavior, copied:

- The search box searches **within the current category**; at the top level that means
  everything.
- Match: case-insensitive substring over `displayName` + `id`.
- Rank: names that **start with** the query sort above plain substring matches;
  alphabetical within each rank.
- Results replace the left list (a synthetic "Search results" view). Because results
  can mix types, each row shows its category as a small type hint.
- Clearing the box, or pressing the up button/Escape, cancels the search and restores
  the category list.

Do **not** reuse the per-type smart-search DSL (`SearchField<T>` lists): each is typed
to its own item, and running them across one mixed list adds real complexity for
little gain. Substring is also what the game does.

### 5. The page — game layout

`lib/codex/codex_page.dart` — a `ConsumerStatefulWidget` with
`AutomaticKeepAliveClientMixin`, following the existing viewer-page pattern.

```
┌────────────────────────────────────────────────────────────────┐
│ [◀] [▶] [▲] [🎲]                    [ Ctrl-F to search…      ] │  toolbar
├──────────────┬─────────────────────────────────────────────────┤
│ Category ▾   │  detail panel              │  related entries   │
│ (title is a  │  switch(entry.type) →      │  (clickable list,  │
│  dropdown)   │  existing card             │   fixed width)     │
│──────────────│                            │                    │
│  ↑ go up     │                            │                    │
│  entry list  ├────────────────────────────┴────────────────────┤
│  (fixed      │  tag filter groups with counts + mod filter     │
│   width)     │  (scrolls if tall)                              │
└──────────────┴─────────────────────────────────────────────────┘
```

- **Left list** (fixed width, ~288 dip — the game uses 290): at the top level it shows
  the six category rows, each icon + name like the game's root (the root stays a real
  level, not just a dropdown feeder — the game has more categories there and TriOS may
  add more later). Inside a category it shows a pinned "go up" row and then the
  entries, alphabetical by `sortName`, filtered by the tag groups and mod filter.
  Selecting a category drills in; selecting an entry shows its detail. The list builds
  rows lazily (`ListView.builder`) — a modded Ships category can exceed a thousand
  rows, each with a sprite-loading image cell. Row layout is in "List rows" below.
- **Category quick-switch** (TriOS addition): the list's title shows the current
  category and is a dropdown (`TriOSDropdownMenu`) listing all six, so the user can
  jump categories without going up first.
- **Detail panel**: `switch (entry.type)` → the matching existing card (ship / weapon /
  hullmod / faction) or the new ship-system / wing card, in a scroller.
- **Related panel** (fixed width, ~288 dip): the linked entries for the shown entry,
  from the linking pass, as clickable rows (same row widget as the list, with type
  hints). Keeps its width with a quiet empty state when there are no links, so the
  detail panel doesn't shift as you navigate.
- **Tag filter bar** (bottom, only when the current category defines facets): the
  checkable groups from section 6, in a horizontal-wrap layout inside a scroller.

Do **not** use `SideRail` (built as a right-side rail) or `ViewerSplitPane` (splits
top/bottom only). Fixed widths for the two side panels, like the game, keep it simple —
no split-view package needed here.

**List rows.** Like the in-game list, each row shows the entry's image, not just text:
a fixed square image cell (sized to the 8 dip grid), then name + grey subtitle. The
viewer pages already have the image widgets — reuse them, including their hover
effects:

| Category | Row image | Hover effect (keep) |
| --- | --- | --- |
| Ship | `ShipBlueprintView.minimal` (`lib/ship_viewer/widgets/ship_blueprint_view.dart`) | engine glow fades in on row hover; the view is built to let the glow overflow a small grid cell — pass the row's hover state through, same as `ships_page.dart` does |
| Weapon | `WeaponImageCell` — currently defined inside `lib/weapon_viewer/weapons_page.dart` (~line 1112); lift it into `lib/weapon_viewer/widgets/` so the Codex can import it without pulling in the page | weapon glow revealed via its `rowHovered` flag |
| Hullmod | the hullmod icon, as `hullmods_page.dart` renders it (`Image.file`) | none today — none needed |
| Ship system | the `icon` column being turned on in the data work | none |
| Wing | the resolved ship's `ShipBlueprintView.minimal` when the hull is available; a plain type icon when not | engine glow, same as ships |
| Faction | the faction crest/logo, as `FactionCard` shows it | none |

Row hover state comes from `HoverableWidget`/`HoverableRow` (the existing hover
helpers), so the ship and weapon cells get the same `rowHovered` signal they get in
their grids today.

The related panel uses this same row widget (plus a type hint), so images and hover
effects carry over there for free.

**Look and feel:** the *structure* copies the game; the *skin* is TriOS. Use the app
theme's fonts, text styles, and colors — do not import the game's fonts or copy its
pixel styling. Spacing on the 8 dip grid, `spacing` params over `SizedBox`s, and the
row/selection styling should sit next to the existing viewer pages without looking
foreign.

### 5b. Page state and controller

`lib/codex/codex_page_controller.dart` — `CodexPageController extends
Notifier<CodexPageState>`, mirroring the viewer-page pattern.

```
class CodexPageState {
  CodexEntryType? category;            // null = the root category list
  (CodexEntryType, String)? selected;  // the entry shown in the detail panel
  String searchQuery;                  // '' = not searching
  List<CodexSnapshot> history;         // oldest first, capped at 100
  int historyIndex;                    // index of the current snapshot
}

class CodexSnapshot {
  CodexEntryType? category;
  (CodexEntryType, String)? selected;
  String searchQuery;
  // group id -> FilterGroup.serialize() output for the category's facets
  Map<String, Map<String, Object?>> facetSelections;
}
```

Controller methods, one line of intent each:

- `openCategory(type)` — set `category`, clear search, reset that category's facets,
  take a snapshot.
- `goUp()` — if searching, cancel the search; else set `category` to null. Snapshot.
- `select(key)` — set `selected`; if the key's category isn't the current one, switch
  `category` first (the "landing in another category" behavior — highlight the row).
  Snapshot.
- `back()` / `forward()` — move `historyIndex` and restore that snapshot: category,
  selected, search text, and facets via `FilterGroup.restore()`. No new snapshot.
- `randomEntry()` — uniform pick from the listed, filtered index, excluding the
  current entry; then `select` it.
- `setSearch(query)` — update the query; empty string cancels the search.

Facet state lives in the per-category `FilterScopeController`s, not in
`CodexPageState`; snapshots capture it with `serialize()` and put it back with
`restore()`. The spoiler level, mod filter, and show-hidden toggle are **standing
settings** — one shared always-present group, not per-category, never in snapshots.

### 6. Tag filter groups

**Decision: reuse the filter engine exactly the way the ships page does.** Each
category gets a `FilterScopeController` (scope: `FilterScope('codex', <category
name>)`) holding `ChipFilterGroup` definitions, rendered by the existing filter
panel widgets. Keep TriOS's three-state chip semantics (indifferent / include /
exclude) instead of the game's all-checked checkboxes — they express the same
filters, and every other TriOS page already works this way. Do **not** build a
custom tag widget.

**Counts:** the game shows a match count on every tag. Add an opt-in per-chip count
badge to the chip renderer (`lib/widgets/filter_engine/filter_group_renderer.dart` /
`lib/widgets/filter_widget.dart`) behind a new flag that defaults to off, so the
existing viewer pages are pixel-identical. The count for a chip is how many entries
in the spoiler- and mod-filtered category contents have that value. Counts do not
change as chips are toggled (the game computes them once when a category is opened).
Facet selections reset when the category changes, like the game; only a history
restore brings them back (via `FilterGroup.serialize()` / `restore()`, which already
exist).

The facet groups, with the exact value per entry (`valueGetter` unless noted):

| Category | Group | Value |
| --- | --- | --- |
| Ships | Tech/manufacturer | `ship.techManufacturer`, uppercased for grouping, labeled by most common original spelling — copy `_techManufacturerLabel` from `ships_page_controller.dart` (~line 434) |
| Ships | Size | `ship.isStation ? 'Station' : ship.hullSizeForDisplay()` — copy the ships page's `hullSize` group |
| Ships | Type | one value by precedence, mirroring the game: Carrier if `(ship.fighterBays ?? 0) > 0`; else Civilian if `ship.hints` contains `CIVILIAN`; else Phase if `ship.shieldType == 'PHASE'` or `ship.hints` contains `PHASE`; else Warship |
| Weapons | Tech/manufacturer | `weapon.techManufacturer`, same case-folding treatment as ships |
| Weapons | Size | `weapon.size` (SMALL/MEDIUM/LARGE), title-cased for display |
| Weapons | Type | `weapon.weaponType` (BALLISTIC/ENERGY/MISSILE) |
| Weapons | Mount type | `weapon.mountTypeOverride ?? weapon.weaponType` (adds HYBRID/COMPOSITE/SYNERGY/UNIVERSAL) |
| Weapons | Damage type | `weapon.damageType` |
| Hullmods | Tech/manufacturer | `hullmod.techManufacturer`, same treatment |
| Hullmods | Type | `hullmod.uiTags` split on commas and trimmed (`valuesGetter`, multi-value) |
| Fighters | Tech/manufacturer | the linked ship's `techManufacturer` (empty if no ship resolved) |
| Fighters | Role | `wing.role`, title-cased |
| Ship systems | Type | the description's short type line (`text2`); "Special" when missing |
| Factions | none | — |

The **mod filter** and the **spoiler level** are not facet groups — they apply at the
combined index (section 6b) and their controls sit with the facets in the bottom bar.
Accepted tradeoff of index-level mod filtering: with a mod filtered out, a ship's
related panel won't show a built-in weapon from that mod.

Filter persistence follows the viewer pages: the existing `FilterGroupPersistence`
opt-in (the lock toggle) decides whether filter state survives restarts — nothing new
invented here.

### 6b. Spoiler levels

The viewer pages already hide spoiler content behind a spoiler-level field, and the
Codex must too — this is also TriOS's stand-in for the game's lock system (the same
`codex_unlockable`-tagged content the game locks behind encounters is what the
spoiler filter hides).

What exists today, per page:

- **Ships** — three-level `SpoilerLevel` enum (`showNone` / `showSlightSpoilers` /
  `showAllSpoilers`) and a top-level `shipMatchesSpoilerLevel(ship, level)` in
  `lib/ship_viewer/ships_page_controller.dart`. Slight = the `codex_unlockable` tag;
  full = `threat` / `dweller` tags and hidden hulls.
- **Weapons** — two-level `WeaponSpoilerLevel` and top-level
  `weaponMatchesSpoilerLevel` in `lib/weapon_viewer/weapons_page_controller.dart`
  (hides `CODEX_UNLOCKABLE`-tagged weapons).
- **Hullmods** — two-level `HullmodSpoilerLevel`, but its check is a private method
  on the controller — lift it to a top-level function like the other two (move only,
  no behavior change).

All three are `EnumField`s defaulting to "no spoilers", using `inactiveValue` so the
default still shows as an active filter.

The Codex uses **one page-wide control** with the ships' three levels, shown as an
always-present group next to the mod filter. It maps onto each category:

| Category | Rule |
| --- | --- |
| Ship | `shipMatchesSpoilerLevel` as-is |
| Weapon | `weaponMatchesSpoilerLevel`; slight and all behave the same (weapons only have unlockable-tier spoilers) |
| Hullmod | the lifted hullmod check; same two-tier note |
| Wing | spoiler if its resolved ship is (`shipMatchesSpoilerLevel` on the linked ship); if no ship resolves, apply the ship tag lists to the wing's own `tags` column |
| Ship system | apply the ship tag lists to the system's `tags` column (being enabled in the data work) |
| Faction | always shown (the faction viewer has no spoiler filter) |

**Apply it once, at the combined index.** The spoiler level and the mod filter both
filter the index into the view everything else reads — so the list, search, tag-group
counts, the related panel, and the random button all inherit them and hidden entries
can't leak in through a link or a random roll. A related-entry key whose target is
filtered out is dropped the same way a disabled-mod key is.

### 7. Navigation and history

Toolbar buttons, with the game's keys:

| Button | Keys | Action |
| --- | --- | --- |
| Back | Q, Left | previous history snapshot |
| Forward | W, Right | next snapshot |
| Up | E, Up | go up a category, or cancel a search |
| Random | R | open a random entry from the whole index (not the current one) |
| — | Ctrl-F | focus the search box |
| — | Escape | cancel search if searching, else go up |

Shortcuts only fire when the Codex page is visible and the search box is not focused
(Ctrl-F and Escape work regardless). Use a `Focus`/`Shortcuts` wrapper on the page,
not a global handler.

**Landing in another category.** A related-entry click, a card cross-reference, a
mixed-type search result, or the random button can target an entry in a different
category. Copy the game: the left list switches to the target's category with the row
selected — use the existing `Highlightable` widget (glow animation + auto-scroll into
view) for the landing row.

History is a snapshot stack (page state, not persisted, capped at 100 — the game's
cap). Each snapshot records: the current category, the selected entry `(type, id)`,
the search text, and the facet selections (`FilterGroup.serialize()`). The spoiler
level, mod filter, and show-hidden toggle are **not** in snapshots — they are
standing settings, and going back should never silently re-show hidden content.
Scroll positions are not restored — decided, not open. Standard truncation: going
back and then navigating somewhere new drops the forward stack. A snapshot is taken
on every selection (list row, related-entry click, cross-reference click, random).

### 8. Clickable cross-references inside the cards

The existing cards show cross-references as hover tooltips. Inside the Codex we want a
click to navigate — on top of the related panel, which already covers the same links.
This is the largest and riskiest task, because today a reference is a
`WeaponCodexCard.tooltip(weapon:, child:)` wrapper — a hover tooltip, not a clickable
element — and it is built deep inside private helpers (e.g. `_armamentWrap` in
`ShipCodexCard`, around line 669, which calls `WeaponCodexCard.tooltip` for each
built-in weapon). All three codex cards have a `.tooltip()` factory, each with several
call sites that must keep working unchanged:

- `WeaponCodexCard.tooltip` — `faction_profile_dialog.dart`, `weapons_page.dart`,
  `ship_codex_card.dart`
- `HullmodCodexCard.tooltip` — `faction_profile_dialog.dart`, `hullmods_page.dart`
- `ShipCodexCard.tooltip` — `faction_profile_dialog.dart`, `ships_page.dart`

Approach:

- Add an optional `onEntitySelected((CodexEntryType, String))` callback to the reused
  cards, and thread it down through the private helpers and the `.tooltip()` factories
  that build each reference.
- When the card is rendered inside the Codex panel, references (system, built-in
  weapons, wings, hull mods) call this callback to navigate.
- Everywhere else (the existing tabs), the callback is null and behaviour is unchanged —
  hover tooltips as today.

### 9. Register the tab

`lib/trios/navigation.dart` — add `codex` to the `TriOSTools` enum, to
`defaultNavOrder` and `reorderableTools`, and to the `label` / `tooltip` / `icon` /
`group` switch expressions (group: `NavGroup.viewers` — it's an enum value, not a
string). `lib/app_shell.dart` — add the next integer key to `tabToolMap` and add
`CodexPage` at the matching position in the `tabChildren` list (the two must line up;
`toolToIndexMap` is computed from `tabToolMap` automatically). Regenerate
`navigation.mapper.dart` with build_runner.

## Data additions

### Ship systems (light)

`lib/ship_systems_manager/ship_system.dart` already lists the extra fields commented
out, with their `@MappableField` CSV keys in place. Turn them on and update the manager
to read them from `data/shipsystems/ship_systems.csv`. The vanilla CSV columns line up
with the commented fields: `flux/use`, `max uses`, `cooldown`, `toggle` (plus the other
TRUE/FALSE flag columns like `noShield`, `noVent`), `tags`, `icon`. One caveat: the
commented `regenFlat` field (`regen flat`) is **not** in the vanilla CSV header — keep
it nullable or drop it.

While you're in the manager, also stamp each `ShipSystem` with the mod it came from
(the manager already parses one CSV per mod folder, so it knows). The model has no mod
field today, and the Codex mod filter needs one.

Add a small `ShipSystemCodexCard` (name, description, and the handful of stats). For
the description, use the same lookup the ship card already uses:
`descriptionProvider((system.id, DescriptionEntry.typeShipSystem))`.

### Fighters / wings (new)

- **Model** — `lib/fighter_viewer/models/wing.dart` (`@MappableClass`), mapping the
  `data/hulls/wing_data.csv` columns we care about: `id`, `variant`, `tags`, `tier`,
  `rarity`, `fleet pts`, `op cost`, `formation`, `range`, `num`, `role`, `role desc`,
  `refit`, `base value`. The CSV has a few extra columns we skip (`attackRunRange`,
  `attackPositionOffset`). Note the file has both a `num` column (craft count — the one
  we want) and a separate trailing column literally named `number`; map `num`, not
  `number`.
- **Loader** — `WingListNotifier` extending `CachedStreamListNotifier`, with one payload
  type and a cache under a new `wings` domain (the domain is just a string used as a
  cache folder name; there is no registry to update — declare it as
  `String get domain => 'wings';` like the others). Note the existing loaders are not
  as simple as one CSV each: the weapon loader reads `weapon_data.csv` **plus** all
  `.wpn` files, and the ship loader reads `.ship`, `.skin`, and `.variant` files. The
  wing loader is actually the simplest of the family — one CSV per mod folder — plus
  the `.variant` lookup below. Follow `ShipListNotifier`'s `.variant` parsing for that
  part. Give the `Wing` model a `late ModVariant? modVariant` field (null = vanilla),
  same as `Weapon`, so the mod filter works.
- **Link to the ship** — a wing's `variant` column names a `.variant` file (vanilla
  fighter variants live in `data/variants/fighters/`) whose `hullId` is the little ship.
  Resolve that id and expose it: the linking pass uses it for wing ↔ ship, and the wing
  card links through it. Full fighter combat stats come from that linked ship, not from
  the wing row.
- **Card** — `WingCodexCard` (role, points, tier/rarity, number of craft, and a link to
  the ship). Note: `descriptions.csv` has **no** entry type for wings (its types are
  SHIP, WEAPON, SHIP_SYSTEM, FACTION, and a few others), so the wing card has no
  description text of its own — the `role desc` column and the link to the ship are
  what there is.

## Key decisions

- **Copy the game's layout and mechanics; skip its campaign machinery.** Drill-down
  list, related panel, tag groups, full nav — but no locking/unlocking (TriOS has no
  player; the spoiler levels stand in for it) and no tree object (an enum of six
  categories plus a flat list gives the same behavior).
- **Spoilers and the mod filter apply at the index.** One page-wide three-level
  spoiler field (reusing the viewer pages' enums and match functions) plus the mod
  filter both filter the combined index itself, so every downstream view — list,
  search, related panel, random, counts — inherits them and nothing hidden leaks
  through a link.
- **Listed vs. linkable.** Fighter hulls and (by default) hidden weapons don't appear
  in lists, search, or random, but stay in the index so links to them work — the
  TriOS version of the game's skip rules, without losing wing → ship navigation.
- **Category quick-switch dropdown** on the list title — a TriOS improvement over the
  game, where switching categories always means going up first.
- **Related links live in a separate map, not on the model.** The entry wrappers stay
  immutable and Flutter-free; the linking pass is a derived provider keyed by
  `(type, id)`, and dead links (disabled mods) resolve to nothing.
- **Reuse cards, add one optional callback.** Do not fork the cards. The single
  `onEntitySelected` hook keeps the existing tabs untouched while letting the Codex
  navigate on click.
- **One combined index, filtered — not six parallel lists.** Simpler search, one source
  of truth for what the Codex shows.
- **Wings link to ships rather than copy their stats.** Avoids duplicating ship data and
  keeps the wing model small.
- **Factions included as a bonus category**, even though the in-game Codex omits them,
  because the data and card already exist and cost almost nothing to add. No facets and
  no related links for factions in v1.

## Risks / edges

- **Cross-mod references.** A built-in weapon or wing may live in a different mod than
  the ship. The combined index is global, so links resolve by id across all enabled
  mods — but a reference to a disabled/missing mod's item should degrade to plain text
  (in cards) or simply not appear (in the related panel), never a broken link.
- **Duplicate ids across mods.** If two mods provide the same id, the existing loaders
  already keep only the first one they saw; the combined index inherits that rule, so
  each link lands on exactly one entry. Different categories can reuse the same id,
  though — every key is `(type, id)`.
- **Wing → ship resolution** depends on reading `.variant` files. If a variant or hull is
  missing, show the wing without the ship link rather than failing.
- **Keyboard shortcuts.** Q/W/E/R are plain letter keys — they must only fire when the
  Codex page has focus and the search box does not, or they'll eat typing. Scope them
  with a `Focus`/`Shortcuts` wrapper on the page, never a global handler.
- **Linking pass cost.** It runs over the already-cached lists and builds one map —
  cheap, but it re-runs when mods change; keep it a pure function of the combined index
  so Riverpod handles invalidation.
