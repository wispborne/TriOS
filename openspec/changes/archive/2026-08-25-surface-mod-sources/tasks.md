# Tasks: Surface mod sources

- [x] Add a typed accessor on `ModRecord` for the resolved "downloaded from" URL, if one doesn't exist.
- [x] Make the Download History section of the Mod Sources dialog editable: URL field backed by a `DownloadHistorySource` override, saved only when it differs from the automatic value. Timestamp stays read-only.
- [x] Rework the mod details dialog's link buttons to read URLs from the resolved `ModRecord` instead of raw version-checker/catalog data.
- [x] Add a "Downloaded from" link button to the mod details dialog, with a tooltip.
- [x] Move "Mod Sources…" from the Troubleshoot submenu to the top level of the mod right-click menu.
- [x] Confirm an override typed in the dialog shows up on the details dialog's buttons, and that clearing an override falls back to the automatic value.
