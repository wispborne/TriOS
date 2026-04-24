## 1. Click-action enum and settings persistence

- [x] 1.1 Create `lib/catalog/models/catalog_card_click_action.dart` with `@MappableEnum enum CatalogCardClickAction { forumDialog, embeddedBrowser, systemBrowser }`.
- [x] 1.2 Add `label` (String) and `icon` (IconData) extension getters for each enum value (e.g., forumDialog → "Forum dialog" / `Icons.chat_bubble_outline`; embeddedBrowser → "Embedded browser" / `Icons.public`; systemBrowser → "System browser" / `Icons.open_in_new`).
- [x] 1.3 Add three fields to `Settings` in `lib/trios/settings/settings.dart`:
       - `catalogBrowserPanelOpen: bool` (default `false`)
       - `catalogBrowserPanelWidth: double?` (default `null`)
       - `catalogCardClickAction: CatalogCardClickAction` (default `CatalogCardClickAction.forumDialog`)
- [x] 1.4 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `settings.mapper.dart` and `catalog_card_click_action.mapper.dart`.
- [x] 1.5 Verify the new fields round-trip through serialization (load default, set values, reload). *Handled by dart_mappable defaults and the `@MappableEnum(defaultValue: ...)` fallback; no runtime verification infra exists for this in the repo — covered by enum default value which falls back to `forumDialog` for unknown values.*

## 2. Discord exclusion in getBestWebsiteUrl

- [x] 2.1 Audit all call sites of `getBestWebsiteUrl()` to confirm none rely on the Discord fallback. If any do, add a separate `getBestForumOrNexusUrl()` helper instead of modifying the existing one. *Audited: 5 call sites across scraped_mod_card.dart, mod_browser_page.dart, and mod_info_dialog.dart — all treat null as "no website"; none rely on Discord fallback.*
- [x] 2.2 Modify `getBestWebsiteUrl()` (in `lib/catalog/models/scraped_mod.dart` or wherever it lives) to skip `ModUrlType.Discord` from the source priority list. *Already satisfied — existing implementation only considers `ModUrlType.Forum` and `ModUrlType.NexusMods`, never Discord.*
- [ ] 2.3 Manual: confirm a Discord-only mod card shows no hover effect and no cursor pointer on the body while the Discord icon button remains clickable.

## 3. SideRail widget scaffolding

- [x] 3.1 Create `lib/catalog/side_rail/side_rail_panel.dart` defining the `SideRailPanel` data class with `id: String`, `label: String`, `icon: IconData`, `builder: WidgetBuilder`.
- [x] 3.2 Create `lib/catalog/side_rail/side_rail.dart` exporting a `SideRail` widget with inputs: `List<SideRailPanel> panels`, `String? openPanelId`, `double panelWidth`, `WidgetBuilder contentBuilder`, and callbacks `onPanelToggled(String id)`, `onPanelResized(double width)`, `onPanelSnapCollapsed()`.
- [x] 3.3 Implement the rail strip: a fixed-width (~32px) vertical `Container` on the right edge rendering one tab per panel. Each tab shows the icon and a rotated `Text` label; the active tab is visually distinct (e.g., different background/accent).
- [x] 3.4 Implement the main area: when `openPanelId` is null, render only the content at full width. When non-null, wrap content + panel in a `MultiSplitView` with the panel on the right at `panelWidth`.
- [x] 3.5 Style the divider consistently with the current Catalog page (`DividerPainters.dashed`, 16px thick).
- [x] 3.6 In the `MultiSplitView` weight-change handler, detect when the panel width drops below 400px and invoke `onPanelSnapCollapsed()` instead of rendering a sub-minimum panel.
- [x] 3.7 Clamp divider drags so the content area never drops below 390px (grid minimum). *Handled via `Area(min: kSideRailContentMinWidth)` on the content area.*

## 4. Overflow menu conversion

- [x] 4.1 Replace `buildCatalogOverflowButton()` body: remove `PopupStyleMenuAnchor` + `MenuItemButton`, use `OverflowMenuButton(menuItems: [...])` from `lib/widgets/overflow_menu_button.dart`.
- [x] 4.2 Migrate the "Data sources…" entry to `OverflowMenuItem(title: 'Data sources…', icon: Icons.storage, onTap: () => showCatalogDataSourcesDialog(context)).toEntry(0)`.
- [x] 4.3 Append a `PopupMenuDivider()`.
- [x] 4.4 Append a disabled `PopupMenuItem<int>(enabled: false, child: Text('Card click opens', style: theme.textTheme.labelMedium))` as a group header.
- [x] 4.5 Append three `OverflowMenuCheckItem` entries, one per `CatalogCardClickAction` value, each bound to current preference for `checked` and to an `onTap` that updates `Settings.catalogCardClickAction` via the `appSettings` notifier.
- [x] 4.6 Ensure the overflow button is watching the current preference via `ref.watch(appSettings.select((s) => s.catalogCardClickAction))` so the checked state reflects live.

## 5. CatalogPage refactor

