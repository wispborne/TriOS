## 1. Dialog Widget Core

- [x] 1.1 Create `ModInfoDialog` StatefulWidget in `lib/mod_manager/mod_info_dialog.dart` with `PaletteGeneratorMixin`, accepting `Mod?`, `ScrapedMod?`, `ForumModIndex?`, `VersionCheckComparison?` parameters. Set up `Dialog` wrapper with `ConstrainedBox(maxWidth: 800)` and scrollable body.
- [x] 1.2 Build header section: mod icon (64x64), name, author(s), version, mod type badges, game version requirement. Gracefully handle missing fields.
- [x] 1.3 Build external link buttons row: Forum, NexusMods, Discord, Changelog, Direct Download. Only show buttons for available URLs, sourced from both version checker and catalog data.
- [x] 1.4 Build image gallery: horizontally scrolling `ListView` of catalog images at ~200px height, using `proxyUrl` with `url` fallback and error placeholders. Hide section if no images.
- [x] 1.5 Build description section with `SelectionArea`. Prefer installed mod description over catalog description.
- [x] 1.6 Build status info card: installed state, enabled version, update availability, VRAM estimate, categories, sources. Hide irrelevant fields for catalog-only mods.
- [x] 1.7 Build forum activity info card: views, replies, last post date, created date, board, WIP status. Hide if no forum data.
- [x] 1.8 Build dependencies section with satisfaction indicators (reuse patterns from `ModSummaryPanel`). Hide if no dependencies.
- [x] 1.9 Build dependents section, separated by enabled/disabled. Hide if no dependents.
- [x] 1.10 Build installed versions list with enabled/disabled indicators and "Open Folder" per variant. Hide for catalog-only mods.
- [x] 1.11 Build TriOS metadata section: first seen, last enabled, update mute status. Hide for catalog-only mods.

## 2. Action Bar

- [x] 2.1 Build footer action bar with contextual buttons: Enable/Disable (split button with version picker for multiple variants), Update, Open Folder, VRAM Check, Delete. Disable destructive actions when game is running.
- [x] 2.2 For catalog-only mods, show only link buttons in the action bar (no local actions).

## 3. Integration

- [x] 3.1 Add "View Mod Details..." item to the mod context menu in `mod_context_menu.dart`, placed near the top before "Change to...". Resolve all data sources and open the dialog.
- [x] 3.2 Add entry point from catalog `ScrapedModCard` to open the dialog (e.g., double-click or detail button). Pass catalog data and any matched installed mod data.
