## Why

The mod catalog page fetches two JSON blobs — `mod_repo.json` (Wisp's Mod Repo, 1h TTL) and `forum_data_bundle.json` (QB's Forum Bundle, 24h TTL) — into a shared cache directory, but users have no visibility into or control over this state. Cache timestamps, source URLs, sizes, and refresh/clear actions are currently only exposed for the forum data file, and only from the debug settings section. Users who want to force-refresh the mod repo have no way to do so short of restarting or manually deleting files from disk.

This change adds a forward-looking overflow menu to the catalog page and a single dialog that shows the status of both data files side-by-side with per-file management actions. It also brings `mod_browser_manager.dart`'s public API up to parity with `forum_data_manager.dart` so the dialog can treat both sources uniformly.

## What Changes

- Add an overflow (`more_vert`) menu anchored next to the catalog page's search box, built with the same `PopupStyleMenuAnchor` pattern as the Mods page overflow menu.
- Add a "Data sources…" item to that menu, opening a new **Catalog Data Sources** dialog.
- The dialog shows two cards, stacked vertically:
  - **Wisp's Mod Repo** — subtitle *"mod index + discord"*, backed by `mod_repo.json`
  - **QB's Forum Bundle** — subtitle *"forum stats & posts"*, backed by `forum_data_bundle.json`
- Each card shows: load status, parsed-item count, cached-at timestamp with age + TTL, file size on disk, source URL (with copy button), local cache path, and per-file "Refresh now" / "Clear cache" actions.
- Dialog footer: "Open cache folder" + "Close".
- Destructive buttons (Clear cache) use neutral `onSurface` coloring rather than `colorScheme.error`, which washes out on cards.
- Bring `mod_browser_manager.dart` to parity with `forum_data_manager.dart` by adding `forceRefreshModRepo()`, `clearModRepoCache()`, and `getModRepoCacheTimestamp()`.

## Capabilities

### New Capabilities
- `catalog-data-sources-dialog`: The overflow menu entry, the Catalog Data Sources dialog, and the backend helpers required to inspect, refresh, and clear each data source uniformly.

### Modified Capabilities
None.

## Impact

- **UI**: New overflow button in the filter row of `lib/catalog/mod_browser_page.dart`; new dialog widget file under `lib/catalog/`.
- **Backend**: New public top-level helpers in `lib/catalog/mod_browser_manager.dart` (`forceRefreshModRepo`, `clearModRepoCache`, `getModRepoCacheTimestamp`) mirroring `forum_data_manager.dart`. Existing `_fetchModRepoWithCache` gains a `bypassCache` parameter.
- **Providers**: Dialog invalidates `browseModsNotifierProvider` and `forumDataProvider` after refresh/clear; watches `isLoadingCatalog` / `isLoadingForumData` to disable buttons during in-flight fetches.
- **No new dependencies, no new models, no codegen required.**
