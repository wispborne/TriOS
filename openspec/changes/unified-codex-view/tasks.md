# Tasks — Unified Codex view

Each task ends with a *Done when* check. Sections are ordered so that everything a
task needs already exists by the time you reach it.

## Data: ship systems (light)

- [x] Turn on the commented-out fields in `lib/ship_systems_manager/ship_system.dart`.
      Their `@MappableField` CSV keys are already written and match the real header
      (`flux/use`, `max uses`, `cooldown`, `toggle` and the other TRUE/FALSE flag
      columns, `tags`, `icon`) — except `regen flat`, which is not in the vanilla CSV;
      keep that field nullable or drop it.
      *Done when:* the model compiles with the fields un-commented and no field maps
      to a column missing from the vanilla CSV header.
- [x] Update the ship-systems manager to read those fields from
      `data/shipsystems/ship_systems.csv`, and stamp each `ShipSystem` with the mod it
      came from (the model has no mod field today; the Codex mod filter needs one).
      *Done when:* loading vanilla + one mod yields systems whose new fields are
      non-null where the CSV has values, and each system's mod field is null for
      vanilla and set for the mod's systems.
- [x] Run build_runner to regenerate `ship_system.mapper.dart`.
      *Done when:* build_runner exits clean and `flutter analyze` passes.
- [x] Add `ShipSystemCodexCard` (name, key stats, and description via
      `descriptionProvider((system.id, DescriptionEntry.typeShipSystem))` — the same
      lookup `ShipCodexCard` already uses).
      *Done when:* the card renders a vanilla system (e.g. Burn Drive) with name,
      stats, and description text, and renders a system with no description entry
      without errors.

## Data: fighters / wings (new)

- [x] Add `lib/fighter_viewer/models/wing.dart` (`@MappableClass`) mapping the
      `data/hulls/wing_data.csv` columns. Map `num` (craft count), not the separate
      `number` column (a plain row counter at the far end of the header, after a run of
      blank columns); skip `attackRunRange` / `attackPositionOffset`. Give the model a
      `late ModVariant? modVariant` field like `Weapon` has (null = vanilla), so the
      mod filter works.
      *Done when:* parsing the vanilla CSV produces one `Wing` per data row with
      `num` equal to the craft count column.
- [x] Add a wings cache payload type (mirror `WeaponsCachePayload` in
      `lib/weapon_viewer/models/weapons_cache_payload.dart`).
      *Done when:* it round-trips through its mapper (encode → decode → equal).
- [x] Add `WingListNotifier` extending `CachedStreamListNotifier`, declaring
      `String get domain => 'wings';` (the domain is just a cache folder name — no
      registry to update), reading each folder's `data/hulls/wing_data.csv`. This is
      one CSV per mod folder — simpler than the weapon loader (which also reads `.wpn`
      files). For the `.variant` read below, follow `ShipListNotifier`'s variant
      parsing in `lib/ship_viewer/ship_manager.dart`.
      *Done when:* the provider emits vanilla wings plus wings from enabled mods,
      each stamped with its `modVariant`, and a second launch loads them from cache.
- [x] Resolve a wing's `variant` column to its `.variant` file (vanilla fighter variants
      live in `data/variants/fighters/`) and read the `hullId` so the wing can link to
      its ship. Degrade gracefully if the variant/hull is missing.
      *Done when:* a vanilla wing (e.g. `broadsword_wing`) resolves to its hull id,
      and a wing whose variant file is absent still loads with a null hull id.
- [x] Run build_runner for the new mapper files.
      *Done when:* build_runner exits clean and `flutter analyze` passes.
- [x] Add `WingCodexCard` (role, points, tier/rarity, number of craft, link to the
      ship). There is no wing entry type in `descriptions.csv`, so the card has no
      long description — use the `role desc` column and the ship link.
      *Done when:* the card renders a vanilla wing, and the ship link is present when
      the hull resolved and absent (plain text) when it didn't.

## Shared codex model

