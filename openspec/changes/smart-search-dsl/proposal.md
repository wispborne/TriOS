## Why

The viewer pages (weapons, ships, hullmods) have a growing filter panel that accumulates a new chip group for every user request. A structured search DSL lets users filter on any field dimension without adding UI — and since all viewer pages share the same search pattern, a generic reusable widget pays off immediately across all of them.

## What Changes

- New reusable `SmartSearchBar<T>` widget that replaces `ViewerSearchBox` on all viewer pages
- New `SearchField<T>` abstraction — each page registers its own fields (key, description, value suggestions, matcher, capabilities)
- New `SearchDslParser` that tokenizes queries into `FieldToken`s and plain `TextToken`s
- Token pills: parsed `field:value` tokens render as removable chips inside the search bar
- Discord-style autocomplete: dropdown shows matching field names, then valid values for the selected field (drawn from actual loaded data)
- Info icon (`ℹ`) opens a panel listing all registered fields with descriptions and example values
- Negation: prefix a token with `-` to exclude (`-type:missile`)
- Numeric comparators: `field:>value`, `field:<value`, `field:>=value`, `field:<=value` on numeric fields
- Recent search history: last ~10 queries shown in the autocomplete dropdown before typing
- Each page controller replaces its `_filterBySearch` implementation with `ParsedQuery` application
- First rollout: weapons page. Ships and hullmods follow the same pattern.

## Capabilities

### New Capabilities

- `smart-search-bar`: Generic DSL search widget (`SmartSearchBar<T>`) with token pills, autocomplete, info panel, negation, numeric comparators, and recent history. Drop-in for `ViewerSearchBox`.
- `weapon-search-fields`: The set of `SearchField<Weapon>` definitions registered for the weapons page (tracking, ammo, type, size, damage type, range, OP, etc.).

### Modified Capabilities

*(none — this adds a new system; the existing chip filter panel is unchanged)*

## Impact

- **New files**: `lib/widgets/smart_search/smart_search_bar.dart`, `search_dsl_field.dart`, `search_dsl_parser.dart`, `search_query.dart`
- **Modified**: `lib/weapon_viewer/weapons_page.dart` (swap widget), `lib/weapon_viewer/weapons_page_controller.dart` (replace `_filterBySearch`, register fields)
- **Later**: `lib/ship_viewer/ships_page.dart` + controller, `lib/hullmod_viewer/hullmods_page.dart` + controller
- **Removed**: `lib/widgets/viewer_search_box.dart` (once all pages are migrated — or kept as a thin wrapper during transition)
- No new dependencies expected; uses Flutter's built-in overlay/autocomplete primitives
