# Ship Viewer: Add Station Filter & Fix "Has Modules" Bug

## Problem

1. **No way to filter out stations** from Ship Viewer results. Users browsing ships have no quick toggle to hide orbital stations, battlestations, etc.

2. **"Has Modules" filter is incorrect.** The Type filter tags any ship with a `STATION_MODULE` weapon slot as "Has Modules", but having the slot doesn't mean a module is actually mapped to it. Some hulls have the slot type but no variant defines modules for them, producing false positives.

## Solution

### 1. New "Station" filter category

Add a filter that categorizes ships as "Station" or "Ship" based on the `hints` field from `ship_data.csv`. Stations have `STATION` in their hints list. This is the same mechanism the game uses.

- Filter name: **"Category"** (or similar)
- Values: `Station`, `Ship`
- Users can exclude stations (set Station to `false`) or show only stations (set Station to `true`)

### 2. Fix "Has Modules" in the Type filter

Replace `ship.hasStationSlots` (which only checks for `STATION_MODULE` slot existence) with actual module resolution. A ship "has modules" only if:
- It has `STATION_MODULE` weapon slots, **AND**
- A variant exists that maps those slots to real module hull IDs

This uses the existing `resolveModules()` function from `ship_module_resolver.dart`, which already does the full resolution (finds a variant, maps slot IDs to module variant IDs, resolves hull IDs).

## Files Changed

- `lib/ship_viewer/ships_page_controller.dart` — Add new filter category; fix "Has Modules" condition in Type filter
- `lib/ship_viewer/models/ship_gpt.dart` — Add `isStation` convenience getter based on `hints`

## Scope

Small, self-contained change. No new dependencies, no data model changes beyond a getter, no UI layout changes.
