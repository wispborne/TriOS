# AI summaries on catalog cards

**Depends on:** `parse-llm-forum-data`

## Problem

Catalog cards show the scraped summary or description, which is often missing
— many cards read "No description...yet!". The forum bundle now includes
AI-written summaries for 840 of 848 mods: a one-sentence version and a
one-paragraph version. They're uniform in tone but not author-written, so
whether to show them is a matter of taste.

## Solution

Show AI summaries on catalog cards, controlled by a new setting in the
catalog page's overflow menu with three options:

- **Always** — prefer the AI sentence over the scraped text.
- **Only when there's no author description** (default) — keep author text
  when it exists; fill the gaps with AI.
- **Never** — today's behavior.

When the AI sentence is shown, hovering the description shows the AI
paragraph. When AI text can't be shown (no llm data, or mode says no), the
card falls back exactly as today.

## Scope

- A persisted three-value setting, surfaced in the catalog overflow menu
  alongside the existing card-click-action options.
- Description selection + hover tooltip in the catalog card.

## Non-goals

- Any AI labeling/badging beyond the setting itself (can be added later if
  it feels misleading in practice).
- AI summaries anywhere other than catalog cards (mod info dialog, Mods page,
  forum dialog stay unchanged).
- Search — the search index keeps matching whatever text it matches today.
