# Activity Panel

## Problem

Download and install progress is shown via ephemeral toasts that auto-dismiss. Once dismissed, there's no record of what happened — no way to see what was recently installed or whether something failed. Users who trigger multiple downloads or drag-drop several archives have no persistent view of that activity.

## Proposed Solution

Replace download/install toasts with a persistent **Activity Panel** — a fixed-width side panel that pushes content, toggled by an icon button in the top-right toolbar. The panel shows both in-progress and completed mod operations.

The toolbar icon shows:
- A **circular progress ring** (aggregate of all in-flight operations) when anything is active
- A **badge count** of completions since the panel was last opened (Edge-style "unseen" count)

## Scope

**In scope:**
- Activity panel UI (fixed-width, pushes content, both layout modes)
- Toolbar icon with progress ring and unseen-completion badge
- In-progress items: downloads and archive installs with live progress
- Completed/failed history: persisted until user clears, capped at 100
- "Clear" button that removes completed/failed items only (not in-progress)
- Migrate download toasts into the panel
- Migrate archive-install toasts into the panel

**Out of scope (non-goals):**
- App self-update notifications (remain as toasts)
- Mod enable/disable, deletion, profile switches
- Auto-opening the panel when activity starts
- Panel resizing (fixed width)
- Retry failed operations from the panel
- "Mod added" detection toasts (the companion mod update toast stays as-is)
