## 1. Settings & Data Model

- [x] 1.1 Add `weaponsSearchHistory List<String>` field to `Settings` with default `[]`
- [x] 1.2 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate mapper

## 2. Parser

- [x] 2.1 Create `lib/widgets/smart_search/search_dsl_parser.dart` — `ParsedQuery`, `FieldToken`, `TextToken` data classes
- [x] 2.2 Implement `SearchDslParser.parse(String query)` — tokenize on whitespace, split `field:op:value`, handle negation prefix `-`, handle operators `:`, `:>`, `:<`, `:>=`, `:<=`
- [x] 2.3 Write unit tests for the parser: plain text, field equality, negation, numeric operators, mixed query, unknown field fallback

## 3. SearchField Model

- [x] 3.1 Create `lib/widgets/smart_search/search_dsl_field.dart` — `SearchField<T>` (key, description, supportsNumeric, supportsNegation, valueSuggestions fn, matches fn) and untyped `SearchFieldMeta` for the widget

## 4. SmartSearchBar Widget

- [x] 4.1 Create `lib/widgets/smart_search/smart_search_bar.dart` skeleton — `SmartSearchBar` stateful widget with params: `List<SearchFieldMeta> fields`, `List<String> recentHistory`, `ValueChanged<String> onChanged`, `VoidCallback onHistoryEntrySubmitted`, `String initialValue`
- [x] 4.2 Implement pill rendering — `Wrap` of committed `FieldToken` chips with ✕ buttons; negated pills visually distinct (e.g. red tint or `-` prefix)
- [x] 4.3 Implement autocomplete overlay — `OverlayEntry` below the text field; show field-name suggestions when no `:` in current token, value suggestions after `key:`; filter as user types
- [x] 4.4 Implement Space-to-commit — pressing Space (or Tab) commits the current raw token into a pill if it parses as a valid `FieldToken`; unrecognized tokens stay as text
- [x] 4.5 Implement keyboard navigation in dropdown — ↑↓ to move highlight, Enter/Tab to accept, Escape to dismiss
- [x] 4.6 Implement info panel — `ℹ` `IconButton` with tooltip that opens a scrollable popover listing all `SearchFieldMeta` entries (key, description, operators available, example values)
- [x] 4.7 Implement recent history — show last N history entries in the dropdown when the bar is focused and query is empty; selecting one restores it as the current query
- [x] 4.8 Wire overlay positioning — use `CompositedTransformFollower`; flip above field if insufficient space below

## 5. Weapons Page Integration

- [x] 5.1 Define `List<SearchField<Weapon>>` in `weapons_page_controller.dart` covering: `tracking`, `ammo`, `type`, `size`, `damage`, `range`, `op`, `dps`, `hint`, `tag`, `mod`
- [x] 5.2 Replace `_filterBySearch` in `WeaponsPageController` with `ParsedQuery` application — `TextToken`s use existing index, `FieldToken`s dispatch to `SearchField.matches`
- [x] 5.3 Add history read/write to `WeaponsPageController` — on query submit, prepend to `weaponsSearchHistory` in settings, dedup, cap at 10
- [x] 5.4 Swap `ViewerSearchBox` for `SmartSearchBar` in `weapons_page.dart` — pass `fields` metadata and `recentHistory` from controller state
- [ ] 5.5 Smoke test: verify plain text search still works, `tracking:excellent` filters correctly, `-type:missile` excludes missiles, `range:>800` filters by range, pills commit and remove, autocomplete shows correct suggestions, info panel opens, recent history appears

## 6. Cleanup

- [x] 6.1 Add tooltips to the `ℹ` icon button and pill ✕ buttons per project convention
