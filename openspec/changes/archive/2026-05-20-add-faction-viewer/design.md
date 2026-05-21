# Faction Viewer -- Design

## Data model

### Faction

`@MappableClass` in `lib/faction_viewer/models/faction.dart`. Implements `WispGridItem`.

Key fields:

```
Faction
  id: String
  displayName: String
  displayNameWithArticle: String?
  displayNameLong: String?
  color: List<int>              // RGBA [0-255]
  baseUIColor: List<int>?
  logo: String?                 // relative path, e.g. "graphics/factions/hegemony.png"
  crest: String?
  showInIntelTab: bool          // defaults to true if absent

  shipNamePrefix: String?
  shipNameSources: Map<String, dynamic>?

  // Doctrine (all 0-5 range)
  doctrine: FactionDoctrine?

  // Blueprint references (raw IDs from faction files)
  knownShipIds: List<String>
  priorityShipIds: List<String>
  knownWeaponIds: List<String>
  priorityWeaponIds: List<String>
  knownFighterIds: List<String>
  priorityFighterIds: List<String>
  knownHullModIds: List<String>

  // Tags from knownShips.tags, knownWeapons.tags, etc.
  knownShipTags: List<String>
  knownWeaponTags: List<String>
  knownFighterTags: List<String>
  knownHullModTags: List<String>

  // Portraits
  malePortraits: List<String>
  femalePortraits: List<String>

  // Economy
  illegalCommodities: List<String>

  // Behavior flags (from "custom" object)
  customFlags: Map<String, dynamic>

  // Music
  music: Map<String, String>?

  // Source tracking
  sources: List<FactionSource>
  sectionAttributions: Map<String, List<SourceContribution>>
  itemAttributions: Map<String, Map<String, String>>  // sectionKey → {itemId → sourceName}
```

### FactionDoctrine

```
FactionDoctrine
  warships: int
  carriers: int
  phaseShips: int
  officerQuality: int
  shipQuality: int
  numShips: int
  shipSize: int
  aggression: int
  combatFreighterProbability: double?
  autofitRandomizeProbability: double?
```

### FactionSource / SourceContribution

```
FactionSource
  name: String          // "Vanilla" or mod display name
  modVariant: ModVariant?

SourceContribution
  source: String        // matches FactionSource.name
  count: int
```

## Data layer

### FactionManager

Extends `CachedStreamListNotifier<Faction, FactionsCachePayload>` following the ship/weapon/hullmod pattern.

**domain**: `"factions"`

**Parse flow**:

1. `parseVanilla()`: Scan `{gameCoreFolder}/data/world/factions/` for `*.faction` files. Parse each with `removeJsonComments()` + `parseJsonToMapAsync()`. Build base `Faction` objects. Each gets a single source: "Vanilla".

2. `parseVariant()`: Scan `{modFolder}/data/world/factions/` for `*.faction` files. For each file:
   - If a Faction with the same ID already exists in `allItemsSoFar`, merge using game rules (see spec).
   - If new ID, create a new Faction with that mod as sole source.
   - Track per-section attribution by snapshotting array lengths before/after merge.

**Merge implementation**: A `mergeFactionJson(base, overlay, sourceName)` function that:
- Iterates overlay keys
- For arrays: appends (handling `core_clearArray`), records count delta, tags each individual item to its source
- For scalars: replaces, records source
- For objects: recurses
- For color/music arrays: replaces entirely

The merge produces both `sectionAttributions` (aggregate counts per source per section) and `itemAttributions` (individual item → source mapping). On `core_clearArray`, item attributions for that key are cleared before tagging new items.

### Provider

```dart
final factionListNotifierProvider =
    StreamNotifierProvider<FactionListNotifier, List<Faction>>(
      FactionListNotifier.new,
    );
```

### Cross-reference resolution

The UI layer resolves blueprint IDs to actual objects on demand via existing providers:

```dart
final ships = ref.watch(shipListNotifierProvider).valueOrNull ?? [];
final factionShips = ships.where((s) => faction.knownShipIds.contains(s.id));
```

This avoids a hard dependency between FactionManager and Ship/Weapon/Hullmod managers. Resolution happens in the profile dialog widget, not the data layer.

**Tag-based resolution**: Faction files reference ships by both explicit hull IDs and tags (e.g. `"base_bp"`, `"heg_bp"`). Ships matched by tag need the ship's `tags` field cross-referenced against the faction's `knownShipTags`. The full set of known ships for a faction is the union of explicit IDs and tag matches.

