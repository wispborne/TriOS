## Context

TriOS shows mods in the catalog via `ScrapedModCard` (`lib/catalog/scraped_mod_card.dart`). Clicking a card currently calls `linkLoader(websiteUrl)`, which opens the forum URL in the user's external browser. For every mod, users bounce out of TriOS and wait for the forum to load.

QB already scrapes and publishes a combined JSON bundle (`forum-data-bundle.json`, ~16MB) that contains, per mod:
- `index` — lightweight metadata (title, author, stats), already parsed and used in TriOS.
- `details` — **a map keyed by `topicId` (as string)** whose values are rich objects, not raw HTML. Each entry has: `topicId`, `title`, `category`, `gameVersion`, `author`, `authorTitle`, `authorPostCount`, `authorAvatarPath`, `postDate`, `lastEditDate`, `contentHtml` (the actual post body), `images` (pre-extracted list), `links` (pre-extracted list), `scrapedAt`, `isPlaceholderDetail`. 881 entries in the current bundle.
- `assumedDownloads` — unrelated to this change.

### HTML profile (from real bundle inspection)

The forum software is SMF, so `contentHtml` uses its BBC-output conventions. Across all 881 entries:

- **Structural / text**: `<br>` (107k), `<div>` (18k, sometimes with `align="center"`), `<span>` (14k), `<strong>` (13k), `<a>` (5k), `<li>` (5k), `<em>` (2.5k), `<ul>` (1k), `<hr>` (889), `<blockquote>` (126), `<pre>` (93), `<code>` (88)
- **Tables**: `<table>` (387) / `<tbody>` / `<tr>` (872) / `<td>` (1583), typically `class="bbc_table"`
- **Media**: `<img class="bbc_img">` (8k), `<iframe>` (118, mostly YouTube embeds)
- **Less common**: `<del>`, `<sub>`, `<sup>`, `<tt>`, `<marquee>` (14 — rare but real)
- **Class conventions**: `bbc_img`, `bbc_link`, `bbc_size` (paired with inline `style="font-size: Npt"`), `bbc_color` (paired with inline `style="color: #..."`), `bbc_u` (underline), `bbc_font` (paired with inline `font-family`), `bbc_list`, `bbc_table`
- **Inline style properties actually used**: `font-size` (4.5k), `color` (1.9k), `font-family` (348), `cursor`, `text-align`, `text-shadow`, `list-style-type`
- **Spoiler blocks** (3274 instances, extremely common): nested structure

      <div class="sp-wrap sp-wrap-default">
        <div class="sp-head">Spoiler</div>
        <div class="sp-body folded">…content… <div class="sp-foot">[close]</div></div>
      </div>

  The `folded` class means the content is collapsed by default on the forum.
- **Syntax-highlighted code**: `<pre><code>` bodies contain `<span class="hljs-keyword">`, `hljs-string`, `hljs-number`, `hljs-comment`, etc. from highlight.js.
- **Many image/download URLs are `http://`** (legacy) — must be handled without crashing on mixed-content restrictions.

`ForumDataBundle` (`lib/catalog/models/forum_data_bundle.dart`) currently skips `details` entirely to avoid the size hit. `forum_data_manager.dart` strips `details` and `assumedDownloads` before handing the JSON to the mapper.

We now want to display that HTML inside TriOS as styled Flutter widgets instead of navigating to the browser.

## Goals / Non-Goals

**Goals:**
- Replace the default click on a `ScrapedModCard` with an in-app dialog that renders the mod's forum post.
- Parse forum post HTML into native Flutter widgets (no WebView, no external renderer).
- Keep the catalog list responsive — do not force the full `details` map to parse synchronously on the main UI path if we can defer it.
- Preserve fallback to existing behavior (browser / direct download) when HTML is unavailable.
- Support the exact element/class subset actually produced by SMF BBC output (see HTML profile above): text with bold/italic/underline/strike/sub/sup, `<br>`/`<div>`/`<hr>`, SMF `bbc_size`/`bbc_color`/`bbc_u`/`bbc_font` styling, links, images, lists, blockquotes, `<pre>`/`<code>` with hljs spans preserved as monospace, simple `bbc_table`s, collapsible **spoiler blocks**, and YouTube iframe placeholders.
- Header bar in the dialog shows: mod title, author (avatar if available), post date, last-edit date, and the forum stats (views / replies) from the matching `ForumModIndex`.

