### Requirement: Overflow menu on the catalog page

The catalog page SHALL display an overflow button (`Icons.more_vert`) in its filter toolbar, positioned adjacent to the search box. The button SHALL open a menu using the same `PopupStyleMenuAnchor` pattern as the Mod Manager page overflow menu. The menu SHALL be structured to support additional items being added in future changes.

#### Scenario: User opens the overflow menu
- **WHEN** the user clicks the overflow button on the catalog page
- **THEN** a popup menu opens, containing at minimum a "Data sources…" item with a leading storage icon

#### Scenario: Overflow button has a tooltip
- **WHEN** the user hovers the overflow button
- **THEN** a "More options" tooltip is shown

### Requirement: Catalog Data Sources dialog

The system SHALL provide a dialog titled "Catalog Data Sources" that displays two stacked cards:
- "Wisp's Mod Repo" with subtitle "mod index + discord", backed by `mod_repo.json`
- "QB's Forum Bundle" with subtitle "forum stats & posts", backed by `forum_data_bundle.json`

Each card SHALL display: load status with a colored status dot, parsed item count, cached-at timestamp with age and TTL, file size on disk, source URL (with a copy-to-clipboard button), local cache path, a "Refresh now" action, and a "Clear cache" action. The dialog SHALL provide an "Open cache folder" footer action and a "Close" button.

#### Scenario: Dialog opens with both files cached
- **WHEN** both `mod_repo.json` and `forum_data_bundle.json` are present in the cache directory and their providers have emitted
- **THEN** each card shows "Loaded", the parsed item count, the cached-at timestamp with age, the file size, source URL, local path, and enabled refresh/clear buttons

#### Scenario: Dialog opens with no cache
- **WHEN** neither cache file exists
- **THEN** each card shows "Not cached", size "—", the clear button is disabled, and the refresh button is enabled

#### Scenario: User force-refreshes a data source
- **WHEN** the user clicks "Refresh now" on a card
- **THEN** the system calls the corresponding `forceRefreshXxx()` helper (bypassing the cache TTL), invalidates the corresponding provider, and the refresh button is disabled until the in-flight fetch completes

#### Scenario: User clears a cached data source
- **WHEN** the user clicks "Clear cache" on a card
- **THEN** the corresponding `.json` and `.meta` files are deleted from the cache directory, and the provider is invalidated so subsequent reads re-fetch

#### Scenario: Clear cache with missing files does not crash
- **WHEN** the user clicks "Clear cache" on a card whose files are already absent
- **THEN** the operation completes without throwing and the card state reflects "Not cached"

#### Scenario: Destructive buttons use neutral coloring
- **WHEN** the "Clear cache" and "Refresh now" buttons are rendered on a card
- **THEN** their foreground color is drawn from `colorScheme.onSurfaceVariant` (or `onSurface`), NOT from `colorScheme.error`

#### Scenario: Every new icon has a tooltip
- **WHEN** the user hovers any icon-only button in the dialog (copy URL, refresh, clear, open folder)
- **THEN** a tooltip explains the button's purpose

### Requirement: Parity API on `mod_browser_manager`

The system SHALL expose public top-level functions in `lib/catalog/mod_browser_manager.dart` mirroring those in `lib/catalog/forum_data_manager.dart`:

- `Future<String> forceRefreshModRepo()` — bypasses the cache TTL and refetches
- `void clearModRepoCache()` — deletes both `mod_repo.json` and `mod_repo.meta` from the cache directory
- `DateTime? getModRepoCacheTimestamp()` — returns the `cachedAt` timestamp from `mod_repo.meta`, or null if the file is missing or corrupt

Additionally, the private `_fetchModRepoWithCache()` SHALL accept an optional `bool bypassCache = false` parameter, and the manager SHALL fall back to stale cache on fetch failure (matching `forum_data_manager.dart`'s behavior).

#### Scenario: `forceRefreshModRepo` bypasses a fresh cache
- **WHEN** `forceRefreshModRepo()` is called with a cached `mod_repo.json` less than 1 hour old
- **THEN** the system makes a network request and overwrites both cache files regardless of cache age

#### Scenario: `clearModRepoCache` with missing files
- **WHEN** `clearModRepoCache()` is called and neither cache file exists
- **THEN** the call completes without throwing

#### Scenario: `getModRepoCacheTimestamp` with missing meta
- **WHEN** `mod_repo.meta` does not exist or is corrupt
- **THEN** `getModRepoCacheTimestamp()` returns null without throwing

#### Scenario: Fetch failure falls back to stale cache
- **WHEN** a fetch fails (network error) but a cached `mod_repo.json` exists (regardless of age)
- **THEN** the manager returns the stale cached content and logs a warning, rather than rethrowing
