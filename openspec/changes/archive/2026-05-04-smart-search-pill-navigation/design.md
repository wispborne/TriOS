## Context

The `SmartSearchBar` widget already has partial pill navigation: pressing backspace/left-arrow at cursor position 0 enters a "pill selection mode" where `_selectedPillIndex` tracks the focused pill. However, the current implementation has a disconnect — the user must mentally switch between "text editing mode" and "pill navigation mode." Gmail's search bar treats chips and text as a single linear sequence, making navigation feel natural.

The current state machine lives in `_handleKeyEvent` with `_selectedPillIndex = -1` meaning "focus is in text field" and `>= 0` meaning "a pill is selected." This is already close to the right model but needs refinement in edge cases and visual feedback.

## Goals / Non-Goals

**Goals:**
- Pills and text input form one continuous cursor sequence: Left/Right arrows traverse pills (as single units) and text seamlessly.
- Two-step backspace deletion: first press selects, second press deletes (prevents accidental filter loss).
- Delete key on a selected pill removes it and advances cursor forward.
- Home/End navigate to the absolute start/end of the pill+text sequence.
- Typing any printable character while a pill is selected deselects it and resumes text input at the appropriate position.

**Non-Goals:**
- Multi-select (Shift+arrow to select multiple pills) — future enhancement.
- Drag-and-drop reordering of pills.
- Editing a pill's content inline (click-to-edit) — users should delete and retype.
- Touch/mobile gestures (desktop-only app).

## Decisions

### 1. Unified cursor position model

**Decision**: Represent cursor position as a single integer spanning `[0, pills.length]` where `0..pills.length-1` means "pill at that index is selected" and `pills.length` means "focus is in the text field." This is essentially what `_selectedPillIndex` already does (with -1 mapped to the "text field" position), but reframing it as a linear sequence simplifies the arrow-key logic.

**Rationale**: The existing `_selectedPillIndex` approach is nearly correct. Rather than introducing a new abstraction (e.g., a `CursorPosition` sealed class), we keep the integer but adjust the navigation logic to always flow linearly. This minimizes code churn while achieving the Gmail feel.

**Alternative considered**: A sealed union type (`PillCursor(index)` | `TextCursor`) — adds type safety but overcomplicates a simple integer state that only this widget uses internally.

### 2. Two-step backspace deletion

**Decision**: When cursor is in the text field at offset 0 and backspace is pressed, select the last pill (highlight it). A second backspace deletes the selected pill. This matches Gmail exactly.

**Rationale**: Prevents accidental deletion of carefully constructed filters. The visual highlight gives clear feedback that the next backspace will delete.

**Alternative considered**: Single-press delete (current behavior for when already in pill mode). Too destructive for filters that may have been auto-committed from complex typed expressions.

### 3. Forward-delete behavior

**Decision**: The Delete key on a selected pill removes it and moves selection to the next pill (or into the text field if it was the last pill). This mirrors how Delete works in text — it removes the character *after* the cursor.

**Rationale**: Consistent with standard text editing mental model where Delete removes forward and Backspace removes backward.

### 4. Visual feedback via border highlight

**Decision**: Keep the existing `Border.all(color: primary)` approach for selected pills. No additional animation or background color change needed.

**Rationale**: The current highlight is already visible and consistent with Material selection patterns. Adding more visual weight would conflict with the negation-pill red background.

## Risks / Trade-offs

- **[Risk] Focus management complexity** → The text field's own cursor and the pill selection state must stay in sync. Mitigation: Already handled by the existing `_selectedPillIndex = -1` escape hatch; we just need to ensure arrow-right from the last pill places the text cursor at offset 0.
- **[Risk] Screen reader accessibility** → Pills-as-characters may confuse screen readers that expect standard text semantics. Mitigation: Add `Semantics` labels to pills indicating their position ("Filter 1 of 3: type:weapon"). This is a future improvement, not blocking.
- **[Trade-off] Two-step delete adds a keypress** → Power users who want rapid deletion need two presses. Acceptable because filter pills represent more semantic weight than single characters, and Gmail has proven this pattern works.
