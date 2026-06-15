## ADDED Requirements

### Requirement: Display value as read-only text by default
The `InlineEditText` widget SHALL display the field label and current value as styled, non-editable text by default. If the value is empty, it SHALL display a placeholder string.

#### Scenario: Field has a value
- **WHEN** the widget renders with a non-empty controller text
- **THEN** the label and value text are displayed in read-only mode with a small edit icon at the end

#### Scenario: Field is empty
- **WHEN** the widget renders with an empty controller text
- **THEN** the label is displayed followed by the placeholder text (e.g., "(empty)") in a muted style, with a small edit icon

### Requirement: Enter edit mode on user action
The widget SHALL switch to a `TextField` when the user clicks the edit icon or the value text.

#### Scenario: Click edit icon
- **WHEN** user clicks the edit icon
- **THEN** the read-only display is replaced with a focused `TextField` containing the current value, plus confirm and cancel action icons

#### Scenario: Click value text
- **WHEN** user clicks the value text area
- **THEN** the widget enters edit mode identically to clicking the edit icon

### Requirement: Confirm edit
The widget SHALL commit the edited value and return to read-only mode when the user confirms.

#### Scenario: Press Enter to confirm
- **WHEN** user presses Enter while the TextField is focused
- **THEN** the TextField value is committed to the controller and the widget returns to read-only mode, and `onChanged` is called

#### Scenario: Click confirm icon
- **WHEN** user clicks the confirm (check) icon
- **THEN** the TextField value is committed to the controller and the widget returns to read-only mode, and `onChanged` is called

### Requirement: Cancel edit
The widget SHALL discard changes and return to read-only mode when the user cancels.

#### Scenario: Press Escape to cancel
- **WHEN** user presses Escape while the TextField is focused
- **THEN** the TextField value is discarded, the controller text reverts to its pre-edit value, and the widget returns to read-only mode

#### Scenario: Click cancel icon
- **WHEN** user clicks the cancel (X) icon
- **THEN** the TextField value is discarded and the widget returns to read-only mode

### Requirement: Edit icon has a tooltip
The edit icon SHALL have a tooltip explaining its purpose.

#### Scenario: Hover over edit icon
- **WHEN** user hovers over the edit icon
- **THEN** a tooltip reading "Edit" is displayed

### Requirement: Dotted underline on value text
The value text in read-only mode SHALL have a dotted underline decoration to visually hint that the field is editable.

#### Scenario: Editable field rendered in read mode
- **WHEN** the widget is in read-only mode
- **THEN** the value text (or placeholder) is displayed with a dotted underline

#### Scenario: Edit mode active
- **WHEN** the widget switches to edit mode (TextField)
- **THEN** the dotted underline is no longer visible (the TextField's own decoration takes over)

### Requirement: Visual consistency with SimpleDataRow
The read-only mode SHALL use the same text styles as `SimpleDataRow` so that editable and non-editable fields look visually consistent within the dialog.

#### Scenario: Rendered alongside SimpleDataRow
- **WHEN** `InlineEditText` and `SimpleDataRow` are rendered in the same column
- **THEN** the label and value text styles match (same `TextTheme.labelLarge`, same font weights)