## UI layer

### Navigation

Add `factions` to `TriOSTools` enum in `lib/trios/navigation.dart`, in `NavGroup.viewers`.

### Page: `lib/faction_viewer/faction_viewer_page.dart`

`ConsumerStatefulWidget` with `AutomaticKeepAliveClientMixin`.

Layout:
```
Column [
  ViewerToolbar (count, search, view mode toggle: gallery/grid)
  Expanded [
    Row [
      Filters sidebar (collapsible)
      Expanded [
        Gallery mode: GridView.builder with FactionCard widgets
        Grid mode: WispGrid with faction columns
      ]
    ]
  ]
]
```

### Controller: `lib/faction_viewer/faction_viewer_controller.dart`

`Notifier<FactionViewerState>` managing:
- Search query
- View mode (gallery / grid)
- Filter state (showHiddenFactions, showModFactions)
- Grid state (for WispGrid persistence)

Split into `FactionViewerState` (ephemeral) and `FactionViewerStatePersisted` (saved to settings).

### Gallery card: `lib/faction_viewer/widgets/faction_card.dart`

Compact card showing:
- Faction logo (small)
- Display name
- Color swatch (thin bar or border tinted with faction color)
- 2-3 key stats (e.g. aggression, fleet size, blueprint count)
- Source badge if from a mod

Click opens profile dialog.

### Profile dialog: `lib/faction_viewer/widgets/faction_profile_dialog.dart`

Full-detail dialog. Sections:

1. **Header**: Logo, crest, name, color swatch, ship prefix.
2. **Doctrine**: Row of visual bars (0-5), using faction color for fill.
3. **Fleet overview**: Blueprint counts per category (ships, weapons, fighters, hullmods) as expandable `ExpansionTile`. When multiple sources contribute to a section, items are grouped by source mod with a subtle `labelSmall` header per group. Groups are ordered by source appearance (Vanilla first, then mods in load order). Single-source sections show a flat list with no header.
4. **Cross-reference links**: Items in expanded lists are tappable, navigating to the relevant viewer page. Implementation TBD -- may use a callback or a shared navigation provider.
5. **Portraits**: `Wrap` of small portrait thumbnails loaded via `Image.file`.
6. **Behavior flags**: `Wrap` of `Chip` widgets for each interesting custom flag.
7. **Source**: Text line listing contributing mods with per-section breakdown available on hover/tap.

### Faction-colored theming

Use `ColorScheme.fromSeed` (or a palette generator package if already in deps) seeded with the faction's `color` field to produce a `ThemeData` scoped to the profile dialog via a `Theme` widget wrapper.

Overflow menu button in the dialog app bar toggles this on/off. Preference persisted in `FactionViewerStatePersisted`.

### Grid columns (for WispGrid mode)

| Column | Type | Sortable |
|---|---|---|
| Logo | image | no |
| Name | string | yes |
| Color | swatch widget | no |
| Warships | int (0-5) | yes |
| Carriers | int (0-5) | yes |
| Phase | int (0-5) | yes |
| Aggression | int (0-5) | yes |
| Ship Quality | int (0-5) | yes |
| Officer Quality | int (0-5) | yes |
| Known Ships | count | yes |
| Known Weapons | count | yes |
| Source | string | yes |

### Filters

Two toggle filters in the sidebar:

1. **Show hidden factions**: Off by default. When off, hides factions where `showInIntelTab == false`.
2. **Show mod factions**: On by default. When off, hides factions whose only source is a mod (no vanilla base).

Both persisted in `FactionViewerStatePersisted`.

## Image loading

Faction logos/crests and portrait images are loaded from disk the same way ship sprites are:

- Resolve path: `{source.modVariant?.modFolder ?? gameCoreFolder}/{relativePath}`
- Use `Image.file()` with error fallback to a placeholder icon.
- For the gallery card, use a small fixed-size logo. For the profile dialog, use a larger version.

## Risks

- **Cross-reference performance**: Resolving all known ship/weapon IDs against the full lists on every profile open could be slow if there are thousands of items. Mitigation: resolve lazily inside `ExpansionTile` (only when expanded), and cache resolved lists in the dialog's widget state.
- **Tag resolution completeness**: Matching ships by tag requires the Ship model to expose its tags. If it doesn't currently, a small addition to the Ship model may be needed.
- **Faction file format variations**: Some mod faction files may have non-standard fields or formatting. The parser should be lenient -- log warnings and skip unrecognized fields rather than failing.
