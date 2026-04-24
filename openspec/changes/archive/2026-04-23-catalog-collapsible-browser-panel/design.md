## Context

The Catalog page (`lib/catalog/mod_browser_page.dart`) uses the `multi_split_view` package with a `MultiSplitViewMixin` to render a horizontal split: left = scraped-mod grid + filter bar, right = embedded `InAppWebView` with a small toolbar. The split is controlled by a `splitPane` bool; when true, both panes are always shown; when false, only the grid. There is no way to peek/close the browser on demand while keeping it discoverable.

The card click dispatch already exists in `ScrapedModCard`: it prefers `forum_post_dialog` when cached HTML is present, falls back to a `linkLoader` callback for URL-based navigation, and is gated on `hasClickableLink` (which is false when there's no URL, no cached HTML, and no direct download). `getBestWebsiteUrl()` currently can return a Discord URL as a last resort, causing Discord-only mods to be clickable in ways that produce poor UX.

The Catalog page's overflow button (`buildCatalogOverflowButton`) is a bespoke `PopupStyleMenuAnchor` + `MenuItemButton` implementation, diverging from the shared `OverflowMenuButton` widget used by the other viewer pages.

This change reshapes the layout (rail), introduces an explicit user preference for card click action (replacing implicit panel-state routing), tightens the Discord edge case at the source, and aligns the overflow button with the rest of the app.

## Goals / Non-Goals

**Goals:**
- Default the Catalog page to a full-width grid so users who never use the embedded browser get maximum grid density.
- Keep the embedded browser one click away via an always-visible rail tab.
- Persist panel open/closed state, panel width, and card-click-action preference per user.
- Give the user explicit, predictable control over card-click behavior via a three-option preference in the overflow menu.
- Eliminate the Discord-only-mod click trap by excluding Discord URLs from the best-URL picker at the source.
- Align the Catalog overflow button with the shared `OverflowMenuButton` pattern used elsewhere.
- Provide a `SideRailPanel` API so future panels can slot in without refactoring.

**Non-Goals:**
- Making `SideRail` a general-purpose, app-wide widget. It lives under `lib/catalog/side_rail/` and is page-scoped.
- Supporting multiple panels open simultaneously (stacked tool windows). v1 is VSCode-sidebar-style: one panel at a time.
- Keyboard shortcuts / accessibility instrumentation.
- Adding `forum_post_dialog` as a rail panel. The API supports it; this change does not do it.
- Cross-platform rework: Linux already shows a fallback "webview not supported" message; that behavior is preserved inside the panel.
- Removing the Discord URL from the mod's data model. Only the *best-website* picker changes — the Discord icon button on the card still uses the raw Discord URL.

## Decisions

### Decision 1: Reuse `multi_split_view` under the hood

**Choice:** The `SideRail` widget internally uses `MultiSplitView`, dynamically rebuilding its `areas` list based on which panel (if any) is open. The rail strip itself is rendered outside the `MultiSplitView` as a fixed-width sibling (e.g., a `Row` of `[Expanded(MultiSplitView(...)), SideRailStrip(...)]`).

**Alternatives considered:**
- Roll a custom resize handle: rejected. `multi_split_view` already handles hit-testing, keyboard focus, and divider theming, and the existing `MultiSplitViewMixin` provides the controller plumbing.
- Put the rail inside `MultiSplitView` as a third fixed-size area: rejected. The package supports fixed sizes but the rail needs tab-interaction semantics that sit awkwardly as an `Area` builder.

### Decision 2: Panel state lives in `_CatalogPageState`, persisted via `appSettings`

**Choice:** Two ephemeral fields on `_CatalogPageState` (`String? openPanelId`, `double panelWidth`) drive rendering. A listener on `appSettings` hydrates them on first build; changes are persisted via the existing `appSettings` notifier (debounced on drag end for the width).

**Alternatives considered:**
- A dedicated `catalogBrowserPanelController` Riverpod `Notifier`: rejected as overkill for a few scalar fields that only one page reads.

### Decision 3: `SideRailPanel` data class (not a widget subclass)

**Choice:**
```dart
class SideRailPanel {
  final String id;          // 'browser', future: 'forum-post'
  final String label;       // 'Browser'
  final IconData icon;      // Icons.public or similar
  final WidgetBuilder builder;
  const SideRailPanel({...});
}
```
`SideRail` takes `List<SideRailPanel>` + `String? openPanelId` + callbacks. The page owns open/closed state; the rail is a controlled component.

**Alternatives considered:**
- `List<Widget>` children: rejected. Loses the tab label/icon metadata.
- Sealed class hierarchy with abstract `build`: rejected. Ceremony without payoff.

### Decision 4: Three scalar settings fields, not a nested object

**Choice:** Add three fields directly to `Settings`:
```dart
final bool catalogBrowserPanelOpen;              // default: false
final double? catalogBrowserPanelWidth;          // default: null → 500 fallback
final CatalogCardClickAction catalogCardClickAction; // default: forumDialog
```
No nested `CatalogPageUiState` object. Keeps settings flat and matches existing patterns (`hasHiddenForumDarkModeTip`).

**Alternatives considered:**
- Nested object: rejected. Premature grouping.
- Storing `openPanelId: String?` instead of a bool: rejected for v1 (only one panel exists). When a second panel lands, migrate to string in that later change.

### Decision 5: Snap-collapse threshold at 400px; grid minimum at 390px

**Choice:** When the user drags the divider such that the panel would fall below 400px, invoke `onPanelSnapCollapsed` and set the panel to closed. Do NOT overwrite the persisted width with the sub-minimum value — next open restores to the last valid width or 500. The grid side is clamped at 390px (one `WispAdaptiveGridView` column minimum).

**Alternatives considered:**
- Hard minimum at 400px (clamp, no close): rejected. VSCode's snap-close pattern matches user intent ("I'm trying to get rid of this") better.
- Different pixel values: 400 balances "forum still usable" vs. "grid not starved." Tunable via constants.

### Decision 6: Card click preference replaces panel-state routing

**Choice:** `CatalogCardClickAction` enum with three values — `forumDialog`, `embeddedBrowser`, `systemBrowser`. `linkLoader` dispatches on the preference:

| Preference        | When `linkLoader` is called                                                            |
| ----------------- | -------------------------------------------------------------------------------------- |
| `forumDialog`     | Fall back to system browser (cached-HTML case is already handled by the card).         |
| `embeddedBrowser` | Load URL in webview. If panel is closed, auto-open it and persist `panelOpen = true`.  |
| `systemBrowser`   | Open URL via `openAsUriInBrowser()`. Panel state untouched.                            |

The card's existing priority dispatch is preserved: `hasForumDetails` → `showForumPostDialog` → else `linkLoader(url)`. This means `forumDialog` preference + cached HTML ⇒ dialog (via the card's existing path); `forumDialog` preference + no cached HTML ⇒ system browser (via `linkLoader` dispatch).