**Non-Goals:**
- Rendering arbitrary/complex HTML, JavaScript, CSS, or BBCode directly.
- Editing or posting back to the forum.
- Offline image caching beyond what the existing image widgets already do.
- Perfectly matching the forum's visual layout — TriOS theme styling is preferred.
- Changing how the catalog grid or browser icon behaves.
- Per-line syntax highlighting inside `<pre><code>` — hljs spans are flattened to plain monospace text (their text content is preserved).
- "Next / previous mod" navigation inside the dialog.
- Embedding actual YouTube players — iframes render as a tappable placeholder that opens the embed URL externally.

## Decisions

### D1: Render HTML with native widgets via `package:html`, not `flutter_html` / `WebView`
`package:html` (already a dep) gives us a DOM to walk. We build a small visitor that emits `InlineSpan`s for text-level nodes (wrapped in `RichText` / `Text.rich`) and block widgets (`Column` children) for structural nodes.

**Alternatives considered:**
- `flutter_html` — heavy, pulls in several transitive deps, theme integration is awkward, and the user explicitly said "don't use a browser to render".
- `WebView` / `webview_flutter` — the user explicitly excluded this.
- Convert HTML → Markdown → `flutter_markdown` — lossy for things like inline images in lists, and adds a dep.

### D2: Parse `details` lazily into a typed model, not as part of the main bundle stream
The existing `forumDataProvider` intentionally strips `details` before mapping to keep the hot path small. We keep that behavior and add a **separate** provider that parses `details` on demand.

Because each `details` entry is a rich object (not just HTML), we introduce a proper model:

```dart
@MappableClass()
class ForumModDetails with ForumModDetailsMappable {
  final int topicId;
  final String title;
  final String? category;
  final String? gameVersion;
  final String author;
  final String? authorTitle;
  final int? authorPostCount;
  final String? authorAvatarPath;
  @MappableField(hook: ForumDateHook())
  final DateTime? postDate;
  @MappableField(hook: ForumDateHook())
  final DateTime? lastEditDate;
  final String contentHtml;
  final List<String>? images;
  final List<String>? links;
  final DateTime? scrapedAt;
  final bool isPlaceholderDetail;
  // ... constructor
}
```

`ForumDateHook` already exists in `forum_mod_index.dart` and handles the SMF date format — reuse it.

Approach for the provider:
- The raw bundle JSON is already cached on disk by `CachedJsonFetcher`. Add a `FutureProvider<Map<int, ForumModDetails>> forumDetailsByTopicId` that:
  1. Reads the cached JSON from `forumDataFetcher`.
  2. In a `compute()` isolate: `jsonDecode` the file, extract just the `details` object, walk its entries, map each through `ForumModDetailsMapper.fromMap`, and return a `Map<int, ForumModDetails>` keyed by `topicId` (int, not the JSON string key).
  3. The resulting map is cached for the app lifetime.
- Expose a thin `Provider.family<ForumModDetails?, int>` that reads from the resolved map.

**Alternatives considered:**
- Parsing `details` eagerly in `forumDataProvider` — rejected; slows catalog startup for users who never open the dialog.
- Per-topic re-read of the cache file — rejected for now; simpler to hold the parsed map once. Can revisit if memory is a problem.
- Treating `details` values as raw HTML strings only — rejected; we'd throw away the pre-extracted author/date/avatar metadata that makes the dialog header useful.

### D3: New capability `forum-post-dialog` for the dialog + HTML renderer
The dialog and HTML-to-widget renderer are tightly coupled and reused only inside this feature, so they live together under `lib/catalog/forum_post_dialog/`:

- `forum_post_dialog.dart` — the `showForumPostDialog(context, {required ForumModDetails details, ForumModIndex? index, required void Function(String) linkLoader})` entry point and dialog shell.
- `forum_post_header.dart` — the header bar widget: title, author row (avatar, author name, author title, post count), post date / last-edit date, and a compact stats row (views, replies) pulled from `ForumModIndex` when available. Styled against the current `ThemeData`.
- `html_to_widgets.dart` — pure function `List<Widget> htmlToWidgets(String html, BuildContext context, {required void Function(String) onLinkTap, String? baseUrl})`. Uses `parse` from `package:html`, walks the DOM, emits widgets keyed to the current `ThemeData`.
- `inline_span_builder.dart` — helper that walks inline descendants and produces `TextSpan` trees for `Text.rich`, preserving bold/italic/underline/strike/sub/sup/link styles and SMF class-driven styling (see D5).
- `spoiler_block.dart` — a small stateful widget that renders a spoiler block with a tap-to-expand header. Starts collapsed to match the forum's `folded` default.

### D4: Click routing in `ScrapedModCard`
New click precedence in the card's `InkWell.onTap`:
1. If `forumModIndex != null` AND a `ForumModDetails` is available for that `topicId`, open the Forum Post Dialog.
2. Else if `websiteUrl != null`, fall back to existing `linkLoader(websiteUrl)`.
3. Else if direct-download URL exists, fall back to existing `_showDirectDownloadDialog`.

The card already has `forumModIndex` passed in from the browser page, so no plumbing is needed at the call site. Because the details lookup is an `AsyncValue`, the card either watches it reactively or calls `ref.read` inside `onTap` and awaits resolution with a short progress indicator when the map is still parsing.

### D5: SMF BBC-specific handlers and element mapping

The renderer dispatches on tag name first, then inspects class / inline style for SMF modifiers.

**Block dispatch (emits `Widget`s):**
- `<p>`, `<div>` → `Padding` + inner content. If the element has `align="center"` or inline `text-align: center`, the content is centered. A bare `<div>` is treated as transparent (just emits children).
- `<h1>`–`<h6>` → `Text` with theme `headlineSmall`/`titleLarge`/`titleMedium`/`titleSmall`/`labelLarge`/`labelMedium`.
- `<ul>` / `<ol>` → `Column` of `<li>`s prefixed with a bullet (`•`) or an incrementing number. `class="bbc_list"` uses the same treatment.
- `<li>` → a row containing the marker + an inline text rich span.
- `<blockquote>` → `Container` with a left border and indented content.
- `<pre>` → `Container` with a monospace `TextStyle`, scrollable horizontally for long lines. Any nested `hljs-*` spans are flattened to their text content.
- `<hr>` → `Divider`.
- `<table class="bbc_table">` / `<tr>` / `<td>` → a Flutter `Table` widget; each `<td>` is a `TableCell` containing the inline render of its children. No colspan/rowspan support (not used in the bundle).
- **Spoiler block** (`<div class="sp-wrap">`): detected at dispatch time. The renderer extracts the `sp-head` label (usually "Spoiler") and the `sp-body` content, renders the body through the renderer recursively, and wraps the whole thing in a `SpoilerBlock` widget that starts collapsed when the body has class `folded`.
- `<iframe src="...">`: rendered as a tappable placeholder (play icon + domain label) that calls `onLinkTap(src)`. No embedded player.

