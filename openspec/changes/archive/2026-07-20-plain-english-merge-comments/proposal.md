# Rewrite the merge code's comments in plain English

## The problem

The mod-data-merge work landed with comments that don't read like the rest of
the codebase. They are essay-length, chatty, and full of tics that no other file
here uses:

- Em-dashes as asides where the repo uses parentheses or a period.
- Second person: "so read this twice", "the user… their game", "don't push a
  fresh one every half second".
- Editorializing and narration: "went badly", "so it can't pick the wrong one",
  "coin flip", "filesystem luck", "which hiding it wouldn't", "decides who wins".
- Running paragraphs where the repo uses a one-line summary.

The worst of it is in `lib/utils/game_data_merge.dart`, whose top comment runs
20-plus lines and whose private helper is named `_firstWins`. `log_collapser.dart`
and `merge_provenance_view.dart` are close behind. The manager and model files
each carry a few of the same over-written doc comments.

The code itself is fine. This is purely about the words.

## What the repo's comments actually look like

Short. Imperative. One line, sometimes two. They say what the code does or why in
a plain clause, use parentheses for asides, never address "you", and never
editorialize. Multi-line doc comments use `/// summary`, a blank `///`, then
`/// detail` — not a running paragraph. For example, from untouched files:

- `/// Handles scanning mod folders for portrait images`
- `// Strip \`#\` comments (quote-aware, multi-line safe) and track source lines.`
- `/// Tracks (originalHash:replacementHash) pairs that have already been warned about.`

## The solution

Rewrite the comments in the uncommitted merge files to match that style, and
rename the two symbols that read as jargon. No behaviour changes. Every line the
code runs stays exactly as it is; only comments and two names move.

The rename:

- `_firstWins` → `_mergeFirstSourceWins` (or similar plain name) in
  `game_data_merge.dart`.
- `_shipsMemo` / `_weaponsMemo` → a plainer name (e.g. `_lastMergedShips`).

The comment rewrite covers `game_data_merge.dart`, `log_collapser.dart`,
`merge_provenance_view.dart`, and the doc comments flagged in the managers and
models (descriptions, factions, engine styles, ship, weapon, and the two cache
payloads, the cached-stream notifier, and `mod_info.dart`).

## In scope

- Rewriting comments and doc comments in the uncommitted merge files to the
  repo's plain, short style.
- Renaming `_firstWins` and the `_*Memo` fields.
- A final read-through so no file still has em-dash asides, second person, or
  narration.

## Out of scope

- **Any behaviour change.** No logic, no control flow, no serialized shape.
- **Symbol renames beyond the two above.** The other new names
  (`orderedSources`, `MergeSource`, `mergeById`, `buildItemProvenance`, …) are
  already plain.
- **The OpenSpec planning docs** for `mod-data-merge-rules` (proposal, design,
  tasks). They are written in the same voice, but they're prose docs, not code,
  and rewriting them changes nothing that ships. Leave them unless asked.
- **The `viewer-cache` spec** edits, which read as normal spec language.
