## ADDED Requirements

### Requirement: DSL token parsing
The `SearchDslParser` SHALL parse a raw query string into a `ParsedQuery` containing an ordered list of tokens. Each token is either a `FieldToken(key, operator, value, negated)` or a `TextToken(text)`. Whitespace between tokens is the separator. A `FieldToken` is any token matching `[-]key[op]value` where `op` is `:`, `:>`, `:<`, `:>=`, or `:<=`. Everything else is a `TextToken`. Multiple tokens are combined with AND semantics.

#### Scenario: Plain text token
- **WHEN** the query is `laser`
- **THEN** the parser produces one `TextToken("laser")`

#### Scenario: Field equality token
- **WHEN** the query is `tracking:excellent`
- **THEN** the parser produces one `FieldToken(key:"tracking", op:equals, value:"excellent", negated:false)`

#### Scenario: Negated field token
- **WHEN** the query is `-type:missile`
- **THEN** the parser produces one `FieldToken(key:"type", op:equals, value:"missile", negated:true)`

#### Scenario: Numeric comparator token
- **WHEN** the query is `range:>800`
- **THEN** the parser produces one `FieldToken(key:"range", op:greaterThan, value:"800", negated:false)`

#### Scenario: Mixed token query
- **WHEN** the query is `laser tracking:excellent -size:large`
- **THEN** the parser produces three tokens: `TextToken("laser")`, `FieldToken("tracking", equals, "excellent", false)`, `FieldToken("size", equals, "large", true)`

#### Scenario: Unknown field token falls back to text
- **WHEN** a `FieldToken` key does not match any registered `SearchField`
- **THEN** it is treated as a `TextToken` for substring matching purposes

---

### Requirement: SearchField registration
Each viewer page SHALL register a `List<SearchField<T>>` with its controller. A `SearchField<T>` defines: `key` (the DSL token name), `description` (shown in the info panel), `valueSuggestions` (a function producing candidate values from the loaded item list), `matches(item, operator, value) -> bool`, `supportsNumeric` (whether `>/<` operators are valid), and `supportsNegation`.

#### Scenario: Field matches item
- **WHEN** a `FieldToken(key:"tracking", op:equals, value:"excellent")` is applied to a weapon with `trackingStr == "Excellent"`
- **THEN** `SearchField.matches` returns `true`

#### Scenario: Numeric field matches comparator
- **WHEN** a `FieldToken(key:"range", op:greaterThan, value:"800")` is applied to a weapon with `range == 900`
- **THEN** `SearchField.matches` returns `true`

#### Scenario: Numeric field rejects non-numeric value gracefully
- **WHEN** a numeric field receives a non-parseable value string
- **THEN** `matches` returns `false` without throwing

---

### Requirement: ParsedQuery application
The page controller SHALL apply a `ParsedQuery` to its item list using AND semantics: an item passes if every token matches. `TextToken`s use the existing per-item substring index. `FieldToken`s dispatch to the matching `SearchField.matches`. Negated tokens invert the result.

#### Scenario: All tokens must match
- **WHEN** the query is `laser tracking:excellent` and a weapon matches `laser` but not `tracking:excellent`
- **THEN** the weapon is excluded from results

#### Scenario: Negated token excludes matches
- **WHEN** the query is `-type:missile` and a weapon has `weaponType == "MISSILE"`
- **THEN** the weapon is excluded from results

#### Scenario: Empty query shows all items
- **WHEN** the query is empty or whitespace only
- **THEN** all items pass the filter

---

### Requirement: Token pills in search bar
The `SmartSearchBar` SHALL render each parsed `FieldToken` as a removable chip (pill) inside the search bar input area. Plain text (`TextToken`) remains as editable text. Clicking the ✕ on a pill removes that token from the query string and triggers a re-filter.

#### Scenario: Field token renders as pill
- **WHEN** the user has typed `tracking:excellent` and pressed space or moved the cursor past it
- **THEN** the token appears as a chip labeled `tracking: excellent` with an ✕ button

#### Scenario: Pill removal updates query
- **WHEN** the user clicks ✕ on a pill
- **THEN** that token is removed from the query string and the item list re-filters immediately

#### Scenario: Negated pill is visually distinct
- **WHEN** a token is negated (e.g., `-type:missile`)
- **THEN** the pill renders with a visual indicator (e.g., strikethrough, different color, or `-` prefix label)

---

### Requirement: Discord-style autocomplete dropdown
The `SmartSearchBar` SHALL show an autocomplete dropdown while the user is typing. Before any `:` is typed, the dropdown suggests matching field keys from the registered `SearchField` list. After `key:` is typed, the dropdown narrows to valid values for that field, drawn from actual loaded items via `valueSuggestions`. Keyboard navigation (↑↓ arrows, Tab/Enter to accept, Escape to dismiss) SHALL be supported.

#### Scenario: Field name suggestions appear
- **WHEN** the user types `tr` with no `:` present in the current token
- **THEN** the dropdown lists all fields whose key starts with or contains `tr` (e.g., `tracking`, `turnrate`)

#### Scenario: Value suggestions appear after colon
- **WHEN** the user has typed `tracking:` 
- **THEN** the dropdown lists all distinct values returned by that field's `valueSuggestions` function

#### Scenario: Value suggestions filter as user types
- **WHEN** the user has typed `tracking:ex`
- **THEN** the dropdown filters to values containing `ex` (e.g., `excellent`)

#### Scenario: Keyboard navigation selects suggestion
- **WHEN** the dropdown is open and the user presses ↓ then Enter
- **THEN** the highlighted suggestion is inserted into the query

#### Scenario: No suggestions hides the dropdown
- **WHEN** there are no matching field names or values for the current input
- **THEN** the dropdown is not shown

---

### Requirement: Info panel
The `SmartSearchBar` SHALL include an `ℹ` icon button that opens a panel (tooltip, popover, or bottom sheet) listing every registered `SearchField` with its key, description, whether it supports negation, whether it supports numeric comparators, and example values. The panel is scrollable if the field list is long.

#### Scenario: Info panel lists all fields
- **WHEN** the user taps the `ℹ` icon
- **THEN** a panel appears showing one entry per registered `SearchField`

#### Scenario: Info panel shows numeric indicator
- **WHEN** a field has `supportsNumeric: true`
- **THEN** its entry shows that `>`, `<`, `>=`, `<=` operators are available

#### Scenario: Info panel closes on dismiss
- **WHEN** the user taps outside the panel or presses Escape
- **THEN** the panel closes without changing the query

---

### Requirement: Recent search history
The `SmartSearchBar` SHALL persist the last 10 distinct non-empty queries to local storage (settings). When the search bar is focused and the query is empty, the autocomplete dropdown SHALL display recent queries as suggestions, most recent first. Selecting a recent query restores it as the current query.

#### Scenario: Recent queries shown on focus
- **WHEN** the user focuses the search bar with an empty query
- **THEN** the dropdown shows up to 10 recent queries

#### Scenario: Selecting recent query restores it
- **WHEN** the user selects a recent query from the dropdown
- **THEN** the full query string is restored and filtering is applied immediately

#### Scenario: Duplicate queries are deduplicated
- **WHEN** the user submits a query that is already in the history
- **THEN** it is moved to the top of the history rather than added as a duplicate

#### Scenario: History is capped at 10 entries
- **WHEN** the history already has 10 entries and a new distinct query is submitted
- **THEN** the oldest entry is removed and the new query is added at the top
