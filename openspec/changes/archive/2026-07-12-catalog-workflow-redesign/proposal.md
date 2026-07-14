# Catalog Workflow Redesign

## Problem

The Catalog page shows every mod as an equal card in a wall of ~1,000+ entries, and the most important user questions are either hidden or ambiguous:

1. **"Will it work with my game?"** — The card shows the required game version as a plain badge. TriOS knows the user's installed game version but never does the comparison for them.
2. **"Is this mod alive or abandoned?"** — No freshness signal on the card. A mod last touched in 2021 looks identical to one active last week.
3. **"How do I get it?"** — The install action is a 32px icon-only button whose color and icon encode seven states, including a surprising "click the checkmark to disable the mod." When an update exists, the button is blurred, which reads as broken.
4. **"Tell me more."** — Clicking a card does one of three different things (forum dialog, embedded browser, system browser) depending on a buried setting and whether cached forum HTML exists. There is no reliable "show me this mod" gesture.
5. **"I have updates."** — Nothing on the page says installed mods have updates. The user must open the filter panel and know to look for Status → Has Update.
6. **Multi-mod threads are invisible.** — Some forum threads contain several mods (e.g. the "Hartley's mods" thread holds 5). Only the thread's primary entry is searchable; downloads for all mods render as one flat, ambiguous button strip that mixes different mods with different hosts of the same mod.

## Solution

Redesign the Catalog around the priority order of user questions, promoting compatibility, freshness, updates, and a single obvious action — while keeping every power-user feature one layer down (context menu, details dialog, filter panel, overflow menu).

1. **Card redesign** — labeled Install/Update/Installed button, color-coded game-version badge (matches installed game vs. older), "active X ago" freshness line from forum thread activity, link icons demoted to menus, "+N more in this thread" hint for multi-mod threads.
2. **Unified details dialog** — clicking a card always opens a details dialog. Threads with cached forum HTML use the existing forum post dialog; others get a fallback built from scraped data with the same shape. Downloads are grouped: each mod in the thread gets a row with one split button (best link on click, other hosts/mirrors behind the dropdown). Dependencies shown under the main mod.
3. **Toolbar** — an "N updates available" pill that appears only when relevant and filters the grid on click; friendlier sort labels.
4. **Addon findability** — mods that live inside another mod's thread (LLM roles `addon`/`separate`) become their own searchable cards, marked as part of their thread.

## Scope

- `lib/catalog/` UI and controller code; no changes to data sources or scrapers.
- Settings: demote/replace the `CatalogCardClickAction` "clicking a mod opens..." setting.

## Non-goals

- Scraper-side update detection (`versionLastChangedAt` diffing, GitHub release-date enrichment). Deliberately deferred; the card's freshness signal is honestly labeled "active" (thread activity), not "updated," until the data source can provide real update timestamps.
- Client-side HTTP HEAD requests to guess file freshness.
- Changes to the embedded browser panel, data-sources dialog, AI summary modes, or filter engine.
- Compatibility claims about the user's *other mods* — the version badge only ever compares against the installed game version.

## Notes

All user-facing strings in this change are drafts and need explicit user sign-off before finalizing.