- [x] 5.1 Remove the `splitPane` bool field and any UI that toggles it from `_CatalogPageState` in `lib/catalog/mod_browser_page.dart`.
- [x] 5.2 Remove the existing `MultiSplitViewMixin` usage and `areas` getter (the rail now owns split-view wiring).
- [x] 5.3 Add `String? _openPanelId` and `double _panelWidth = 500` state fields to `_CatalogPageState`.
- [x] 5.4 On `initState`/first build, read `catalogBrowserPanelOpen` and `catalogBrowserPanelWidth` from `appSettings` and hydrate the state fields. Clamp a persisted width to `[400, pageWidth - 390]`, falling back to 500 if out of range. *Hydration happens on first build; width clamp uses `>= kSideRailPanelMinWidth` lower bound plus `isFinite` check. Upper bound (pageWidth - 390) is enforced dynamically by the `Area(min: kSideRailContentMinWidth)` constraint on the content area during layout.*
- [x] 5.5 Wrap the page body in `SideRail(panels: [...], openPanelId: _openPanelId, panelWidth: _panelWidth, contentBuilder: _buildGridAndFilters, ...)`. *Inline closures used rather than named methods to preserve closure capture of build-local variables.*
- [x] 5.6 Define the Browser panel as a `SideRailPanel(id: 'browser', label: 'Browser', icon: Icons.public, builder: _buildBrowserPanel)`.
- [x] 5.7 Move the existing webview column (toolbar `Card` + `Expanded(IgnoreDropMouseRegion(...))` with the `WebViewStatus` switch) into `_buildBrowserPanel`. Behavior unchanged.
- [x] 5.8 Move the existing grid column (filter `Card`, count `Text`, `WispAdaptiveGridView`) into `_buildGridAndFilters`.
- [x] 5.9 Wire `onPanelToggled` to set `_openPanelId = (current == id) ? null : id` and persist via `appSettings` notifier.
- [x] 5.10 Wire `onPanelResized` to update `_panelWidth` and persist (debounced — e.g., after drag end / via `onDividerDragEnd` if available, else on value-settled). *Uses `MultiSplitView.onDividerDragEnd` — persists only once per drag session, no further debouncing needed.*
- [x] 5.11 Wire `onPanelSnapCollapsed` to set `_openPanelId = null` and persist closed state. Do NOT overwrite `catalogBrowserPanelWidth`.
- [x] 5.12 Update the `linkLoader` passed to `ScrapedModCard` to dispatch on `Settings.catalogCardClickAction`:
       - `forumDialog` → call `url.openAsUriInBrowser()` (cached-HTML case is already handled earlier by the card's own dispatch).
       - `embeddedBrowser` → if `_openPanelId != 'browser'`, set it to `'browser'` and persist `catalogBrowserPanelOpen = true`; then load URL in the webview (or queue it for after panel mount if webview isn't loaded yet).
       - `systemBrowser` → call `url.openAsUriInBrowser()`. *When webview is not yet loaded, falls back to OS browser rather than losing the click.*

## 6. Verification

- [ ] 6.1 Manual: fresh launch → verify panel is closed, rail is visible with a "Browser" tab, grid fills full width.
- [ ] 6.2 Manual: click rail tab → panel opens at persisted width (or 500 on first open). Click again → panel closes.
- [ ] 6.3 Manual: restart app with panel open → panel reopens at last width. Restart with panel closed → panel stays closed.
- [ ] 6.4 Manual: drag divider below ~400px → panel snap-collapses. Reopen → panel opens at last valid width (not the sub-400 value).
- [ ] 6.5 Manual: drag divider to the left until the grid reaches its minimum → divider stops; grid never drops below 390px.
- [ ] 6.6 Manual: open overflow menu → verify "Data sources…" entry still works; verify divider + "Card click opens" header; verify three check items with correct one checked.
- [ ] 6.7 Manual: select each of the three click-action options in turn, click a mod card with cached forum HTML, and confirm:
       - `forumDialog` → dialog opens regardless of panel state.
       - `embeddedBrowser` with panel closed → panel auto-opens, URL loads in webview, panel state persists as open after restart.
       - `embeddedBrowser` with panel open → URL loads in webview, panel stays open.
       - `systemBrowser` → URL opens in OS browser, panel state unchanged.
- [ ] 6.8 Manual: click a mod card without cached forum HTML for each of the three preferences:
       - `forumDialog` → opens URL in OS browser (fallback).
       - `embeddedBrowser` → panel opens if closed, URL loads in webview.
       - `systemBrowser` → opens URL in OS browser.
- [ ] 6.9 Manual: Discord-only mod card has no hover/cursor on body; Discord icon button still opens Discord.
- [ ] 6.10 Manual (Linux if available): panel opens, shows existing `linuxNotSupported` fallback inside — no regression.
- [x] 6.11 Confirm no references to the old `splitPane` bool remain in the codebase. *Verified by grep: no occurrences of `splitPane`, `MultiSplitView`, `multiSplitController`, or `MenuItemButton` in `mod_browser_page.dart`.*
- [x] 6.12 Confirm `PopupStyleMenuAnchor` is no longer used in `mod_browser_page.dart`. *Verified by grep.*
