## Why

The smart search bar already supports pill-based filter tokens, but keyboard navigation between pills feels disconnected from the text input. Users expect Gmail-style behavior where pills act as single characters in the cursor flow — left/right arrows move through them seamlessly, backspace deletes the previous pill when at position 0, and the entire row feels like one continuous editable sequence. This makes power-user workflows significantly faster.

## What Changes

- Pills behave as single-character units in the cursor flow: arrow keys move the cursor through pills and text as one sequence.
- Backspace at cursor position 0 selects the previous pill; a second backspace deletes it (two-step delete prevents accidents).
- Delete key on a selected pill removes it and advances cursor forward.
- Home/End keys jump to the start/end of the entire pill+text sequence.
- Clicking a pill selects it inline (existing behavior, refined with visual feedback).
- Selected pill shows a distinct highlight; pressing any printable key deselects and resumes typing.

## Capabilities

### New Capabilities

- `pill-keyboard-navigation`: Seamless keyboard navigation through pills as single-character units, including selection, deletion, and cursor flow between pills and text input.

### Modified Capabilities

## Impact

- `lib/widgets/smart_search/smart_search_bar.dart` — Refactor `_handleKeyEvent` and pill selection state to implement unified cursor model.
- `lib/widgets/filter_pill.dart` — May need visual states for "cursor-adjacent" vs "selected" feedback.
- All pages using `SmartSearchBar` benefit automatically with no changes needed.
