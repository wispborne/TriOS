## Context

All viewer pages (weapons, ships, hullmods) share the same search pattern: a `ViewerSearchBox` widget, a `currentSearchQuery` string in state, a `_updateSearchIndices` method that builds a per-item `Map<id, List<String>>` of lowercased field values, and a `_filterBySearch` method that does `.any(value.contains(query))`. This works for plain text but has no structure.

The new system replaces this with a typed DSL layer while keeping the existing substring index for plain-text tokens.

## Goals / Non-Goals

**Goals:**
- Generic widget (`SmartSearchBar<T>`) usable by any viewer page without modification to the widget itself
- Parser is stateless and pure — easy to test
- Each page owns its field definitions; the widget and parser know nothing about the data model
- Token pills, autocomplete, info panel, negation, numeric comparators, recent history
- Weapons page is the first consumer; ships and hullmods follow the same pattern with no framework changes

**Non-Goals:**
- OR logic within a single field (e.g., `type:missile|energy`) — AND-only for now
- Saved/named presets
- Field aliases (short forms)
- Modifying the existing chip filter panel

## Decisions

### Data model: `SearchField<T>` is typed, passed through widget as untyped

The widget (`SmartSearchBar`) needs field metadata for autocomplete and the info panel (keys, descriptions, value suggestions) but does NOT need to apply `matches`. Matching happens in the controller.

**Decision**: `SearchField<T>` is a typed class owned by the controller. The widget receives `List<SearchFieldMeta>` (untyped: key, description, supportsNumeric, supportsNegation, valueSuggestions as `List<String>`) so the widget has zero dependency on the item type. The controller holds the full `SearchField<T>` list and applies `matches` itself.

**Alternative considered**: Pass `List<SearchField<T>>` to the widget and let the widget also apply filters. Rejected — violates separation; the widget should only handle UI.

---

### Token pills: parse-on-commit, not parse-on-keystroke

Discord-style pills commit when the user presses Space (or moves the cursor away from the token). Parsing mid-keystroke would create flickering pills and disrupt typing.

**Decision**: Pills are rendered from the controller's last applied `ParsedQuery`, not from live text. The text field shows the raw in-progress token. On Space or blur, the new token is parsed and a pill may be committed.

**Alternative considered**: Always parse the full string and re-render pills continuously. Rejected — too much state churn mid-edit.

---

### Recent history storage: in `Settings` via `appSettings`

The existing settings system (`lib/trios/settings/settings.dart`, serialized via dart_mappable) already persists viewer state. Search history is a small `List<String>` that fits naturally there.

**Decision**: Add `weaponsSearchHistory`, `shipsSearchHistory`, `hullmodsSearchHistory` as `List<String>` fields in `Settings` (capped at 10). The page controller reads/writes history; the widget receives it as a plain `List<String>` parameter.

**Alternative considered**: A shared single `Map<pageId, List<String>>` history field. Rejected — dart_mappable handles flat typed fields more cleanly; per-page fields are explicit.

---

### New file location: `lib/widgets/smart_search/`

Consistent with the existing `lib/widgets/` pattern for shared viewer widgets (`ViewerSearchBox`, `ViewerToolbar`, `FiltersPanel`).

Files:
- `search_dsl_field.dart` — `SearchField<T>` and `SearchFieldMeta`
- `search_dsl_parser.dart` — `SearchDslParser`, `ParsedQuery`, `FieldToken`, `TextToken`
- `smart_search_bar.dart` — `SmartSearchBar` widget

---

### Autocomplete: custom overlay, not Flutter's `SearchAnchor`

The current `ViewerSearchBox` uses `SearchAnchor` but with an empty `suggestionsBuilder`. `SearchAnchor` doesn't support mixed pill+text input, so we need a custom approach.

**Decision**: Replace with a plain `TextField` + `OverlayEntry` for the dropdown. Pills sit in a `Wrap` above (or inside) the field. The overlay positions below the field and shows field-name or value suggestions depending on the cursor position.

**Alternative considered**: Keep `SearchAnchor` and layer pills on top. Rejected — the anchor's open/close model conflicts with pills-as-chips inside the input area.

---

### Numeric matching: parse value string to double at match time

No pre-computation. Each `FieldToken` with a numeric operator parses its value string to `double` at match time. If parsing fails, the match returns `false`.

## Risks / Trade-offs

- **Token pill UX is fiddly** — Space-to-commit is standard but unfamiliar; users may be confused why `tracking:excellent` didn't become a pill. Mitigation: show a hint in the placeholder text (`field:value — press Space to commit`).
- **Autocomplete overlay positioning** — overlays near window edges can clip. Mitigation: use `CompositedTransformFollower` + bounds check; flip above the field if insufficient space below.
- **History in Settings grows the settings model** — three new `List<String>` fields add minor serialization overhead. Acceptable given cap of 10 × 3 entries.
- **Ships and hullmods not migrated in this change** — `ViewerSearchBox` stays until those pages are updated. Two search widgets coexist temporarily. Mitigation: keep `ViewerSearchBox` as-is; `SmartSearchBar` is additive.

## Migration Plan

1. Add history fields to `Settings` + run `build_runner`
2. Build `lib/widgets/smart_search/` (parser, field model, widget)
3. Weapons controller: define `List<SearchField<Weapon>>`, replace `_filterBySearch` with `ParsedQuery` application
4. Weapons page: swap `ViewerSearchBox` for `SmartSearchBar`
5. Manual smoke test on weapons page
6. Ships and hullmods: repeat steps 3–4 in a follow-up change (out of scope here)
