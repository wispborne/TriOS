## ADDED Requirements

### Requirement: Fields can stay as typed text
`SmartSearchBar` SHALL accept an option that turns off pills. With pills off, `key:value` pieces stay in the text exactly where the user typed them, and the query passed to `onChanged` is the text as typed. Field-name and field-value suggestions still work. The piece being completed is the text after the last space or comma before the cursor. The option is on by default, so pages that don't set it behave as before.

#### Scenario: Pills off keeps order
- **WHEN** pills are off and the user types "kol, author:wisp"
- **THEN** `onChanged` receives "kol, author:wisp" unchanged

#### Scenario: Other pages are unchanged
- **WHEN** a page does not set the option
- **THEN** `key:value` pieces still become pills, as before

### Requirement: Custom help panel
`SmartSearchBar` SHALL accept an optional builder for the help panel's contents. When it is given, the info button shows that content. When it is not given, the info button shows the "Search Field Reference" dialog, as before.

#### Scenario: Catalog help
- **WHEN** the Catalog gives its own help content and the user presses the info button
- **THEN** the panel shows the Catalog's search rules instead of the field reference
