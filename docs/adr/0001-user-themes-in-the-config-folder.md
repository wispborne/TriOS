# User themes live in the config folder, not the asset bundle

Built-in themes ship in `assets/themes.json`, which sits inside the install folder and is replaced wholesale every time the self-updater extracts a release over it. So user-written themes are kept in a separate `trios_themes-v1.json` under `getApplicationSupportDirectory()`, alongside the other settings files, where updates never reach. TriOS seeds that file once with a commented template and never writes to it again — the "Copy theme as JSON" button puts an entry on the clipboard for the user to paste — so hand-added comments and formatting survive, which they would not if TriOS rewrote the file through a JSON encoder.

## Considered Options

A user theme could have been an overlay that names a built-in and changes some of its fields. Rejected: a built-in tweaked in a later release would silently change the appearance of someone's theme, which reads as a bug rather than an improvement. User themes are standalone.

The user file could have been keyed by display name, matching `assets/themes.json`. Rejected: the selected theme is saved by its key, so renaming a theme would lose the selection — we hit exactly that renaming a built-in during development. User themes are keyed by a slug the author picks, saved as `user:<slug>`, with the display name a separate mutable field.

## Consequences

Built-in themes keep their display names as ids, so the two kinds of theme identify themselves differently. Changing built-ins to slugs would need a migration for every existing user's saved `themeKey`, and their current names are already a published identifier.

Nothing tells a user that renaming their slug loses their selection — that explanation was deliberately left out of the seeded file's comments to keep them short.