- [x] Add `lib/codex/models/codex_entry.dart`: sealed `CodexEntry` with `id`, `type`,
      `displayName`, `sortName` (ships sort by hull name), `subtitle` (exact
      per-category expressions are in the design's subtitle table), and
      `Set<String> modIds`. One subclass per category wrapping the existing data
      object. `modIds` is a set because factions can come from several mods
      (`faction.sources`); the others map their single source
      (`ship.modId`, `weapon.modVariant?.modInfo.id`, etc.). Keep the model
      Flutter-free — icons are keyed off `type` in the page.
      *Done when:* one `List<CodexEntry>` can hold all six subclasses; no Flutter
      imports in the file.
- [x] Add `CodexEntryType` enum (ship, weapon, hullmod, shipSystem, wing, faction).
      *Done when:* it exists and `CodexEntry.type` returns it.

## Spoiler levels (shared functions)

- [x] Lift the hullmod spoiler check out of `HullmodsPageController` (it's a private
      method today) into a top-level function like `shipMatchesSpoilerLevel` and
      `weaponMatchesSpoilerLevel`. Move only; no behavior change on the hullmods page.
      *Done when:* the hullmods page filters exactly as before and the function is
      importable from outside the controller.

## Combined index

- [x] Add a provider that watches all six sources — the four `CachedStreamListNotifier`
      loaders, the ship-systems `StreamProvider`, and the wings loader — and flattens
      them into `List<CodexEntry>`. Duplicate ids within a category are already handled
      (each loader keeps the first one it saw); different categories can reuse the same
      id, so every key is `(type, id)`. Read ship systems as its own
      `List<ShipSystem>`; it does not share the cached loaders' payload interface.
      *Done when:* with vanilla + one mod enabled, the list contains entries of all
      six types and rebuilds when a mod is toggled.
- [x] Apply the standing filters at the index: spoiler level (per-category rules are
      the table in design section 6b), the mod filter, and the "show hidden" toggle.
      Everything downstream (list, search, counts, related panel, random) reads the
      filtered view.
      *Done when:* setting "no spoilers" removes `codex_unlockable`-tagged ships from
      the filtered view; filtering to one mod removes all entries whose `modIds`
      don't match.
- [x] Listed vs. linkable: fighter hulls are in the index but never listed in Ships
      (not in search or random either — reachable only via their wing); hidden
      weapons (system/decorative) are unlisted unless the "show hidden" toggle is on,
      but stay in the index as link targets, so a ship's built-in hidden weapon still
      shows in its related panel. D-hulls/skins: list whatever the ships page lists.
      Ship systems without a description are included; their type buckets as
      "Special".
      *Done when:* a fighter hull never appears in the Ships list or search but its
      detail opens from its wing's link; a hidden weapon appears in the list only
      with the toggle on, yet always resolves as a link target.

## Related-entries linking pass

- [x] Add a derived provider computing `Map<(CodexEntryType, String),
      List<(CodexEntryType, String)>>` from the combined index. Rules, each added in
      both directions: ship ↔ system (`systemId`); ship ↔ built-in hullmods
      (`builtInMods`); ship ↔ built-in weapons (`builtInWeapons.values`); ship ↔
      built-in wings (`builtInWings`); wing ↔ its ship (resolved hull id); ships
      sharing a `baseHullId` (skins) link to each other and the base. Factions get no
      links in v1.
      *Done when:* for a vanilla ship with a built-in weapon (e.g. the Onslaught's
      TPCs), the ship's links contain the weapon **and** the weapon's links contain
      the ship.
- [x] Sort each entry's links by category in the game's order (ship systems →
      hullmods → weapons → fighters → ships → factions), alphabetical within each.
      Links resolve to entries at display time; a key that resolves to nothing
      (disabled mod, filtered out) is silently dropped.
      *Done when:* a ship's related list shows its system before its hullmods before
      its weapons, and disabling a linked mod removes those rows without errors.

## Search

- [x] Search scoped to the current category (top level = everything):
      case-insensitive substring over `displayName` + `id`, with starts-with matches
      ranked above plain substring matches, alphabetical within each rank.
      *Done when:* searching "ham" in Weapons lists Hammer Barrage before a weapon
      merely containing "ham"; searching from the root returns mixed types.
- [x] Results replace the left list as a synthetic "Search results" view; rows show
      their category as a type hint since results mix types. Clearing the box, the up
      button, or Escape cancels the search and restores the category. Do not reuse the
      per-type `SearchField` DSL lists (each is typed to its own item).
      *Done when:* all three cancel routes restore the exact pre-search list.

## The Codex tab — game layout

- [x] Add `lib/codex/codex_page.dart` — `ConsumerStatefulWidget` with
      `AutomaticKeepAliveClientMixin` — and
      `lib/codex/codex_page_controller.dart` with `CodexPageState` /
      `CodexSnapshot` exactly as sketched in design section 5b. Layout: toolbar (nav
      buttons + search box), left drill-down list (fixed width ~288 dip), detail
      panel (flexes), related-entries panel (fixed width ~288 dip), tag filter bar
      along the bottom. Fixed side widths like the game — no `SideRail` (right-side
      only), no `ViewerSplitPane` (top/bottom only), no split-view package.
      *Done when:* the page builds with all five regions present and resizing the
      window only flexes the detail panel.
- [x] Left list: top level shows the six category rows (icon + name, like the game's
      root); inside a category, a pinned "go up" row then the entries, alphabetical
      by `sortName`, filtered by the facets and standing filters. Selecting a
      category drills in; selecting an entry shows its detail. Build rows lazily
      (`ListView.builder`) — a modded Ships category can exceed a thousand rows.
      *Done when:* drilling into Ships and scrolling stays smooth with 1000+ entries
      (no eager building of all rows), and "go up" returns to the root.
- [x] Category quick-switch: the list's title shows the current category and is a
      dropdown (`TriOSDropdownMenu`) of all six, so the user can jump categories
      without going up first.
      *Done when:* picking a category from the dropdown behaves exactly like
      navigating there via the root (facets reset, snapshot taken).
- [x] Shared list-row widget: image cell + name + grey subtitle, hover state via the
      existing `HoverableWidget`/`HoverableRow` helpers. Images reuse the viewer
      pages' widgets with their hover effects intact: ships (and wings with a
      resolved hull) use `ShipBlueprintView.minimal` with the engine glow wired to
      row hover, same as `ships_page.dart`; weapons use `WeaponImageCell` with its
      `rowHovered` flag; hullmods and ship systems show their icon files; factions
      show their crest. The related panel reuses this row widget with a type hint.
      *Done when:* hovering a ship row fades in its engine glow, and the same row
      widget renders correctly for all six types.
