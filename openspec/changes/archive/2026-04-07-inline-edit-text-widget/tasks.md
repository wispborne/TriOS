## 1. Create InlineEditText Widget

- [x] 1.1 Create `lib/widgets/inline_edit_text.dart` with the `InlineEditText` StatefulWidget
- [x] 1.2 Implement read-only mode: Row with label, value text (or placeholder) with dotted underline, and edit IconButton with tooltip
- [x] 1.3 Implement edit mode: TextField with confirm (check) and cancel (X) icon buttons
- [x] 1.4 Handle mode transitions: enter edit on icon/text click, confirm on Enter/check icon, cancel on Escape/X icon
- [x] 1.5 Match `SimpleDataRow` text styles (labelLarge, same font weights) for visual consistency

## 2. Update Mod Sources Dialog

- [x] 2.1 Replace `_editField` method usages in `_buildVersionCheckerSection` with `InlineEditText`
- [x] 2.2 Replace `_editField` method usages in `_buildCatalogSection` with `InlineEditText`
- [x] 2.3 Remove the now-unused `_editField` method

## 3. Verify

- [x] 3.1 Confirm dialog renders all fields in read-only mode by default and edit mode activates correctly
