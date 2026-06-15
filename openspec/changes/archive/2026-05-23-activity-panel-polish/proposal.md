# Activity Panel Polish

## Problem

The activity panel was added to replace download/install toasts, but the current implementation has two categories of issues:

**UI**: The panel tiles are plain text rows with small icons. The toasts they replaced had card containers with status icons, progress bars with byte counts, and action buttons (Open folder, Enable mod). The panel feels like a downgrade. The panel is also fixed-width with no way to resize it, and always pushes the main content aside — there's no lightweight overlay option.

**State reactivity**: The panel's in-progress vs completed split reads `ValueNotifier.value` at snapshot time inside `ref.watch(downloadManager)`. When a download finishes or install completes, those ValueNotifiers fire — but the panel's filtering logic doesn't re-run because the download manager only invalidates on status changes, not on `installComplete` or `installCancelled` transitions from the panel's perspective. Items can get stuck in the wrong section.

## Proposed Solution

1. **Card-based tiles** inspired by the `ModDownloadGroupToast` item layout: bordered card container, larger status icon, progress bar with status text, and action buttons (Open folder, Enable) on completed items.

2. **Fix state reactivity** so the panel correctly moves items between In Progress and Recent sections when downloads finish, installs complete, or installs fail. The panel should also listen to `installCancelled` to properly handle user-cancelled installs.

3. **Active-state highlight on toolbar icon** — When the activity panel is open, show a subtle background highlight behind the `ActivityIconButton`.

4. **Resizable panel** — Allow the user to drag the left edge of the panel to resize it, with the width persisted to settings.

5. **Pinned vs overlay mode** — A toggle button in the panel header lets the user switch between pinned (pushes content aside) and overlay (floats over content with shadow, rounded corners, dismiss-on-click-outside, fade animation).

6. **Individual item dismiss** — Each completed activity entry has a small X button to remove it from history.

7. **Mod icons on cards** — Show the mod's icon on both in-progress and completed activity cards when available, falling back to a status icon when no icon exists.

## Scope

**In scope:**
- Redesign `InProgressActivityTile` and `CompletedActivityTile` as cards
- Add progress bar with byte count / percentage to in-progress cards
- Add "Open" and "Enable" action buttons to completed cards
- Fix the panel's filtering to be reactive to all relevant state changes
- Show error details on failed items
- Drag-to-resize with persisted width (200–600px range)
- Resize handle with hover indicator
- Pinned/overlay mode toggle with persisted setting
- Overlay mode: rounded corners, shadow, border, inset from window edges
- Overlay mode: click-outside-to-close
- Overlay mode: fade animation on show/hide
- Per-item dismiss button on completed entries
- Mod icon on activity cards (in-progress and completed)

**Non-goals:**
- Adding retry functionality
- Modifying toast behavior