- [x] Lift `WeaponImageCell` out of `lib/weapon_viewer/weapons_page.dart` (~line 1112)
      into `lib/weapon_viewer/widgets/` so the Codex can import it without pulling in
      the page. Move only; no behavior change on the weapons page.
      *Done when:* the weapons page renders identically and imports the new file.
- [x] Detail panel: `switch (entry.type)` → render the matching existing card
      (ship / weapon / hullmod / faction) or the new ship-system / wing card, in a
      scroller.
      *Done when:* selecting one entry of each type shows the right card without
      layout overflow errors.
- [x] Related panel: the linked entries for the shown entry as clickable rows (same
      row widget as the list, with type hints). Keeps its width with a quiet empty
      state when there are no links, so the detail panel doesn't shift.
      *Done when:* navigating between an entry with links and one without does not
      change the detail panel's width.

## Tag filter groups

- [x] Per-category `FilterScopeController`s (scope `FilterScope('codex', <category
      name>)`) holding `ChipFilterGroup` definitions per the exact value table in
      design section 6 — copy the ships page's `hullSize` and `techManufacturer`
      groups (including the `_techManufacturerLabel` case-folding approach) rather
      than re-deriving them. Facet selections reset on category change; only a
      history restore brings them back.
      *Done when:* excluding "Frigate" in Ships hides frigates; switching category
      and back shows the facets reset.
- [x] Per-chip count badges: add an opt-in flag (default off) to the chip renderer
      so existing pages are untouched. A chip's count is how many entries in the
      spoiler- and mod-filtered category contents have that value; counts don't
      change as chips are toggled.
      *Done when:* Codex chips show counts, the viewer pages' filter panels are
      pixel-identical to before, and toggling a chip doesn't change other counts.
- [x] Standing controls in the bottom bar next to the facets: the spoiler level
      (three-level `EnumField`, per-category rules from design 6b), the mod filter,
      and the "show hidden" toggle — all applied at the index (see Combined index),
      shared across categories, never reset by category change or history.
      *Done when:* changing any of the three updates the list, search, related
      panel, and random alike, in every category.
- [x] Filter persistence via the existing `FilterGroupPersistence` lock toggle, same
      as the viewer pages.
      *Done when:* a locked group's state survives an app restart; unlocked state
      doesn't.

## Navigation and history

- [x] Toolbar buttons: back (Q, Left), forward (W, Right), up (E, Up — also cancels a
      search), random (R — uniform pick from the listed, filtered index, excluding
      the current entry). Ctrl-F focuses the search box; Escape cancels search, else
      goes up. Each button gets a `MovingTooltipWidget.text` naming its shortcut.
      *Done when:* every key does what its tooltip says, and back/forward buttons
      disable at the ends of the history stack.
- [x] Shortcuts fire only when the Codex page is visible and the search box is not
      focused (Ctrl-F/Escape work regardless). Use a `Focus`/`Shortcuts` wrapper on
      the page, not a global handler.
      *Done when:* typing "war" in the search box does not trigger forward/random,
      and Q/W/E/R do nothing while another tab is shown.
