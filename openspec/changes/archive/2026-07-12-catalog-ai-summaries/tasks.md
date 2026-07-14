# Tasks

## Setting

- [x] Create `lib/catalog/models/ai_summary_mode.dart` with the
      `AiSummaryMode` `@MappableEnum` (`always`, `whenNoAuthorText`, `never`)
      plus `label`/`icon` getters.
- [x] Add `AiSummaryMode catalogAiSummaryMode` to `Settings` with default
      `whenNoAuthorText`.
- [x] Run `dart run build_runner build --delete-conflicting-outputs`.
- [x] Add a "Show AI mod summaries" section to `buildCatalogOverflowButton`
      with three check items, mirroring the card-click-action section.

## Card rendering

- [x] In `buildDescription`, pick the text per mode (see design.md decision 2),
      watching `appSettings.select((s) => s.catalogAiSummaryMode)`.
- [x] When the AI sentence is displayed, make the hover tooltip show the AI
      paragraph; keep today's overflow-tooltip behavior for author text.

## Verify

- [x] Mode "Only when the author didn't write one" (default): cards with
      author text look unchanged; former "No description...yet!" cards now
      show an AI sentence.
- [x] Mode "Always show": cards with both prefer the AI sentence; hover shows
      the AI paragraph.
- [x] Mode "Never show": identical to pre-change behavior everywhere.
- [x] Mod with no forum/llm data shows author text or the placeholder in all
      three modes.
- [x] Switching the mode in the overflow menu updates cards immediately and
      persists across app restarts.
- [x] `flutter analyze` is clean (no new issues from this change).
- [x] User sign-off on the menu strings — chose header "Show AI mod summaries"
      with options "Always" / "Only if missing" / "Never".
