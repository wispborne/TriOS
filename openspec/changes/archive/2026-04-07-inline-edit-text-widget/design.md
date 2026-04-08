## Context

The mod sources dialog (`mod_record_sources_dialog.dart`) currently renders editable fields using a private `_editField` method that creates `TextField` widgets with `OutlineInputBorder`. All 12 editable fields are always in edit mode, making the dialog look like a form rather than an information display. Read-only fields use `SimpleDataRow` (a `SelectableText.rich` widget), creating a visual mismatch between editable and non-editable rows.

## Goals / Non-Goals

**Goals:**
- Create a reusable `InlineEditText` widget that shows text in read-only mode and switches to a TextField on user action
- Make the mod sources dialog easier to scan by defaulting to a readable text display
- Maintain all existing edit/save functionality

**Non-Goals:**
- Changing the data model, save logic, or override diffing
- Adding inline validation or field-specific formatting
- Changing non-editable fields (Identity, Installed, Download History sections)

## Decisions

### 1. New standalone widget: `InlineEditText`

**Location**: `lib/widgets/inline_edit_text.dart`

**Approach**: A `StatefulWidget` that manages its own editing state. In read mode, it displays a `Row` with:
- Label text (light weight, matching `SimpleDataRow` style)
- Value text (bold, matching `SimpleDataRow` style) with a dotted underline to hint editability — or a placeholder like "(empty)" if blank, also with dotted underline
- A small edit `IconButton` (pencil icon, size 16) at the end

Clicking the edit icon switches to a `TextField` pre-filled with the current value. The TextField includes a small check icon to confirm and X icon to cancel, or the user can press Enter to confirm / Escape to cancel.

**Why not extend SimpleDataRow**: `SimpleDataRow` is a simple `SelectableText.rich` — it has no state or controller management. Composition is cleaner than inheritance here.

**API**:
```dart
InlineEditText({
  required String label,
  required TextEditingController controller,
  String placeholder = '(empty)',
  VoidCallback? onChanged,
})
```

Using the existing `TextEditingController` from the parent means no change to the save logic — the parent still reads controllers on save. The `onChanged` callback lets the dialog call `_markDirty()`.

### 2. Dotted underline affordance

The value text in read mode has a dotted underline (using `TextDecoration.underline` with `TextDecorationStyle.dotted`) to signal that the field is editable. This differentiates it from plain `SimpleDataRow` fields that are truly read-only, without being as heavy as a full TextField border.

### 3. Read-mode visual alignment with SimpleDataRow

The read mode should use the same `labelLarge` text style and weight conventions as `SimpleDataRow` so editable and non-editable rows look visually consistent.

### 4. Edit-mode activation

The edit icon and the value text area are both tappable to enter edit mode. This provides a larger hit target. The label text is not tappable (keeps it clear which part is the value).

## Risks / Trade-offs

- **More taps to edit**: Users must click to edit each field instead of all fields being immediately editable. This is an acceptable tradeoff since these fields are rarely edited; readability is the priority.
- **Focus management**: Switching between read/edit mode requires careful focus handling to avoid jarring UX. Mitigation: auto-focus the TextField when entering edit mode, and return to read mode on blur (unfocus).