**Inline dispatch (emits `InlineSpan`s):**
- `<br>` → `\n` (as a text span).
- `<strong>`, `<b>` → `FontWeight.bold`.
- `<em>`, `<i>` → `FontStyle.italic`.
- `<u>` or `<span class="bbc_u">` → `TextDecoration.underline`.
- `<del>`, `<s>`, `<strike>` → `TextDecoration.lineThrough`.
- `<sub>` → smaller font, baseline shifted down.
- `<sup>` → smaller font, baseline shifted up.
- `<tt>`, `<code>` → monospace `TextStyle` (theme `fontFamilyMonospace` if set, else `"monospace"`).
- `<span class="bbc_size" style="font-size: Npt">` → parse `Npt`, convert points → logical pixels (`pt * 96/72 * 0.8` scaled to fit dialog body — tuned so `10pt` ≈ body text).
- `<span class="bbc_color" style="color: #rrggbb">` → parse hex color; if the parsed color has very low contrast against the current theme's surface, fall back to the theme's body text color (so light-on-light or dark-on-dark posts remain readable).
- `<span class="bbc_font" style="font-family: X">` → ignored (pass through — we stick to theme fonts).
- `<a class="bbc_link" href="...">` → styled link span with `TapGestureRecognizer` → `onLinkTap(href)`. Never opens a browser directly from the renderer.
- `<img class="bbc_img" src="...">` → emitted as a `WidgetSpan` containing an `Image.network` inside a constrained box with max width. Broken images (via `errorBuilder`) show a small placeholder. Absolute URLs are used as-is; relative URLs are resolved against `baseUrl` (set from `ForumModIndex.topicUrl`).
- `<span class="hljs-*">` → flattened to plain text in the parent `<pre><code>` context.
- `<marquee>` → text content preserved, no animation.
- `<script>` / `<style>` → dropped entirely (tag and text).
- Unknown tags → descend into children; text preserved, structure dropped.

**HTTP vs HTTPS:** `http://` URLs are used as-is (Flutter's `Image.network` handles them on desktop; the bundle predates HTTPS-everywhere).

### D6: Do not cache-bust or re-fetch details for this change
`details` comes bundled with the same file that feeds `forumDataProvider`. The existing 24-hour `CachedJsonFetcher` TTL is reused unchanged. No new network calls are introduced.

## Risks / Trade-offs

- **[~16MB JSON in memory once clicked]** → Parse on demand via `FutureProvider`; if a user never clicks, no cost. If memory becomes a problem, switch to a per-topic lookup that re-reads the cache file.
- **[SMF-specific markup with 20+ distinct tags and class-driven styling]** → D5 lists every tag observed in the real bundle. Unknown tags still degrade gracefully to plain text. Iterate based on what real posts need.
- **[`bbc_color` can clash with dark/light themes]** → Low-contrast colors fall back to the theme's body text color (see D5).
- **[Inline images can be huge / slow]** → Constrain image widgets with a max width and lazy loading (`Image.network` with a loading builder).
- **[Mixed `http://` content on some platforms]** → Accept broken images gracefully via `errorBuilder`. Desktop Flutter handles plain `http` without a platform manifest change.
- **[YouTube iframes expected by users]** → Render a play-icon placeholder that opens the embed URL externally. No in-app video playback.
- **[Spoiler blocks change height when expanded]** → The dialog body uses a `SingleChildScrollView`; an expanding spoiler just grows the scroll extent.
- **[Link tap behaviour surprises users]** → Dialog provides an explicit "Open in Browser" button as an always-available escape hatch.
- **[Users who liked browser-first behaviour]** → The browser icon on the card already opens the forum externally; nothing there changes.
- **[Main-thread jank parsing the bundle]** → Initial JSON decode + mapping of `details` runs inside `compute()` / off the UI isolate.
- **[Placeholder details]** → `isPlaceholderDetail == true` entries may have empty / stub HTML. Treat those as "no details available" and fall back to website-open behavior.

## Migration Plan

1. Land the `details` parsing and the new providers without changing the card's click behavior (feature-flagged off behind a local constant, if needed).
2. Build the HTML renderer + dialog in isolation; verify with a few real topic IDs via a debug entry point.
3. Flip the `ScrapedModCard` click handler to use the dialog.
4. Manual regression: mods with no forum entry (direct download only), mods with only a website URL, and mods with full forum HTML.

No rollback concern — the change is entirely within the catalog UI and is locally reversible by restoring the previous `onTap` body.

## Open Questions

- None — header bar with forum stats is in scope; next/previous mod navigation is out.
