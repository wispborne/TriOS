## 1. Refactor cursor navigation logic

- [x] 1.1 Refactor `_handleKeyEvent` Left arrow: when in text field at offset 0 with pills present, select last pill (already works); ensure it does NOT delete on first press
- [x] 1.2 Refactor `_handleKeyEvent` Right arrow in pill mode: advance to next pill, or if on last pill, return to text field at offset 0
- [x] 1.3 Ensure Left arrow on first pill stays at first pill (no wrap-around)

## 2. Two-step backspace deletion

- [x] 2.1 Backspace at text offset 0: select last pill without deleting (first press = select only)
- [x] 2.2 Backspace on already-selected pill: delete it, move selection to previous pill or clear if none remain

## 3. Delete key forward behavior

- [x] 3.1 Delete on selected pill: remove it, advance selection to the next pill (now at same index)
- [x] 3.2 Delete on last pill: remove it, return focus to text field

## 4. Home/End navigation

- [x] 4.1 Home key from text field or any pill: select first pill (index 0)
- [x] 4.2 End key from pill selection: clear selection, place text cursor at end of text content

## 5. Printable character escape

- [x] 5.1 Any printable character while pill selected: deselect pill, place cursor at text offset 0, allow keystroke to pass through to text field (existing behavior — verify it works correctly)

## 6. Testing

- [x] 6.1 Add widget tests for left/right arrow traversal across pills and into text field
- [x] 6.2 Add widget tests for two-step backspace (select then delete)
- [x] 6.3 Add widget tests for Delete key forward behavior
- [x] 6.4 Add widget tests for Home/End key navigation