**Alternatives considered:**
- Panel-state-based routing (our earlier design): rejected. Couples two concerns — panel visibility and click target — that users may want to control independently. "I have the panel open because I'm browsing the Mod Index, but I still want clicks to open the dialog" is a legitimate workflow.
- Smart/automatic default without an explicit setting: rejected. Too much magic; users had no way to predict or change behavior.
- Per-card action picker (right-click): rejected. Card context menu already exists for other actions; adding three click-target options there is friction for a setting users set once.

### Decision 7: Exclude Discord from `getBestWebsiteUrl()` rather than route Discord URLs specially

**Choice:** Modify `getBestWebsiteUrl()` so it returns null when only a Discord URL exists. The card's existing `hasClickableLink` gate fails, and the card body renders without an `InkWell` — no hover, no cursor, no click. The Discord icon button remains the sole path.

**Alternatives considered:**
- Detect Discord URLs inside `linkLoader` and no-op or show a toast: rejected. The card still appears clickable, which lies about what will happen.
- Show a "Discord only" tooltip on hover with body click disabled: rejected as out of scope. The visual absence of hover state is itself a signal; explicit tooltip can be a follow-up if users get confused.

### Decision 8: Render click-action preference as three `CheckedPopupMenuItem`s under a disabled group header

**Choice:** In the overflow menu, after a `PopupMenuDivider`, insert a disabled `PopupMenuItem` as a group header labeled "Card click opens", followed by three `OverflowMenuCheckItem` entries (one per enum value). The item matching the current preference renders checked.

