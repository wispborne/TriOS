# Design

## Keep the facts, cut the theatrics

Some of these comments carry real information: the decompiled game rules, file and
line references like `LoadingUtils.java:384-390`, the deliberate differences from
the game, the reason a value isn't serialized. Keep all of that. The job is to say
the same thing in fewer, plainer words — not to delete the substance.

What to cut: the drama and the hand-holding. "so read this twice", "went badly",
"coin flip", "filesystem luck", "which hiding it wouldn't", "decides who wins",
"every half second". What to keep: the rule, the game reference, the one-line
reason.

## Style rules to apply

1. **One-line summary first.** A doc comment opens with a single plain clause. If
   there's more, blank `///`, then the detail — don't run it into a paragraph.
2. **No em-dash asides.** Use a period or parentheses, matching the repo.
3. **No second person.** Not "you", not "the user… their game". State the fact.
4. **No narration or editorializing.** Drop "on purpose", "went badly", "so it
   can't pick the wrong one", "read this twice". If a choice needs a reason, give
   the reason in a clause, not a story.
5. **Trim length.** A 20-line file header becomes a few lines. A five-sentence
   field doc becomes one or two.
6. **Spelling matches the repo:** "color", not "colour".

## The renames

Use the IDE rename refactor so call sites update in one move; both symbols are
private, so the blast radius is one file each.

- `_firstWins` (in `game_data_merge.dart`) → a plain name. It's the CSV / spreadsheet
  merge where the first source to claim a key keeps it. Suggested:
  `_mergeFirstSourceWins`. The section header comment above it ("Rule 2:
  spreadsheet rows — the first source to claim a key wins") also gets rewritten.
- `_shipsMemo` / `_weaponsMemo` (fields caching the last merge result) → e.g.
  `_lastMergedShips` / `_lastMergedWeapons`.

## Worked examples

`game_data_merge.dart`, current file header (22 lines) — trim to the essentials:
what the file is (the one place merge rules live), the two constraints (no disk
I/O, no viewer models), and the game-source reference. Drop "went badly", "so it
can't pick the wrong one", the bullet styling with bold lead-ins.

`_firstWins` doc, current:
> The spreadsheet rule. Sources are walked in the order given; the first to
> claim a key keeps it.

becomes something like:
> Merges rows keyed by `keyOf`. The first source in order to supply a key keeps
> it; later copies are dropped. Blank keys are skipped (vanilla uses blank rows
> as spacers). A duplicate key within one source keeps the first and warns.

`_deepMerge` doc, current — opens with "**The direction is the opposite of the
spreadsheet rule, and the two live in the same file, so read this twice.**" and a
"Don't describe this as…" paragraph. Keep the actual rule (vanilla is the base,
mods apply highest-priority first, last applied wins a value) in plain sentences.
Drop the "read this twice" framing and the meta-note about how not to describe it.

## Verification

- `flutter analyze` — comments and private renames can't change analysis output,
  so this only confirms nothing was mistyped.
- `git diff` shows only comment lines and the two renamed symbols. No change to
  any executable line. This is the real check.
