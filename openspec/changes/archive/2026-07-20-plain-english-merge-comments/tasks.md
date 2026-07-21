# Tasks

Comments and two renames only. No executable line changes. After each file, a
quick glance at `git diff` should show comment lines (and, for three files, a
renamed symbol) and nothing else.

## The three heaviest files

- [x] `lib/utils/game_data_merge.dart`
  - [x] Rewrite the 22-line file header (L1–22) down to a few plain lines: what
        the file is, the two constraints (no disk I/O, no viewer model imports),
        and the decompiled-game reference. Drop "went badly", "so it can't pick
        the wrong one", the bold bullet lead-ins.
  - [x] Rename `_firstWins` → `_mergeFirstSourceWins` via replace-all; update
        its callers (`mergeById`, `mergeDescriptions`, `_mergeSpecs`).
  - [x] Rewrite the "Rule 2 / Rule 3 / Rule 4" banner comments as plain section
        headers without the narration.
  - [x] Rewrite the `_firstWins` doc plainly; keep the blank-key and
        duplicate-key facts.
  - [x] Rewrite `orderedSources` doc: keep the load-order fact and the
        tie-break difference; drop "Note the direction", "read this twice"-style
        framing.
  - [x] Rewrite `_deepMerge` doc: keep the rule (vanilla base, mods
        highest-priority first, last applied wins); drop "so read this twice" and
        the "Don't describe this as…" meta-paragraph.
  - [x] Rewrite `_replacesWholeList` doc, `_mergeSpecs` doc,
        and `_pathsInResolutionOrder` doc: keep the game references and
        deliberate-difference facts; drop "coin flip", "filesystem luck".
  - [x] Trim inline comments to one plain clause each. Fix "colour" → "color".
- [x] `lib/utils/log_collapser.dart`
  - [x] Trim the class doc to a plain summary plus one detail line.
  - [x] Simplify the `flush` doc example wording.
- [x] `lib/widgets/merge_provenance_view.dart`
  - [x] Rewrite the `mergeProvenanceView` doc to one plain summary plus a
        short note on the split-line case.

## Models

- [x] `lib/ship_viewer/models/ship.dart` — `spriteModVariant` and `provenance`
      docs trimmed.
- [x] `lib/weapon_viewer/models/weapon.dart` — `modVariant`, `spriteModVariant`,
      and `provenance` docs trimmed.
- [x] `lib/ship_viewer/models/ships_cache_payload.dart` — class doc and field
      docs rewritten plainly.
- [x] `lib/weapon_viewer/models/weapons_cache_payload.dart` — class doc and
      field docs rewritten plainly.

## Managers and the notifier

- [x] `lib/ship_viewer/ship_manager.dart`
  - [x] Rename `_shipsMemo` → `_lastMergedShips` via replace-all.
  - [x] Rewrite the memo doc, provider doc, `_shipAreaNames` doc, `_buildHull`
        doc, `_resolveSkins` doc, `progressiveYieldInterval` doc, and
        `_scanShipsFolder` doc.
- [x] `lib/weapon_viewer/weapons_manager.dart`
  - [x] Rename `_weaponsMemo` → `_lastMergedWeapons` via replace-all.
  - [x] Rewrite the memo doc, provider doc, `_weaponAreaNames` doc, the
        `type`-column inline, the nulls inline, `progressiveYieldInterval` doc,
        `_scanWeaponsFolder` doc, and the em-dash in the missile spec comment.
- [x] `lib/viewer_cache/cached_stream_list_notifier.dart` — trimmed `_sources`
      doc, `progressiveYieldInterval` doc, and `_flatten` doc.
- [x] `lib/descriptions/descriptions_manager.dart` — trimmed all three flagged
      docs.
- [x] `lib/faction_viewer/faction_manager.dart` — trimmed
      `progressiveYieldInterval` doc and the merge inline.
- [x] `lib/ship_viewer/engine_styles_manager.dart` — trimmed the provider doc
      and fixed "colour" → "color".
- [x] `lib/models/mod_info.dart` — shortened the `loadOrderKey` doc.

## Final read-through

- [x] Grep the changed files for the tells and confirm none remain: ` — ` (em-dash
      asides in new code), "on purpose", "read this twice", "every half second",
      "decides who wins", "colour", `_firstWins`, `_shipsMemo`, `_weaponsMemo`.
- [x] `flutter analyze` passes.
- [x] `flutter test` passes (507 tests).
