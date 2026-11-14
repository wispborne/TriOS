# Stop reading the old catalog format

Status: needs-triage

This is a todo for later. Don't start it until the conditions under "When to do this" are met.

## Problem

The scraper changed the format of two catalog files:

- `mod-catalog-details.json`: each AI answer's fields now sit in nested objects (`release`, `saveCompat`, `requirements`, `sourceCode`, `description`) instead of one `extras` object. Some fields were renamed (`requires` → `parentMod`, `image` → `imageUrl`, `isTool` → `types`, a download's `kind` → `type`).
- `mod-catalog-extras.json`: schema 1 became schema 2 (`requirements`, `types`, `saveCompat`, and an `updateNote` on each release).

TriOS now reads the new format. It also converts the old format as files load, because the live files on GitHub were still old when TriOS was changed, and installs may have old copies cached. Once nothing serves the old format, that conversion code is dead weight and should go.

## When to do this

All of these must be true:

1. The scraper has published the new format to StarsectorModRepo. The details file has `meta.llmFormat: 2`. The extras file has `schemaVersion: 2`.
2. A TriOS release that reads the new format has been out long enough that no install still has an old copy of either file cached.

## In scope

- Remove the old-format conversion for the details file and the extras file.
- Remove or rewrite the tests that feed old-format data.
- Make TriOS ignore an extras file older than schema 2, the same way it ignores a schema newer than it knows.

## Out of scope

- `ModRepo.json` and `forum-data-bundle.json`. TriOS 1.7.0 and older read those, and the scraper keeps them in the old format on purpose.
- Reading fields TriOS doesn't use yet (a conflict's `type`, a requirement's `oneOf`).
