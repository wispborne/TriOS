# Design

## Background

The bundle is fetched and cached by `forumDataFetcher`, and the index is parsed
in [forum_data_manager.dart:39](../../../lib/catalog/forum_data_manager.dart#L39)
by passing `decoded['index']` to `ForumDataBundleMapper.fromMap`. Unknown JSON
keys are dropped by dart_mappable, which is why the `llm` block is invisible
today. Parse time is already logged
([forum_data_manager.dart:45](../../../lib/catalog/forum_data_manager.dart#L45)),
so we can confirm the added cost is acceptable.

Verified shape of the data (July 7 bundle, checked across all 848 mods):

- `llm.mods[]` — `name` (always), `role` (always: main 797 / addon 49 /
  separate 2), `requires` (98, always a list of strings), `downloads` (always
  present, may be empty — 24 mods have zero links), `extras` (844).
- `downloads[]` — `url`, `label`, `kind`, `confidence`, `requiresManualStep`,
  `sourceHost` always present; `resolvedDirectUrl` (761/1070) and `fileName`
  (667/1070) optional.
- `extras` — all fields optional: `version` (703), `summary` (840, always an
  object with both `sentence` and `paragraph`), `changelog` (597, has
  `entries` map and/or `link` string), `license` (92, string),
  `supportLinks` (96, list of `{url, type}`; types seen: patreon, kofi,
  paypal, boosty, other).

## Key decisions

### 1. One new model file with the whole tree

New file `lib/catalog/models/forum_llm_data.dart`:

```
ForumLlmData          { List<ForumLlmMod> mods }
ForumLlmMod           { name, role, List<String>? requires,
                        List<ForumLlmDownload> downloads, ForumLlmExtras? extras }
ForumLlmDownload      { url, label, kind, confidence, requiresManualStep,
                        sourceHost?, resolvedDirectUrl?, fileName? }
ForumLlmExtras        { version?, ForumLlmSummary? summary,
                        ForumLlmChangelog? changelog, license?,
                        List<ForumLlmSupportLink>? supportLinks }
ForumLlmSummary       { sentence, paragraph }
ForumLlmChangelog     { Map<String, String>? entries, String? link }
ForumLlmSupportLink   { url, type }
```

All `@MappableClass`, following the existing model style in
[forum_mod_index.dart](../../../lib/catalog/models/forum_mod_index.dart).
`ForumLlmData` only models `mods` — the scraper's `isMod` flag is being
removed, and unknown keys are ignored anyway.

### 2. Enums with an `unknown` fallback, not raw strings

`role`, `kind`, and `confidence` become `@MappableEnum`s (`LlmModRole`,
`LlmDownloadKind`, `LlmDownloadConfidence`), each with an `unknown` value as
the decode fallback (dart_mappable's `defaultValue`). The downloads change
needs to *sort* by kind and confidence, which enum ordering gives us for free,
and a new scraper value degrades to `unknown` instead of failing the parse.

### 3. Defensive parse on the `llm` field

`ForumModIndex` gains:

```dart
@MappableField(hook: ForumLlmDataHook())
final ForumLlmData? llm;
```

`ForumLlmDataHook` decodes the block inside `beforeDecode` with a try/catch
returning null, following the `VersionHook` pattern
([dart_mappable_utils.dart](../../../lib/utils/dart_mappable_utils.dart)).
One malformed `llm` block costs that topic its LLM data instead of costing
the app the whole bundle.

*(Changed during implementation: the design originally named
`SafeDecodeHook`, but its try/catch wraps a plain `return value`, which can
never throw — the decode happens after the hook, so it protects nothing.)*

### 4. Main-mod getter on `ForumLlmData`

```dart
ForumLlmMod? get mainMod =>
    mods.firstWhereOrNull((m) => m.role == LlmModRole.main) ?? mods.firstOrNull;
```

Four topics have more than one `main` mod; "first main, else first" matches
post order, which puts the primary mod first in practice. Both follow-up
changes read this getter.

### 5. Parse where the index already parses

No manager changes. The `llm` block rides along in the existing
`decoded['index']` pass. It is mostly short strings (the heavy HTML lives in
`details`, which stays skipped), so the existing timing log is enough to
confirm no regression — no isolate or deferred parse unless the log says
otherwise.

## Files changed

- `lib/catalog/models/forum_llm_data.dart` — new models + enums (and its
  generated `.mapper.dart`).
- `lib/catalog/models/forum_mod_index.dart` — add the nullable `llm` field.
- `test/forum_llm_data_test.dart` — new parsing test.

## Risks / edge cases

- **Parse time.** The index parse runs on the UI isolate. Expected cost is
  small relative to the 14 MB `jsonDecode` that already happens; verify via
  the existing log line before/after.
- **Scraper drift.** New enum values → `unknown` (decision 2); malformed
  blocks → null (decision 3); removed `isMod` → never modeled.
- **Old cached bundles.** Entries without `llm` simply have `llm == null`;
  all consumers must treat that as "no data" (183 topics lack it even in the
  new bundle).
