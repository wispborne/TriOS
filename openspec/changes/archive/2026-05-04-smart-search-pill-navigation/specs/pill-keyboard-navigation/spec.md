## ADDED Requirements

### Requirement: Left arrow navigates from text field into pills
The smart search bar SHALL move selection to the last pill when the user presses the Left arrow key while the text cursor is at position 0 in the text field.

#### Scenario: Left arrow at start of text with pills present
- **WHEN** the text cursor is at offset 0 and there are committed pills
- **THEN** the last pill becomes selected and the text field cursor is deactivated

#### Scenario: Left arrow at start of text with no pills
- **WHEN** the text cursor is at offset 0 and there are no committed pills
- **THEN** nothing happens (key event is ignored)

### Requirement: Right arrow navigates from pills into text field
The smart search bar SHALL move selection from the last pill back into the text field (cursor at offset 0) when the user presses the Right arrow key while the last pill is selected.

#### Scenario: Right arrow on last pill
- **WHEN** the last pill is selected and the user presses Right arrow
- **THEN** pill selection is cleared and the text cursor is placed at offset 0

#### Scenario: Right arrow on non-last pill
- **WHEN** a pill that is not the last one is selected and the user presses Right arrow
- **THEN** the next pill becomes selected

### Requirement: Left arrow traverses pills sequentially
The smart search bar SHALL select the previous pill when the user presses Left arrow while a pill (other than the first) is selected.

#### Scenario: Left arrow on middle pill
- **WHEN** pill at index N (where N > 0) is selected and Left arrow is pressed
- **THEN** pill at index N-1 becomes selected

#### Scenario: Left arrow on first pill
- **WHEN** the first pill (index 0) is selected and Left arrow is pressed
- **THEN** selection remains on the first pill (no wrap-around)

### Requirement: Two-step backspace deletion
The smart search bar SHALL require two backspace presses to delete a pill: the first selects it, the second deletes it. This prevents accidental deletion.

#### Scenario: Backspace at text position 0 selects last pill
- **WHEN** the text cursor is at offset 0, there are committed pills, and no pill is currently selected
- **THEN** the last pill becomes selected (highlighted) but is NOT deleted

#### Scenario: Backspace on a selected pill deletes it
- **WHEN** a pill is currently selected and the user presses Backspace
- **THEN** the selected pill is removed and selection moves to the previous pill (or clears if none remain)

### Requirement: Delete key removes selected pill forward
The smart search bar SHALL remove the selected pill and advance selection forward when the Delete key is pressed on a selected pill.

#### Scenario: Delete on selected pill with more pills after
- **WHEN** pill at index N is selected, there are pills after it, and the user presses Delete
- **THEN** the pill at index N is removed and the pill that was at index N+1 (now at index N) becomes selected

#### Scenario: Delete on last selected pill
- **WHEN** the last pill is selected and the user presses Delete
- **THEN** the pill is removed and focus returns to the text field

### Requirement: Home key jumps to first pill
The smart search bar SHALL select the first pill when the Home key is pressed, regardless of current cursor position.

#### Scenario: Home from text field
- **WHEN** focus is in the text field and there are committed pills and the user presses Home
- **THEN** the first pill (index 0) becomes selected

#### Scenario: Home from middle pill
- **WHEN** a pill other than the first is selected and the user presses Home
- **THEN** the first pill becomes selected

### Requirement: End key jumps to text field
The smart search bar SHALL return focus to the text field (cursor at end) when the End key is pressed, regardless of current position.

#### Scenario: End from pill selection
- **WHEN** any pill is selected and the user presses End
- **THEN** pill selection is cleared and the text cursor is placed at the end of the text field content

### Requirement: Printable character exits pill selection
The smart search bar SHALL exit pill selection mode and insert the typed character into the text field when a printable character is pressed while a pill is selected.

#### Scenario: Typing while pill selected
- **WHEN** a pill is selected and the user types a printable character
- **THEN** pill selection is cleared, the text cursor is placed at offset 0, and the character is passed through to the text field for normal insertion

### Requirement: Selected pill visual feedback
The smart search bar SHALL display a distinct visual highlight on the currently selected pill to indicate it will be affected by the next keyboard action.

#### Scenario: Pill becomes selected
- **WHEN** a pill transitions from unselected to selected state
- **THEN** the pill displays a primary-color border to indicate selection

#### Scenario: Pill becomes deselected
- **WHEN** a selected pill transitions to unselected state
- **THEN** the pill's border returns to transparent
