# Activity Panel Polish — Design

## State Reactivity Fix

### Problem Detail

`ActivityPanel.build()` does `ref.watch(downloadManager)` and then filters downloads using `.value` reads on ValueNotifiers:

```dart
final inProgress = downloads.where((d) {
  final status = d.task.status.value;           // snapshot, not reactive
  final installDone = d.installComplete.value;   // snapshot, not reactive
  return !status.isCompleted || !installDone;
}).toList();
```

The download manager invalidates itself when `status` changes and when `installComplete` changes (via listeners added in `addDownload`). But `installCancelled` does NOT have a listener. If a user cancels an install, `installCancelled` fires but the manager never invalidates, so the panel never re-filters.

### Fix

Add an `installCancelled` listener in `TriOSDownloadManager.addDownload()` that calls `ref.invalidateSelf()`, matching the existing `installComplete` listener pattern. Also add the same listener in `addInstallation()` for archive-only installs.

## Card-Based Tiles

### InProgressActivityTile

Wrapped in `_ActivityCard` (bordered container with rounded corners). Layout: status icon left, mod name, status text, `TriOSDownloadProgressIndicator` for live progress.

### CompletedActivityTile

Wrapped in `_ActivityCard`. Layout: mod icon (or status icon fallback), mod name + version + dismiss X button, source type + relative timestamp, error details (if failed), action buttons (Open folder, Enable mod) for successful installs.

### Resolving the variant for action buttons

`CompletedActivityTile` watches `AppState.mods` and looks up the mod by `modId` (falling back to name match). If found, shows action buttons; if not, hides them.

## Active-State Highlight on Toolbar Icon

Conditional `backgroundColor` on the existing `IconButton` — 8% `onSurface` tint when open, `null` when closed. No new state or widgets needed.

## Resizable Panel

### Settings

New field `activityPanelWidth` (double, default 320) in `Settings`. Constants in `activity_panel.dart`: `minActivityPanelWidth = 200`, `maxActivityPanelWidth = 600`.

### Drag Handle

A vertical pill-shaped indicator on the left edge of the panel, rendered in `app_shell.dart` via `_buildResizeHandle()`. The handle:
- Uses `MouseRegion` with `SystemMouseCursors.resizeColumn`
- Tracks hover state via `_isResizeHandleHovered` on `_AppShellState`
- On hover: pill grows from 40px to 48px, color changes from 20% to 60% `onSurface`, animated over 150ms
- `GestureDetector.onHorizontalDragUpdate` calculates new width (dragging left = wider, since panel is on the right), clamped to min/max, and persists to settings

### Width Application

`ActivityPanel.build()` reads width from settings: `ref.watch(appSettings.select((s) => s.activityPanelWidth))`.

## Pinned vs Overlay Mode

### Settings

New enum `ActivityPanelMode { pinned, overlay }` and field `activityPanelMode` (default: `pinned`) in `Settings`.

### Toggle Button

Pin icon button in the `ActivityPanel` header (between Clear and the right edge). Shows filled `push_pin` when pinned, outlined `push_pin_outlined` when overlay. Tooltip describes the action. Toggles `activityPanelMode` in settings.

### Layout in AppShell

`_buildBody()` reads both `isActivityPanelOpen` and `activityPanelMode`:

- **Pinned**: resize handle + `ActivityPanel` are children of the main `Row`, pushing content aside.
- **Overlay**: resize handle + `ActivityPanel` are inside the content `Stack` as a `Positioned` overlay on the right edge.

### Overlay Styling

In overlay mode, the `ActivityPanel` container:
- Has 12dp rounded corners with `Clip.antiAlias`
- Has a 1dp border at 8% `onSurface` opacity (instead of the left-only border in pinned mode)
- Is wrapped in a `DecoratedBox` with a `BoxShadow` (black 30%, 16dp blur, offset -2,2)
- Is inset 8dp right, 4dp top, 8dp bottom from the window edges

### Click-Outside-to-Close

A `Positioned.fill` `GestureDetector` with `HitTestBehavior.opaque` sits behind the overlay panel. Tapping it sets `isActivityPanelOpen = false`. Wrapped in `IgnorePointer(ignoring: !isOpen)` so it doesn't block interaction when hidden.

### Fade Animation

The overlay is always mounted when in overlay mode (not conditionally inserted). `AnimatedOpacity` with 120ms duration fades the panel in/out. `IgnorePointer(ignoring: !isOpen)` prevents interaction when invisible.

## Mod Icons on Cards

Both tile types show the mod's icon (24px via `ModIcon` widget) when available, falling back to the status icon.

### CompletedActivityTile

Already resolves the mod via `modId`/name lookup from `AppState.mods`. Uses `variant?.iconFilePath` directly. Falls back to check/error status icon if the mod has no icon or is uninstalled.

### InProgressActivityTile

Uses a `_resolveIconPath()` helper with two-level fallback:
1. `download.installedVariant.value?.iconFilePath` — available once install completes
2. `ModVariant.iconCache[modInfo.id]` — static cache keyed by mod ID, available if a previous version of the mod was already loaded (covers the common "updating an existing mod" case)

Falls back to the status icon (schedule/downloading/installing) when no icon path is found (e.g., brand-new mod being installed for the first time).

The `ListenableBuilder` also listens to `download.installedVariant` so the tile rebuilds and picks up the icon once installation writes the variant.

## Individual Item Dismiss

### Controller

`ActivityHistoryStore.removeEntry(String id)` filters out the entry with the matching id and persists.

### UI

`CompletedActivityTile` has a 20x20 `IconButton` with `Icons.close` at 14px, positioned after the version text in the header row. Tooltip: "Remove". Calls `removeEntry(entry.id)` on tap.

## Files Modified

| File | Change |
|------|--------|
| `lib/trios/settings/settings.dart` | Add `activityPanelWidth`, `activityPanelMode`, `ActivityPanelMode` enum |
| `lib/trios/settings/settings.mapper.dart` | Regenerated |
| `lib/trios/activity_panel/activity_panel.dart` | Use width from settings, mode-aware decoration (rounded corners, border), pin toggle button |
| `lib/trios/activity_panel/activity_item_tile.dart` | Card-based tiles, mod icons, dismiss X button on completed items |
| `lib/trios/activity_panel/activity_panel_controller.dart` | Add `removeEntry(id)` method |
| `lib/trios/activity_panel/activity_entry.dart` | Add optional `modId` field |
| `lib/trios/activity_panel/activity_entry.mapper.dart` | Regenerated |
| `lib/trios/download_manager/download_manager.dart` | Add `installCancelled` listener |
| `lib/trios/toasts/toast_manager.dart` | Populate `modId` when creating `ActivityEntry` |
| `lib/toolbar/activity_icon_button.dart` | Active-state highlight |
| `lib/app_shell.dart` | Resize handle, pinned/overlay layout, click-outside-to-close, fade animation |
