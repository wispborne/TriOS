# Activity Panel Polish — Tasks

## 1. Fix state reactivity

- [x] Add `installCancelled` listener in `TriOSDownloadManager.addDownload()` that calls `ref.invalidateSelf()`
- [x] Add `installCancelled` and `installComplete` listeners in `TriOSDownloadManager.addInstallation()` for archive-only installs
- [x] Verify that `ToastDisplayer` correctly handles cancelled installs

## 2. Add modId to ActivityEntry

- [x] Add optional `modId` field to `ActivityEntry`
- [x] Populate `modId` in `ToastDisplayer` when creating completion entries
- [x] Run `build_runner` to regenerate mapper

## 3. Redesign InProgressActivityTile as card

- [x] Wrap content in `_ActivityCard` container (rounded corners, subtle border)
- [x] Add status icon on the left (queued/downloading/installing)
- [x] Replace raw `LinearProgressIndicator` with `TriOSDownloadProgressIndicator`
- [x] Show install progress status text when installing

## 4. Redesign CompletedActivityTile as card

- [x] Wrap content in `_ActivityCard` container
- [x] Look up mod by `modId` (falling back to name match) from `AppState.mods`
- [x] Add "Open" button (opens mod folder)
- [x] Add "Enable" button (activates mod variant, shown when not already enabled)
- [x] Add tooltips to action buttons

## 5. Active-state highlight on toolbar icon

- [x] Add conditional `backgroundColor` to `ActivityIconButton` when panel is open

## 6. Panel layout adjustments

- [x] Adjust `ActivityPanel` padding for card-based tiles
- [x] Verify empty state and scrolling behavior

## 7. Resizable panel

- [x] Add `activityPanelWidth` field to `Settings` (default 320)
- [x] Add min/max width constants (200, 600) in `activity_panel.dart`
- [x] Use width from settings in `ActivityPanel.build()`
- [x] Add `_buildResizeHandle()` method to `_AppShellState` with drag-to-resize
- [x] Add hover indicator on resize handle (animated pill + color change)
- [x] Regenerate mapper

## 8. Pinned vs overlay mode

- [x] Add `ActivityPanelMode` enum (`pinned`, `overlay`) to `settings.dart`
- [x] Add `activityPanelMode` field to `Settings` (default: `pinned`)
- [x] Add pin toggle button in `ActivityPanel` header
- [x] In `app_shell.dart`, render pinned mode in `Row`, overlay mode in `Stack`
- [x] Overlay styling: 12dp rounded corners, `Clip.antiAlias`, mode-aware border
- [x] Overlay styling: `DecoratedBox` with `BoxShadow` (black 30%, 16dp blur)
- [x] Overlay styling: 1dp border at 8% `onSurface` opacity
- [x] Overlay styling: inset from window edges (8dp right, 4dp top/bottom)
- [x] Click-outside-to-close via `Positioned.fill` `GestureDetector`
- [x] Fade animation: `AnimatedOpacity` (120ms), `IgnorePointer` when hidden
- [x] Regenerate mapper

## 9. Mod icons on cards

- [x] Show `ModIcon` (24px) on `CompletedActivityTile` using `variant?.iconFilePath`, falling back to status icon
- [x] Add `_resolveIconPath()` to `InProgressActivityTile` — checks `installedVariant` then `ModVariant.iconCache` by mod ID
- [x] Add `download.installedVariant` to `ListenableBuilder.listenable` merge so tile rebuilds on icon availability
- [x] Import `ModVariant` and `ModIcon` in `activity_item_tile.dart`

## 10. Individual item dismiss

- [x] Add `removeEntry(String id)` method to `ActivityHistoryStore`
- [x] Add dismiss X button (20x20, `Icons.close`) to `CompletedActivityTile` header row
- [x] Add "Remove" tooltip to dismiss button
