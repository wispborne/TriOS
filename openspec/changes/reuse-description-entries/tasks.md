# Tasks

All in `lib/descriptions/descriptions_manager.dart`.

## Step 1 — the entry cache

- [ ] Add `_entriesByRow`, an identity-keyed `HashMap` from raw row map to `DescriptionEntry`, with the comment from the design: identity because the row object is stable for as long as its source is cached, and cheaper than hashing row contents.
- [ ] Change `_composeDescriptions` to look up before building (`??=`). `mergeDescriptions` stays untouched.

## Step 2 — prune the cache in step with the rows

- [ ] Before the smolId `removeWhere` (line 67), remove each dropped source's rows from `_entriesByRow`. **Skipping this leaks: the cache would hold dead row maps alive, growing on every mod change.**
- [ ] Same at the vanilla invalidation (line 63) when the game path changes.

## Step 3 — skip empty yields

- [ ] Count rows added since the last yield; at the 500 ms mark, compose and yield only when the count is nonzero, then reset it.
- [ ] Leave the final yield unconditional — it publishes the finished map.

## Step 4 — verify

- [ ] Cold start with an empty descriptions state: descriptions still appear progressively, not all at once at the end.
- [ ] Heap snapshot mid-startup: `DescriptionEntry` at roughly the unique-key count (~13,000 on the 460-mod install), not a multiple of it.
- [ ] Enable and disable a mod that has a `descriptions.csv`: its descriptions come and go correctly, and a second toggle behaves the same (catches a stale cache entry surviving a prune).
- [ ] Uninstall a mod with descriptions while TriOS is running, trigger a refresh, and confirm `_entriesByRow` does not retain its rows (breakpoint or temporary log).
- [ ] `flutter test`.
- [ ] Add a line to `changelog.md` in the user's voice: with many mods installed, TriOS wastes less work while loading, because mod descriptions that were already loaded are no longer rebuilt every half second during startup.
