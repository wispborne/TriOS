## Context

Two catalog data files live in `Constants.cacheDirPath`:

| File | Provider | TTL | Managed by |
|------|----------|-----|------------|
| `mod_repo.json` (+ `.meta`) | `browseModsNotifierProvider` | 1 hour | `lib/catalog/mod_browser_manager.dart` |
| `forum_data_bundle.json` (+ `.meta`) | `forumDataProvider` | 24 hours | `lib/catalog/forum_data_manager.dart` |

`forum_data_manager.dart` already exposes `forceRefreshForumData()`, `clearForumDataCache()`, and `getForumDataCacheTimestamp()`. `mod_browser_manager.dart` does not — all of its logic is private, and `_fetchModRepoWithCache` has no `bypassCache` knob. This asymmetry is invisible today because only the debug settings section touches these APIs; surfacing the data in a user-facing dialog makes it glaring.

The catalog page (`lib/catalog/mod_browser_page.dart`) has no AppBar — its filter toolbar is a `Card` containing a row with filter icon buttons and a right-aligned search box (see `mod_browser_page.dart:248`). The overflow button fits naturally at the end of that row.

The Mods page already implements an overflow menu with `PopupStyleMenuAnchor` at `mods_grid_page.dart:1193`, with `MovingTooltipWidget.text` wrapping, `Icons.more_vert`, checkbox items, submenus, and dividers. This is the pattern to copy.

## Goals / Non-Goals

**Goals**
- Give users a single dialog to inspect and manage both catalog data files from one place.
- Bring the mod repo manager's public surface up to parity with the forum data manager's.
- Keep the overflow menu forward-looking — subsequent changes will add more items.
- Match the Mods page's overflow menu pattern for visual consistency.

**Non-Goals**
- Migrating either manager to a new caching layer or abstraction.
- Exposing a raw JSON viewer (that's a separate feature if wanted).
- Changing TTLs, fetch policies, or retry logic.
- Unifying the two managers behind a shared interface. Worth revisiting only if a third data source appears.
- Adding a destructive confirmation dialog for "Clear cache" — the action is fully recoverable (the next read refetches).

## Decisions

### 1. Overflow menu pattern: copy `PopupStyleMenuAnchor` from the Mods page

Rationale: visual consistency and reuse. The Mods page already establishes the idiom at `mods_grid_page.dart:1185` — `MovingTooltipWidget.text` + `PopupStyleMenuAnchor` + `Icons.more_vert` + `MovingTooltipWidget` item tooltips. Reusing this gives us the same menu styling, the same helper functions (`PopupStyleMenuAnchor.checkboxItem`, `.paddedIcon`), and zero new widget work.

### 2. One dialog, two stacked cards — not tabs, not two dialogs

Rationale: both files live in the same cache dir, are fetched by the same page, and share the same shape of metadata. Stacked cards make the symmetry visible at a glance. Tabs would hide one while showing the other; two separate dialogs would duplicate chrome. This is a power-user tool, so vertical scrolling is acceptable if narrow widths force cards to grow.

### 3. Parity API on `mod_browser_manager.dart`

```dart
// New public top-level API, mirroring forum_data_manager.dart:
Future<String> forceRefreshModRepo();      // bypass cache TTL, refetch
void clearModRepoCache();                  // delete mod_repo.json + .meta
DateTime? getModRepoCacheTimestamp();      // read cachedAt from .meta
```

`_fetchModRepoWithCache()` gains an optional `bool bypassCache = false` parameter. `forceRefreshModRepo()` is a one-liner that calls it with `bypassCache: true`. Cache filenames are hoisted into private constants at the top of the file (`_cacheFileName`, `_metaFileName`), matching `forum_data_manager.dart`'s layout.

The dialog triggers UI refresh with `ref.invalidate(browseModsNotifierProvider)` after refresh or clear — the existing `StreamProvider` re-runs from scratch on invalidate, which re-enters `_fetchModRepoWithCache` and picks up the new state.

**Alternative considered**: restructure `browseModsNotifierProvider` into a `Notifier` or a family with a refresh argument. Rejected — two call sites don't justify the churn, and matching `forum_data_manager.dart`'s shape is worth more than clever provider design.

### 4. Destructive button coloring: neutral, not error-red

Per feedback: `colorScheme.error` washes out against card surfaces in the current TriOS theme. The Clear cache button uses `colorScheme.onSurfaceVariant` (or `onSurface`) as its foreground. Tooltip copy conveys destructive intent; no confirmation dialog because the action is recoverable (the file just refetches on next read). The status dots at the top of each card still use the theme error color for error state — those are small, directional indicators, not destructive actions.

### 5. File size display

Read via `File(path).statSync().size` — sync is fine for a single local cache file, and the dialog is opened on demand. Format bytes with the existing TriOS byte-formatting helper if one exists under `lib/utils/`; otherwise inline a small formatter (KB/MB with one decimal). If the file doesn't exist, display "—".

### 6. Disable refresh while loading

Each card binds its Refresh button's `onPressed` to `null` when the corresponding `isLoadingCatalog` / `isLoadingForumData` state is true. Prevents double-submits and communicates in-flight work.

### 7. Card layout sketch

```
┌─ Wisp's Mod Repo ───────────────────────────── ● Loaded ─┐
│  mod index + discord                                      │
│                                                           │
│  1,284 mods • Cached 12m ago (TTL 1h) • 2.3 MB            │
│                                                           │
│  Source: https://.../mod_repo.json              [copy]    │
│  Path:   …/TriOS/cache/mod_repo.json                      │
│                                                           │
│                        [ ↻ Refresh now ]  [ 🗑 Clear ]    │
└───────────────────────────────────────────────────────────┘

┌─ QB's Forum Bundle ───────────────────────── ● Loaded ──┐
│  forum stats & posts                                     │
│                                                          │
│  872 threads • Cached 4h ago (TTL 24h) • 5.1 MB          │
│  ...                                                     │
└──────────────────────────────────────────────────────────┘
```

Status dot: grey (no cache), theme primary (loading), success (loaded), error (failed).

## Risks / Open Questions

- **Refresh spam**: Mitigated by disabling the button while loading. Also worth sanity-checking what happens when the user spams invalidate between frames.
- **Long cache paths on Windows**: Dialog renders the path with `SelectableText` inside a scrollable/ellipsized container so it's always copyable even when truncated.
- **Item count before stream emits**: Show "—" or "Not loaded", not `0`, so users can distinguish "no data yet" from "loaded zero items".
- **What happens if the file exists but provider hasn't re-read it**: File-on-disk and in-memory state can drift briefly. The cached-at timestamp is read from disk (`getXxxCacheTimestamp()`), item count from the provider's current value — documented inconsistency, acceptable.
