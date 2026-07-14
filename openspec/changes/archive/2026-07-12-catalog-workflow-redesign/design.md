# Design — Catalog Workflow Redesign

## Overview

Four slices, each independently shippable, in this order:

1. Card redesign (`scraped_mod_card.dart`)
2. Unified details dialog + grouped downloads (`scraped_mod_card.dart`, `forum_post_dialog/`, new fallback dialog)
3. Toolbar: updates pill + sort labels (`mod_browser_page.dart`, `catalog_search.dart`, controller)
4. Addon findability (controller, `scraped_mod.dart`, card)

No data-source or scraper changes. All new user-facing strings are drafts pending user sign-off.

## Slice 1 — Card redesign

### 1a. Labeled install button

Replace `CatalogDownloadButton`'s 32px `FloatingActionButton.small` with a compact labeled button (`DenseButton`-style, fits the 140px card). New state → label mapping:

| State | Label | Behavior |
|---|---|---|
| Not installed, one-click candidate | `Install` | Run primary candidate (unchanged logic) |
| Not installed, browser-only link | `Get` (opens page) | Open browser link |
| Update available | `Update` | Run primary candidate / open page |
| Installed (enabled or disabled) | `Installed ✓` | **No action on click** (non-interactive status marker); **no longer toggles enable/disable** |
| No link | disabled `Install` | Tooltip "No download available" |

Decided labels (user sign-off): `Install` (one-click), `Get` (browser-only link, opens page), `Update`, `Installed ✓` (inert status). `Installed ✓` clicking does nothing; enable/disable lives only in the context menu.

- The enable/disable toggle moves to the card's context menu (`Enable` / `Disable` entries shown only when installed).
- Remove the `Blur` wrapper on the update state entirely (both on the button and the left status strip).
- The multi-candidate tie chooser keeps its `MenuAnchor`, now anchored to the labeled button.
- Keep the existing `_resolveState` state machine; only presentation and the installed-click behavior change.

### 1b. Color-coded game-version badge

`_ScrapedModGameVersionReq` compares `mod.gameVersionReq` against the installed game version from `AppState.starsectorVersion` (FutureProvider<String?>; widget becomes a `ConsumerWidget`).

- **Match** (same version bucket): standout positive color (theme `statusColors.success` tint on border/text).
- **Mismatch / older**: muted warning tint.
- **Unknown** (no installed version detected, or mod has no requirement): current neutral styling.

Matching uses the same version-bucket normalization the Game Version filter already uses (`extractVersionGroups` in `lib/utils/catalog_search.dart`) so "0.98a-RC8" matches a mod that says "0.98a". Extract a small shared helper rather than duplicating the bucketing rules.

Tooltip stays factual: "Game version required: X" plus a line "Your game: Y" — it must never claim compatibility with the user's other mods.

### 1c. Freshness chip (revised: compact, single footer line)

The card was overcrowded with freshness and the thread hint as their own rows, so all secondary metadata collapses into **one footer line**: `👁 1.2M · 💬 253 · 🕐 3mo · ⧉ +4` (views, replies, age, multi-mod chip). The line sits in a `FittedBox` so it scales down slightly on narrow cards instead of wrapping or overflowing.

- Age chip: icon + very short age ("3h", "6d", "2mo", "3y") from `ForumModIndex.lastPostDate`.
- The tooltip carries the honest wording: "Last forum post: <date>" — thread activity, deliberately not "updated"; mods can update without the post changing.
- When `lastPostDate` is older than ~1 year, the age chip renders dimmed so abandonment is visible at a glance.
- Hidden when there is no forum index entry / no date.

### 1d. Demote link icons

Remove the `BrowserIcon` / `DiscordIcon` / `NexusModsIcon` column from the card. The same links move to:

- The card context menu (new "Links" section: Forum, Discord, NexusMods — only entries that exist).
- The details dialog header (slice 2).

The Discord right-click-to-copy affordance becomes a context-menu entry ("Copy Discord link").

### 1e. Multi-mod thread hint (revised: chip in the footer line)

When `forumModIndex.llm.mods` contains more than one entry, the footer line (1c) gets a `⧉ +N` chip; the tooltip reads "This forum thread has N mods. Click the card to see them all." (Originally a full "+N more in this thread" row — merged into the footer to fix card overcrowding.) The card's install button always targets the **main mod only** (`llm.mainMod`, existing behavior).

## Slice 2 — Unified details dialog

### Click behavior

Card click **always** opens a details dialog:

- Cached forum HTML available (`forumDetailsForTopic`) → existing `showForumPostDialog` (unchanged body rendering).
- No cached HTML → new fallback dialog built from scraped data: same dialog shell, header, and download strip; body shows the mod image (with existing fallback), full `description` (or `summary`), and the AI paragraph summary when present (respecting `AiSummaryMode`, with the existing AI attribution notice).

`CatalogCardClickAction` is retired as a click dispatcher:

- Remove the "Clicking a mod opens..." section from the catalog overflow menu.
- `_dispatchCardLink` no longer routes card-body clicks; it remains (simplified) as the handler for explicit "open in embedded browser" requests from the dialog/context menu.
- The settings field stays in `Settings` (marked `@Deprecated` comment) to avoid a settings migration in this change; actual removal is a later cleanup.

"Open in embedded browser" and "Open in system browser" become explicit secondary actions: icon buttons in the dialog header and entries in the card context menu.