**Alternatives considered:**
- Nested submenu: Material `PopupMenuButton` doesn't nest cleanly; rejected.
- Separate modal dialog with radio buttons triggered by a "Card click action…" menu item: rejected. Extra click, extra context switch, for a simple three-way choice.
- Three items without a header: rejected. Grouping intent becomes unclear as the menu grows.

### Decision 9: Convert `buildCatalogOverflowButton` to shared `OverflowMenuButton`

**Choice:** Replace the bespoke `PopupStyleMenuAnchor` implementation with `OverflowMenuButton(menuItems: [...])`. Existing "Data sources…" entry uses `OverflowMenuItem.toEntry(...)`. New click-action entries use `OverflowMenuCheckItem.toEntry(...)`. Group header is a plain `PopupMenuItem<int>(enabled: false, child: Text('Card click opens'))`.

**Alternatives considered:**
- Keep the bespoke implementation and layer on click-action items: rejected. Drift from the other viewer pages has no upside.
- Extend `OverflowMenuButton` with native radio-group support: rejected as scope creep. `CheckedPopupMenuItem` already gives us what we need.

## Risks / Trade-offs

- **Risk:** Users who had the pre-change `splitPane = true` see the Catalog "lose" the browser on first load after update (new default is closed).
  **Mitigation:** Acceptable. The rail tab is visible; one click restores the browser. Not worth a migration path for a desktop hobbyist tool.

- **Risk:** `multi_split_view` rebuilding `areas` while preserving divider position.
  **Mitigation:** The existing `MultiSplitViewMixin` already rebuilds `areas` dynamically (see current `splitPane`-branched getter). Apply the same pattern. Panel width lives in state, not in the controller, so rebuild → reapply size is straightforward.

- **Risk:** Persisted `catalogBrowserPanelWidth` or `catalogCardClickAction` coming back as an invalid/unknown value (corruption, hand-edit, older app version).
  **Mitigation:** On load, clamp width to `[400, pageWidth - 390]`, fall back to 500 if out of range. For the enum, dart_mappable already handles unknown values via `SafeDecodeHook`-style defaults — ensure the Settings mapper uses the default `forumDialog` when decoding fails.

- **Risk:** The Discord exclusion could break another caller of `getBestWebsiteUrl()` that relied on the Discord fallback.
  **Mitigation:** Audit all call sites before changing. If any legitimately want the Discord fallback, keep `getBestWebsiteUrl()` unchanged and add a `getBestForumOrNexusUrl()` variant that excludes Discord, then use the new variant from `ScrapedModCard`.

- **Risk:** User picks `embeddedBrowser` and clicks a card — panel auto-opens, causing a layout shift mid-interaction.
  **Mitigation:** Accepted. The layout shift is the point of the preference. The alternative (silent no-op when panel is closed) would be worse.

- **Risk:** The `WebViewStatus` state machine runs only when the panel is mounted. Opt-in/loading flows defer to first panel open, which may surprise users who previously saw them on page load.
  **Mitigation:** Intentional. No point running a webview nobody asked for. Existing loading spinner handles the first-open case.

- **Trade-off:** Page-scoping the rail means duplication if a future page wants the same pattern.
  **Mitigation:** Accepted. A later change can lift `side_rail/` into `lib/widgets/` when a second consumer appears; the API is already designed for it.

## Migration Plan

No user-facing migration needed. Internal steps:

1. Define `CatalogCardClickAction` enum with `@MappableEnum`.
2. Add the three `Settings` fields with defaults; regenerate mappers.
3. Tweak `getBestWebsiteUrl()` to exclude Discord URLs (after auditing call sites).
4. Build `SideRail` + `SideRailPanel` under `lib/catalog/side_rail/`.
5. Refactor `CatalogPage` to use `SideRail`, remove `splitPane`, wire `linkLoader` to the click-action dispatch.
6. Convert `buildCatalogOverflowButton` to `OverflowMenuButton` and append the click-action items.
7. Manual QA per the scenarios in specs.

Rollback: single commit revert. Settings fields are additive and tolerated if unread.

## Open Questions

None. All decisions resolved during exploration.
