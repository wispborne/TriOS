# Proposal: Ships Smart Search

## Problem
The ships page uses a simple substring search (`ViewerSearchBox`), while the weapons page already has a full DSL-powered `SmartSearchBar` with field-specific filtering, numeric comparators, negation, and autocomplete suggestions. Users can't do targeted queries like "show me all capital ships with speed > 60" or "exclude phase ships."

## Proposed Solution
Replace `ViewerSearchBox` on the ships page with `SmartSearchBar`, wiring up typed `SearchField<Ship>` definitions in the ships page controller. Follow the same pattern the weapons page uses: define fields, parse DSL tokens, match against ship properties.

## Scope
- Define `SearchField<Ship>` entries for ship properties (hull size, shield type, hitpoints, speed, OP, etc.)
- Replace `ViewerSearchBox` with `SmartSearchBar` in `ships_page.dart`
- Add `shipsSearchHistory` to settings for persistence
- Wire up DSL-aware filtering in the controller (replacing the current substring filter)

## Non-goals
- Changing the SmartSearchBar widget itself
- Adding new search DSL syntax or operators
- Modifying the weapons page search fields
- Creating a formal spec (weapons spec serves as the established pattern)
