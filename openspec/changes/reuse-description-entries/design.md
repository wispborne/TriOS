# Design

## Where things stand

`DescriptionsNotifier.build()` parses each source's `descriptions.csv` into `_cachedRowsByVariant`, a map from source key to that source's raw row maps. The parse loop yields a composed map every 500 ms (line 96) and once at the end (line 106). `_composeDescriptions` (line 122) runs `mergeDescriptions` over every cached source, then builds the result map with a fresh `DescriptionEntry` per merged row.

The raw row maps are the stable thing here. A row map object is created once, when its source's CSV is parsed, and then sits in `_cachedRowsByVariant` unchanged until that source is pruned. `mergeDescriptions` does not copy rows; it hands back references to the same objects. That stability is what the fix keys on.

## The entry cache

```dart
/// Entries already built, keyed on the raw row they came from. A row map stays
/// in [_cachedRowsByVariant] while its mod is installed, so the same object
/// comes back on every compose and its entry is reused instead of rebuilt.
final _entriesByRow = HashMap<Map<String, dynamic>, DescriptionEntry>.identity();
```

Identity, not equality: hashing a whole row map by content on every lookup would cost more than building the entry, and content equality is also the wrong meaning — the question is "is this the same parsed row", not "does this row look the same".

Compose becomes:

```dart
return {
  for (final entry in merged)
    (entry.row['id'] as String, entry.row['type'] as String):
        _entriesByRow[entry.row] ??= DescriptionEntry(
          id: entry.row['id'] as String,
          type: entry.row['type'] as String,
          text1: entry.row['text1'] as String?,
          text2: entry.row['text2'] as String?,
          text3: entry.row['text3'] as String?,
          text4: entry.row['text4'] as String?,
        ),
};
```

Merge behaviour is untouched. If a mod parsed later sorts earlier in load order and takes over a key, the merge hands compose a different winning row, and the different row object misses the cache and builds its own entry. The losing row's entry just stops being referenced by the result map.

## Pruning, which the cache makes necessary

`_cachedRowsByVariant.removeWhere` (line 67) drops sources that are no longer installed, and the vanilla slot is dropped when the game path changes (line 63). If the entry cache is not pruned in step, it keeps referring to the dropped row maps and holds them alive — a leak that grows on every mod change for the rest of the session.

So each prune removes the matching entries first:

```dart
for (final row in _cachedRowsByVariant[key]!) {
  _entriesByRow.remove(row);
}
_cachedRowsByVariant.remove(key);
```

This applies in both places a source is dropped: the smolId prune and the vanilla invalidation. Rebuilding the cache from scratch on prune would be simpler, and would throw away the whole benefit on the first mod change of the session — mid-session mod changes are exactly when the recompose runs again.

## Skipping empty yields

The parse loop knows how many rows each source contributed the moment it parses one. Track it:

```dart
var rowsAddedSinceYield = 0;
// after each source parses:
rowsAddedSinceYield += modResult.rows.length;
// at the 500 ms mark:
if (rowsAddedSinceYield > 0) {
  yield Map.unmodifiable(_composeDescriptions(variants));
  rowsAddedSinceYield = 0;
}
```

The final yield at the end of the loop stays unconditional. It is what publishes the finished map, and the last window may have added rows without hitting a 500 ms boundary.

One subtlety: a source parsing to zero rows is not the same as a source being skipped — a previously-cached source that gets pruned also changes the composed result without adding rows. During the startup loop that cannot happen (pruning runs before the loop), so the row counter is a correct signal there. The prune path does not yield at all today, and this change does not add one.

## Risks

**The cache leaking through missed prunes** is the only real one, and it is handled above. Everything else is a straight swap of construction for lookup on objects whose lifetime already matches.

**`Map.unmodifiable` still copies the result map** on every yield. That copy is ~13,000 map slots, not 13,000 objects, and it is what makes the yielded map safe to hand out. Left alone.

## How to tell it worked

- A heap snapshot taken mid-startup should show `DescriptionEntry` at roughly the unique-key count (~13,000 on the test install), not a multiple of it.
- The descriptions log line should report the same entry count and roughly the same elapsed time as before — this change removes churn, it does not speed up parsing.
- With the Codex page open during startup, the codex index should rebuild noticeably fewer times (it logs nothing today, so watch allocation in DevTools or add a temporary log line while verifying).
- Descriptions must still appear progressively during a cold start with an empty cache — the yields still happen whenever rows actually arrived.
