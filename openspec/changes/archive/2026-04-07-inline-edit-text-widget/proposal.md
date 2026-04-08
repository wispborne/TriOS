## Why

The mod sources dialog currently shows all editable fields as always-visible TextFields with outlined borders. This makes the dialog visually noisy and hard to scan — users can't quickly distinguish read-only information from editable fields, and the wall of text inputs is overwhelming when most values are rarely edited.

## What Changes

- Replace always-visible TextFields with inline text that shows a small edit icon. Clicking the icon (or the text) toggles that field into an editable TextField.
- Create a reusable `EditableText` widget (or similar name) that encapsulates this read-then-edit pattern.
- Update the mod sources dialog to use the new widget for all editable fields (Version Checker and Catalog sections).

## Capabilities

### New Capabilities
- `inline-edit-widget`: A standalone Flutter widget that displays text in read-only mode with a small edit icon, and switches to a TextField on activation. Handles focus, commit, and cancel behavior.

### Modified Capabilities

(none)

## Impact

- New widget file in `lib/widgets/`
- `lib/mod_records/mod_record_sources_dialog.dart` — replace `_editField` usages with the new widget
- No API or data model changes
