# Proposal: Finish weapons smart search parameters

## Problem

The weapons page smart search currently supports 11 DSL fields (tracking, ammo, type, size, damage, range, op, dps, hint, tag, mod). The weapon model exposes many more useful fields — combat stats, spread/accuracy, and metadata — that users can't filter on without scrolling through the grid manually.

## Solution

Add all remaining useful weapon fields as smart search parameters, following the same pattern as the existing 11 fields. This covers three categories:

1. **Combat stats** (numeric): damage/shot, emp, energy/shot, energy/second, chargeup, chargedown, burst size, burst delay, turn rate, proj speed, beam speed, launch speed, flight time, proj hitpoints, ammo/sec, reload size, impact, autofire accuracy bonus
2. **Spread/accuracy** (numeric): min spread, max spread, spread/shot, spread decay/sec
3. **Weapon identity** (string): spec class, mount type, tech/manufacturer, primary role, group tag
4. **Metadata** (numeric): tier, rarity, base value

## Scope

- Add ~28 new `SearchField<Weapon>` entries to `_buildSearchFields()` in the weapons page controller
- Numeric fields get `supportsNumeric: true` and comparator support
- String fields get value suggestions from loaded weapons
- Update the existing spec to document the new fields

## Non-goals

- No changes to the smart search infrastructure (parser, widget, matching engine)
- No changes to other viewer pages
- No new UI beyond what the search bar already provides