### Grouped downloads ("mods get rows, hosts get a split button")

Restructure the header download strip (`ForumPostHeader.downloads`) from a flat candidate list into per-mod rows:

```
Downloads
<Main mod name>                 [ ⬇ Install ▾ ]
    needs LazyLib ✓ · MagicLib (installed with it)
Also in this thread:
<Addon name>   (addon)          [ ⬇ Install ▾ ]
<Separate name> (separate)      [ ⬇ Install ▾ ]
```

- One row per `ForumLlmMod` in `llm.mods`. Order: `main`, then `addon`, then `separate`, then `unknown` last.
- Each row has **one split button**: main click runs the best candidate for that mod (existing `primaryCandidate` ranking: trios > direct > mirror, then confidence); the `▾` opens a menu listing all of that mod's candidates with host names (`sourceHost`) and a marker on low-confidence links. Mirrors appear **only** inside the menu, never as top-level buttons.
- If a mod's candidates are all manual-step (`requiresManualStep`), the button label becomes `Open download page` and the click opens the link instead of downloading.
- Dependencies line under the main mod's row, from `llm requires`: each dependency rendered as `✓` when installed (lookup via the controller's status map / installed mod names) or `(installed with it)` when the primary candidate is a TriOS deep link that handles deps.
- Fallback when the topic has no LLM data: the current scraped-links path (`details.links` where `isDownloadable`) renders as a single unnamed group — one row, split button over the scraped candidates.
- The header changes apply to both the forum-HTML dialog and the new fallback dialog (shared header widget; the fallback constructs the same inputs from `ScrapedMod` + `ForumModIndex`).

## Slice 3 — Toolbar

### Updates pill

- Computed in `CatalogPageController`: count of catalog entries whose `CatalogEntryStatus.versionCheck?.hasUpdate == true`.
- Rendered in the toolbar row only when count > 0: a pill (e.g. `⬆ 3 updates`) using the theme's primary/update color.
- Click: activates the existing Status → `hasUpdate` bool filter (the `BoolField('hasUpdate')` in the `status` composite group) and opens the filter panel if closed, so the state is visible and reversible through normal filter UI. Clicking again (or clearing filters) restores the previous view.

### Sort labels

Rename `CatalogSortKey` labels only (enum values and sort logic unchanged):

| Key | Old label | New label (draft) |
|---|---|---|
| name | Name | Name |
| date | Date Added | Newest |
| version | Game Version | Game Version |
| mostViewed | Forum Views | Popular |
| mostReplies | Forum Replies | Most Discussed |
| lastActivity | Last Forum Activity | Recently Active |

## Slice 4 — Addon findability

Goal: mods that only exist inside another mod's thread (e.g. the "Hartley's mods" thread with 5 mods) are searchable cards of their own.

### Synthesis

In `CatalogPageController.build` (or a derived provider it watches), after loading `allMods` and the forum lookup:

- For each `ScrapedMod` with a forum topic whose `llm.mods` has entries beyond `mainMod`, synthesize one entry per non-main `ForumLlmMod` (roles `addon`, `separate`, and `unknown` beyond the first).
- **Dedupe**: skip synthesis when a real catalog entry with the same normalized name (lowercase, trimmed) already exists.
- Field mapping for the synthesized `ScrapedMod`: name from the LLM mod name; summary/description from `extras.summary`; `gameVersionReq` from the thread's `ForumModIndex.gameVersion`; authors and urls (Forum) from the parent entry; no images (existing fallback image renders); no categories.
- Add a nullable, non-serialized-in-practice field to `ScrapedMod` (e.g. `String? partOfThreadTitle`) to mark synthesized entries and carry the parent thread title. Requires `build_runner` regen. Absent from repo JSON, so parsing is unaffected.

### Behavior of addon cards

- Card shows `part of <thread title>` where the authors line normally sits (or appended to it).
- Install button resolves candidates from **that** LLM mod's `downloads` (pass the specific `ForumLlmMod` instead of `llm.mainMod` into `resolveDownloadCandidates`).
- Card click opens the **thread's** details dialog (same dialog as the parent entry, where the grouped rows from slice 2 make the specific addon findable).
- Installed status works automatically through the existing name-keyed status map when names align.
- Search (`searchScrapedMods`), filters, and sorting operate on the combined list with no changes; forum-stat sorts use the thread's stats.

## Key decisions

1. **"Active", not "updated"** — honest labeling until data sources can provide `versionLastChangedAt` (deferred scraper work).
2. **Badge coloring over a new compat chip** — reuse the existing badge; color communicates the verdict; wording never implies mod-list compatibility.
3. **Enable/disable leaves the primary button** — the catalog is for acquiring mods; managing them belongs to the Mods page and the context menu.
4. **`CatalogCardClickAction` deprecated in place** — no settings migration in this change.
5. **Synthesized addons extend `ScrapedMod`** rather than introducing a wrapper view-model — keeps `WispAdaptiveGridView`, search, filter engine, and sort signatures untouched.

## Risks

- Name-based join (`statusForModName`) is fuzzy; synthesized addon names come from LLM extraction and may not match installed `mod_info` names — install status on addon cards may miss. Acceptable; identical to today's failure mode for regular entries.
- Version-bucket matching for the badge must agree with the filter's bucketing or users will see contradictory signals — hence the shared helper.
- `ScrapedMod` model change requires `dart run build_runner build --delete-conflicting-outputs`.
