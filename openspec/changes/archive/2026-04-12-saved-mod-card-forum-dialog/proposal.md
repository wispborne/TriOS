## Why

Clicking a mod card in the catalog currently opens the mod's forum page in an external browser, taking the user out of TriOS and requiring a full page load for every browse. QB's Forum Bundle already ships the full HTML of every mod's forum post, so we can show mod details instantly inside TriOS without leaving the app or launching a browser.

## What Changes

- Change `ScrapedModCard`'s primary click action: instead of opening the forum website URL, open an in-app **Forum Post Dialog** that displays the mod's forum post content.
- Extend forum data loading to also parse the `details` section of `forum-data-bundle.json` (currently skipped for size reasons). Each entry is a rich object keyed by `topicId` containing `contentHtml`, `title`, `author`, `authorTitle`, `authorPostCount`, `authorAvatarPath`, `postDate`, `lastEditDate`, `category`, `gameVersion`, `images`, `links`, `scrapedAt`, and `isPlaceholderDetail`. Add a `ForumModDetails` mappable model and a Riverpod provider that exposes these by `topicId`.
- Add a native Flutter HTML-to-widget renderer (no `WebView`, no external browser). It parses `contentHtml` with the existing `html` package and maps the SMF BBC-style element subset actually used in the bundle to native Flutter widgets styled with the current TriOS theme. Supported: `<br>`, `<div>` (incl. `align="center"`), `<span>` (with `bbc_size`, `bbc_color`, `bbc_u`, `bbc_font` and inline `font-size`/`color`/`font-family`/`text-align`), `<strong>`/`<b>`, `<em>`/`<i>`, `<img class="bbc_img">`, `<a class="bbc_link">`, `<ul>`/`<ol>`/`<li>`, `<hr>`, `<table>`/`<tr>`/`<td>`/`<tbody>`, `<del>`/`<s>`, `<sub>`, `<sup>`, `<tt>`/`<code>`/`<pre>` (hljs syntax-highlight spans preserved as plain monospace), `<blockquote>`. Spoiler blocks (`<div class="sp-wrap">` … `<div class="sp-head">Spoiler</div><div class="sp-body folded">` …) render as collapsible sections. `<iframe>` (mostly YouTube) renders as a tappable placeholder linking to the embedded URL. `<marquee>` degrades to plain text. `<script>`/`<style>` are dropped.
- Add a **Forum Post Dialog** widget that shows the rendered post. Its header bar displays mod title, author (with avatar if available), post date, last-edit date, and forum stats (views and replies) pulled from the matching `ForumModIndex`. Actions: "Open in Browser" (routes `topicUrl` through the existing link loader) and close.
- Fall back to the previous behavior (open direct-download dialog or website) when no forum HTML is available for a mod.
- Direct-download behavior for mods without a forum URL is unchanged.

## Capabilities

### New Capabilities
- `forum-post-dialog`: In-app dialog that renders a mod's forum post HTML as native Flutter widgets when a catalog mod card is clicked.

### Modified Capabilities
- `forum-data-fetching`: Bundle parsing must now also decode the `details` section (per-topic HTML), exposed via a lookup provider, without forcing it to load eagerly on every browse.

## Impact

- Affected code:
  - `lib/catalog/scraped_mod_card.dart` — click handler redirected to new dialog.
  - `lib/catalog/forum_data_manager.dart` — parse and expose `details` (rich model by topicId) on demand.
  - `lib/catalog/models/forum_data_bundle.dart` — remains unchanged (keeps stripping `details` from the hot path).
  - New file `lib/catalog/models/forum_mod_details.dart` — `@MappableClass` for the per-topic rich detail record.
  - New files under `lib/catalog/forum_post_dialog/` for the dialog and the HTML-to-widget renderer.
- Dependencies: reuses existing `html: ^0.15.6`. No new packages required.
- Performance: `details` is ~13MB of HTML; it must be parsed lazily / on demand (not blocking the catalog list) to keep the catalog responsive.
- UX: clicking a card no longer leaves TriOS by default; the "open in browser" action remains available via the existing browser icon and as a dialog action.
