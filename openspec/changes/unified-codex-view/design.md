# Design — Unified Codex view

## Goal

One new tab that pools the existing game-data loaders into a single, searchable,
cross-linked encyclopedia, styled after the in-game Codex. Reuse everything possible.

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
- **Descriptions** — `descriptionProvider` (`lib/descriptions/descriptions_manager.dart`),
  a family provider keyed by `(id, type)` that reads `data/strings/descriptions.csv`
  from the game and all enabled mods. The ship card already uses it for ship-system
  text: `descriptionProvider((ship.systemId!, DescriptionEntry.typeShipSystem))`.
- **Layout / search** — the filter engine and the smart-search field metadata
  (`SearchField<T>` / `SearchFieldMeta` in `lib/widgets/smart_search/`). Each viewer
  page controller builds its own `List<SearchField<T>>` in a `_buildSearchFields()`
  method — see `lib/ship_viewer/ships_page_controller.dart` for the richest example.
  Note: `SideRail` (`lib/catalog/side_rail/side_rail.dart`) is built as a
  **right-side** rail and `ViewerSplitPane` only splits **top/bottom** — neither fits
  this page's left-to-right layout as-is (see section 3).

## New pieces

### 1. A shared codex-entry type

A sealed type so one list can hold any category:

```
sealed class CodexEntry {
  String get id;            // stable id used for links and history
  CodexEntryType get type;  // ship | weapon | hullmod | shipSystem | wing | faction
  String get displayName;
  String? get modId;        // for the mod filter
  Widget icon(...);
}
```

One small subclass per category, each wrapping the existing data object
(`ShipCodexEntry(Ship)`, `WeaponCodexEntry(Weapon)`, etc.). No data is copied; the
subclass just points at the underlying model.

**The models do not share a mod-id field**, so each subclass maps `modId` its own way:

| Category | Where the mod id lives |
| --- | --- |
| Ship | `ship.modId` (a plain field; also has `modName`) |
| Weapon | `weapon.modVariant?.modInfo.id` (`modVariant` is null for vanilla) |
| Hullmod | `hullmod.modVariant?.modInfo.id` (same rule) |
| Ship system | Nothing today — add it while reworking the manager (see Data additions) |
| Wing | New model — give it a `modVariant` field like Weapon's |
| Faction | `faction.sources` — a faction can come from several mods at once. For the mod filter, treat a faction as matching if **any** source matches. |

### 2. Combined index provider

A Riverpod provider that watches all six sources — the four `CachedStreamListNotifier`
loaders, the ship-systems `StreamProvider`, and the new wings loader — and flattens them
into `List<CodexEntry>`. The four cached loaders and wings share the same payload shape;
ship systems is read separately as its own `List<ShipSystem>`. Each source is already
cached or cheap, so this rebuilds reactively when mods change without extra work. Search
filters this one list. Category and mod filters are plain `where` clauses over `type` and
`modId` (using the per-category mapping above; factions match on any source).

If two mods (or a mod and the base game) both provide the same id, keep whichever the
loader saw first — this is what `CachedStreamListNotifier._flatten()` already does
within each category, so the combined index inherits it for free. Only guard against
the same id appearing in two different categories: make history/link keys
`(type, id)`, not bare `id`.

Search reuses the existing per-type search field metadata where it exists; the default
match is on `displayName` and `id`.

### 3. The three-panel page

`lib/codex/codex_page.dart` — a `ConsumerStatefulWidget` with
`AutomaticKeepAliveClientMixin`, following the existing viewer-page pattern.

```
┌──────────┬──────────────────────┬───────────────────────────┐
│ category │  search results      │  detail panel             │
│  + mod   │  (from combined      │  switch(entry.type) →     │
│  filter  │   index)             │  reuse existing card      │
└──────────┴──────────────────────┴───────────────────────────┘
```

Do **not** reuse `SideRail` or `ViewerSplitPane` here — `SideRail` is hard-coded as a
right-side rail, and `ViewerSplitPane` hard-codes `axis: Axis.vertical` (top/bottom
split). Instead:

- **Left panel:** a plain fixed-width `Column`/`ListView` of category tiles plus the
  mod filter. Nothing fancy.
- **Middle + right:** use `MultiSplitView` from the `multi_split_view` package directly
  (the same package `ViewerSplitPane` wraps) with `axis: Axis.horizontal`, so the user
  can drag the divider between results and detail. Copy the divider theming from
  `lib/widgets/viewer_split_pane.dart`.

### 4. Clickable cross-references + history

The existing cards show cross-references as hover tooltips. Inside the Codex we want a
click to navigate. This is the largest and riskiest task, because today a reference is a
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

- Add an optional `onEntitySelected(CodexEntryRef)` callback to the reused cards, and
  thread it down through the private helpers and the `.tooltip()` factories that build
  each reference.
- When the card is rendered inside the Codex panel, references (system, built-in
  weapons, wings, hull mods) call this callback to navigate. The `Ship` model exposes
  these as ids — `systemId`, `builtInWeapons`, `builtInMods`, `builtInWings` — which the
  combined index resolves to entries.
- Everywhere else (the existing tabs), the callback is null and behaviour is unchanged —
  hover tooltips as today.

The page keeps a simple history stack of selected entries so a **Back** button (and
forward) can walk the chain. This is page state, not persisted.

### 5. Register the tab

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
  For v1, resolve that id and expose it so the wing card can link to the ship entry. Full
  fighter combat stats come from that linked ship, not from the wing row.
- **Card** — `WingCodexCard` (role, points, tier/rarity, number of craft, and a link to
  the ship). Note: `descriptions.csv` has **no** entry type for wings (its types are
  SHIP, WEAPON, SHIP_SYSTEM, FACTION, and a few others), so the wing card has no
  description text of its own — the `role desc` column and the link to the ship are
  what there is.

## Key decisions

- **Reuse cards, add one optional callback.** Do not fork the cards. The single
  `onEntitySelected` hook keeps the existing tabs untouched while letting the Codex
  navigate on click.
- **One combined index, filtered — not six parallel lists.** Simpler search, one source
  of truth for what the Codex shows.
- **Wings link to ships rather than copy their stats.** Avoids duplicating ship data and
  keeps the wing model small.
- **Factions included as a bonus category**, even though the in-game Codex omits them,
  because the data and card already exist and cost almost nothing to add.

## Risks / edges

- **Cross-mod references.** A built-in weapon or wing may live in a different mod than
  the ship. The combined index is global, so links resolve by id across all enabled
  mods — but a reference to a disabled/missing mod's item should degrade to plain text,
  not a broken link.
- **Duplicate ids across mods.** If two mods provide the same id, the existing loaders
  already keep only the first one they saw; the combined index inherits that rule, so
  each link lands on exactly one entry. Different categories can reuse the same id,
  though — key history and links by `(type, id)`.
- **Wing → ship resolution** depends on reading `.variant` files. If a variant or hull is
  missing, show the wing without the ship link rather than failing.
