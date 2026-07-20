# Catalog Mod Summary Widget

## Problem

The catalog shows mod information in three different, inconsistent places:

- **Card hover**: only the description text has a tooltip (the AI paragraph, or plain overflow text). Hovering a card doesn't give a real overview of the mod.
- **Forum post dialog** and **catalog details dialog**: both use `ForumPostHeader`, which shows title, author, dates, and forum stats — but not the summary, mod image, changelog, support links, or save compatibility.

Meanwhile, QB's forum bundle now carries rich per-mod data that we parse (or could parse) but never show: extracted changelogs, support/donation links, and save compatibility. Save compatibility isn't even in our Dart model yet.

## Proposed Solution

Build one reusable "mod summary" widget that gathers everything we know about a mod and renders it in a consistent layout. Each field can be shown or hidden through a config object, so the same widget serves two roles:

1. **Card tooltip**: hovering a catalog mod card shows the summary widget as a framed tooltip (compact config).
2. **Modal header**: the forum post dialog and catalog details dialog use it as their header info block (fuller config). A new user setting can turn these dialog headers off.

Fields the widget can show:

- Mod title
- Mod image (scraped image → QB LLM image URL → none)
- Author info (name, avatar, forum title, post count when available)
- Where it's posted (forum board/category) and posted/edited dates
- Forum stats (views, replies)
- Summary text (author description or AI summary, honoring the existing AI-summary setting)
- Extracted changelog (from QB data; latest entries, plus external link when present)
- Support links (Patreon, Ko-fi, etc., from QB data)
- Save compatibility (from QB data — **new model field**)

## Scope

- New `saveCompatibility` field on `ForumLlmExtras` (exists in the raw QB bundle, not yet modeled).
- New summary widget + per-field config in `lib/catalog/widgets/`.
- Wire it as the catalog-mod-card hover tooltip.
- Use it as the info section of both mod dialogs, replacing the info portion of `ForumPostHeader` (window/browser buttons and download rows stay as they are).
- New setting to hide the dialog header summary, plus its Settings-page toggle.

## Non-Goals

- No per-field user settings — field visibility is configured in code per usage; the only user toggle is dialog headers on/off (the existing AI-summary mode setting still governs summary text).
- No changes to download resolution, grouping, or buttons.
- No changes to the forum post body rendering (HTML-to-widgets).
- No new scraper/bundle work — only consume what QB's bundle already has.

## Assumptions

- "Configurable" means a code-level config object (tooltip and header presets), not a user-facing per-field settings UI.
- Turning the header off leaves a slim bar with the title, window controls, and download rows, since those are functional, not informational.