- [x] Landing in another category (related click, card cross-reference, mixed-type
      search result, random): switch the left list to the target's category and
      select the row, highlighted with `Highlightable` (glow + auto-scroll) — the
      game's behavior.
      *Done when:* clicking a ship's built-in weapon in the related panel switches
      the list to Weapons with that weapon's row highlighted and scrolled into view.
- [x] History: the snapshot stack from design 5b (capped at 100), recording category,
      selected entry, search text, and facet selections
      (`FilterGroup.serialize()`/`restore()`). Standing settings (spoiler, mod
      filter, show hidden) and scroll positions are excluded — decided. Snapshot on
      every selection; navigating after going back drops the forward stack.
      *Done when:* browse ship → weapon → search → result, then Back three times
      lands on the original ship with its category, list, and facets restored.

## Clickable cross-references in the cards

> ⚠️ **Not a task for a small/local model.** This edits ~700 lines of private card
> internals with three `.tooltip()` call sites that must not regress. Do this one
> with a strong model or by hand.

- [x] Add an optional `onEntitySelected` callback to `ShipCodexCard`, `WeaponCodexCard`,
      `HullmodCodexCard`, and the wing/ship-system cards. Thread it through the private
      helpers that currently build the references (e.g. `_armamentWrap` in
      `ShipCodexCard`, which wraps built-in weapons in `WeaponCodexCard.tooltip`).
      All three cards have `.tooltip()` factories with existing call sites that must
      keep their current hover behaviour (callback stays null there):
      `WeaponCodexCard.tooltip` in `faction_profile_dialog.dart`, `weapons_page.dart`,
      `ship_codex_card.dart`; `HullmodCodexCard.tooltip` in
      `faction_profile_dialog.dart`, `hullmods_page.dart`; `ShipCodexCard.tooltip` in
      `faction_profile_dialog.dart`, `ships_page.dart`. Default null = current hover
      behaviour, existing tabs unchanged.
      *Done when:* with the callback null, every existing tab's hover tooltips are
      unchanged; with it set, hovering still shows the tooltip and clicking fires
      the callback with the right `(type, id)`.
- [x] In the Codex detail panel, wire references (system, built-in weapons, wings, hull
      mods) to call the callback and select that entry, taking a history snapshot.
      References to missing/disabled-mod items fall back to plain text, not broken
      links.
      *Done when:* clicking a built-in weapon inside the ship card navigates to it
      (with highlight + snapshot), and a reference to a disabled mod's weapon renders
      as plain text.

## Register the tab

- [x] Add `codex` to the `TriOSTools` enum in `lib/trios/navigation.dart`.
- [x] Add it to `defaultNavOrder` and `reorderableTools`.
- [x] Add its `label`, `tooltip`, `icon`, and `group` cases (group is
      `NavGroup.viewers`, an enum value).
- [x] Regenerate `navigation.mapper.dart` with build_runner.
- [x] In `lib/app_shell.dart`: add the next integer key to `tabToolMap` and add
      `CodexPage` at the matching position in the `tabChildren` list — the two must
      stay in the same order (`toolToIndexMap` is derived automatically).
      *Done when (whole section):* the Codex tab appears in the sidebar, opens the
      page, survives tab reordering, and `flutter analyze` passes.

## Wrap-up

- [x] Add tooltips to every new icon (tab icon, nav buttons) — project rule.
      *Done when:* every new icon shows a `MovingTooltipWidget.text` on hover.
      (Nav buttons use `MovingTooltipWidget.text`; the tab icon shows the
      `TriOSTools.codex` tooltip; root-list and control icons carry text labels.)
- [ ] Look-and-feel pass: game structure, TriOS skin — app theme fonts/text
      styles/colors only (no game fonts), spacing on the 8 dip grid, `spacing` params
      over `SizedBox`s. The page should not look foreign next to the existing viewers.
      *Done when:* a side-by-side with the ships page shows consistent fonts,
      spacing, and selection styling.
- [~] `flutter analyze` and `dart run custom_lint` clean. (`flutter analyze` is
      clean — 0 errors project-wide. `custom_lint` is not a dependency in this
      project's pubspec, so the CLI can't run here.)
- [x] Draft the user-facing text — tab name, category names, "go up" row, search hint,
      button tooltips, "Search results" title, related-panel empty state — and confirm
      wording before finalizing.
      *Done when:* the user has signed off on the visible strings. (Approved.)
