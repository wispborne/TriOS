# Activity Panel — Tasks

## 1. Data model and persistence

- [x] Create `ActivitySourceType` and `ActivityStatus` enums with `@MappableEnum`
- [x] Create `ActivityEntry` model with `@MappableClass`
- [x] Create `ActivityPanelController` (Riverpod `Notifier`) with history list, `isOpen`, `unseenCount`, disk load/save, `toggle()`, `recordCompletion()`, `clearHistory()`
- [x] Add `isActivityPanelOpen` to settings model (persisted panel open/close state)
- [ ] Run `build_runner` for generated code

## 2. Toolbar icon

- [x] Create `ActivityIconButton` widget with:
  - Download icon
  - Circular progress ring (watches `TriOSDownloadManager` for aggregate progress)
  - Badge count overlay (watches `ActivityPanelController.unseenCount`)
  - `onPressed` calls `ActivityPanelController.toggle()`
- [x] Add `ActivityIconButton` to `CompactTopBar` (right side, before the divider)
- [x] Add `ActivityIconButton` to `FullTopBar` (same position)

## 3. Panel UI

- [x] Create `ActivityItemTile` widget — displays one activity item (in-progress with live progress bar, or completed/failed with status icon and timestamp)
- [x] Create `ActivityPanel` widget — fixed-width column with:
  - Header row ("Activity" label)
  - In-progress section (live `Download` items from `TriOSDownloadManager`)
  - Completed section (history from `ActivityPanelController`)
  - "Clear" button at bottom (only clears completed/failed)
- [x] Wire `ActivityPanel` into `_buildBody` in `AppShell` — add as conditional right sibling in a `Row`

## 4. Toast migration

- [x] Modify `ToastDisplayer` to stop creating download/install toasts (remove `_downloadToastIdsCreated` tracking, group toast logic, individual download toast creation)
- [x] Route download completions to `ActivityPanelController.recordCompletion()` — either from `ToastDisplayer`'s existing mod-variants listener or from `TriOSDownloadManager` directly
- [x] Route archive install completions to `ActivityPanelController.recordCompletion()`
- [x] Verify self-update toast and companion mod toast still work
- [x] Remove unused toast widgets if no longer referenced (`ModDownloadToast`, `ModDownloadGroupToast`, related helpers) — kept files; still used by debug section

## 5. Polish

- [x] Add tooltip to `ActivityIconButton`
- [x] Handle empty state in panel (no activity yet)
- [ ] Test with multiple simultaneous downloads
- [ ] Test with archive drag-drop install
- [ ] Test badge clears on panel open
- [ ] Test "Clear" only removes completed/failed, not in-progress
- [ ] Test history persistence across app restart
- [ ] Test 100-item cap with FIFO eviction
