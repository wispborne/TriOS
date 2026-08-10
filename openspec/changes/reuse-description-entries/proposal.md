# Proposal: Stop rebuilding every description entry every 500 ms during startup

## Problem

While mods parse on launch, `DescriptionsNotifier` yields a progress update every 500 ms so descriptions appear as they load. Each yield calls `_composeDescriptions` (`lib/descriptions/descriptions_manager.dart:122`), which re-merges every parsed source and builds a brand-new `DescriptionEntry` for all ~13,000 merged rows — even the ones that were identical last time, which during a startup is nearly all of them.

A heap snapshot taken mid-startup on a 460-mod install shows the churn directly: 38,968 `DescriptionEntry` objects against 12,979 unique `(id, type)` keys. Three complete copies, two of them garbage waiting for collection.

The rebuilt map is also not the end of the cost. The descriptions provider is one of the seven inputs to `codexIndexProvider`, so every yield makes the codex index rebuild too — 233,000 wrapper objects and three filter passes per rebuild, on the same thread that is still parsing mods:

```
descriptions yield (every 500 ms during startup)
   │
   ├──▶ ~13,000 new DescriptionEntry + a new map
   │
   └──▶ codexIndexProvider rebuilds
            └──▶ 233,000 new codex wrappers, 3 filter passes
```

And some of those yields carry nothing at all: roughly 200 of the 460 installed mods have no `descriptions.csv`, so a 500 ms window that happens to cover only those mods composes and yields a map identical to the previous one.

## Proposed solution

Two changes to `DescriptionsNotifier`, nothing outside it:

1. **Reuse entries instead of rebuilding them.** Cache built `DescriptionEntry` objects keyed on the identity of the raw row they came from. A row map lives in `_cachedRowsByVariant` for as long as its mod is installed, so the same object comes back on every compose; compose becomes a lookup instead of a construction. The merge itself (`mergeDescriptions`) is untouched — it still decides which source wins each key.

2. **Skip yields that carry nothing.** Track whether any rows were added since the last yield; when none were, skip both the compose and the yield, so downstream providers are not poked for an identical map.

## Scope

- `lib/descriptions/descriptions_manager.dart` only.

## Non-goals

- **Making the merge itself incremental.** `mergeDescriptions` still walks all ~25,000 raw rows per compose. Fixing that means merge logic living outside `game_data_merge.dart`, which that file exists to prevent. The walk is cheap relative to what this change removes.
- **The codex index's own rebuild cost.** This change reduces how often it is triggered; making the index itself reuse wrappers is a follow-up with the same shape as this one.
- **Memory.** The extra entry copies are garbage, not held data. The held-memory work is the separate `shrink-parsed-data-memory` change.

## Why there is no spec delta

Descriptions still appear progressively while mods load, still merge by the same rules, and the final map is identical entry for entry. Only wasted rebuilding is removed.
