# Tasks

## Models

- [x] Create `lib/catalog/models/forum_llm_data.dart` with `ForumLlmData`,
      `ForumLlmMod`, `ForumLlmDownload`, `ForumLlmExtras`, `ForumLlmSummary`,
      `ForumLlmChangelog`, and `ForumLlmSupportLink` as `@MappableClass`es,
      matching the field shapes in design.md.
- [x] Add `LlmModRole`, `LlmDownloadKind`, and `LlmDownloadConfidence`
      `@MappableEnum`s, each with an `unknown` decode fallback. Order the
      values by priority (e.g. `trios, direct, mirror, unknown` and
      `high, medium, low, unknown`) so enum index can drive sorting later.
- [x] Add the `mainMod` getter on `ForumLlmData` (first `role: main` entry,
      else first mod, null when empty).
- [x] Add `@MappableField(hook: ForumLlmDataHook())` `ForumLlmData? llm` to
      `ForumModIndex` in `lib/catalog/models/forum_mod_index.dart`.
      (Design originally said `SafeDecodeHook`, which turned out to be a
      no-op — see the note in design.md.)
- [x] Run `dart run build_runner build --delete-conflicting-outputs` to
      regenerate mappers.

## Tests

- [x] Add `test/forum_llm_data_test.dart` covering: a full entry (all fields),
      a minimal entry (no `llm` at all), an entry with unknown `role`/`kind`/
      `confidence` values (decodes to `unknown`), a malformed `llm` block
      (decodes to null via the hook), a changelog with `link` but no
      `entries`, and the `mainMod` getter with zero, one, and multiple `main`
      mods.

## Verify

- [x] `flutter test` passes (382 tests, including the 10 new ones).
- [x] `flutter analyze` is clean (no new issues from this change; the 470
      reported infos are all pre-existing, none in the changed files).
- [x] Launch the app with a fresh forum bundle and compare the "Parsed N forum
      mod entries in Xms" log line against the pre-change number — no
      meaningful regression. (Verified by user: same number of entries
      parsed, no regression.)
