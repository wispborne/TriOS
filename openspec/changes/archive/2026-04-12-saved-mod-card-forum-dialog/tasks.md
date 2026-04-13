## 1. Forum mod details model

- [x] 1.1 Create `lib/catalog/models/forum_mod_details.dart` with `@MappableClass ForumModDetails` containing: `topicId`, `title`, `category`, `gameVersion`, `author`, `authorTitle`, `authorPostCount`, `authorAvatarPath`, `postDate` (with `ForumDateHook`), `lastEditDate` (with `ForumDateHook`), `contentHtml`, `images`, `links`, `scrapedAt`, `isPlaceholderDetail`.
- [x] 1.2 Run `dart run build_runner build --delete-conflicting-outputs` to generate `forum_mod_details.mapper.dart`.

## 2. Forum details data layer

- [x] 2.1 In `lib/catalog/forum_data_manager.dart`, add an on-demand parser that reads the cached bundle JSON via `forumDataFetcher`, decodes it inside `compute()`, extracts only the `details` map, and returns `Map<int, ForumModDetails>` (converting the JSON string keys to `int`).
- [x] 2.2 Expose a `FutureProvider<Map<int, ForumModDetails>> forumDetailsByTopicId` that triggers parsing on first read and caches the resulting map for the app lifetime.
- [x] 2.3 Add a `Provider.family<ForumModDetails?, int> forumDetailsForTopic` thin lookup that returns the entry or null from the resolved map.
- [x] 2.4 Verify `forumDataProvider` still emits only `updatedAt` and `index` (no regression in the catalog hot path).

## 3. HTML-to-widgets renderer

- [x] 3.1 Create `lib/catalog/forum_post_dialog/html_to_widgets.dart` exporting `List<Widget> htmlToWidgets(String html, BuildContext context, {required void Function(String) onLinkTap, String? baseUrl})`.
- [x] 3.2 Parse input with `package:html`'s `parse` and walk the body's children, dispatching on tag name.
- [x] 3.3 Implement block handlers: `<p>`, `<h1>`–`<h6>`, `<div>` (with `align="center"` and inline `text-align: center` support), `<ul>`, `<ol>`, `<li>`, `<blockquote>`, `<pre>` (flatten hljs spans), `<hr>`.
- [x] 3.4 Implement `<table class="bbc_table">` → Flutter `Table` with `<tr>` rows and `<td>` cells; no colspan/rowspan.
- [x] 3.5 Create `lib/catalog/forum_post_dialog/inline_span_builder.dart` that walks inline descendants and returns `List<InlineSpan>` supporting `<br>`, `<strong>`/`<b>`, `<em>`/`<i>`, `<u>`, `<del>`/`<s>`/`<strike>`, `<sub>`, `<sup>`, `<tt>`/`<code>`, and `<span>`.
- [x] 3.6 Handle SMF span classes inside the inline builder: `bbc_u` → underline; `bbc_size` + inline `font-size: Npt` → scaled font size; `bbc_color` + inline `color: ...` → parsed color with correct WCAG luminance contrast check and fallback to theme body color; `bbc_font` + inline `font-family: ...` → resolved via GoogleFonts for ~50 common web fonts, generic CSS families fall back to system defaults.
- [x] 3.7 Handle `<a class="bbc_link">` (and any `<a>`) as a link span with a `TapGestureRecognizer` that calls `onLinkTap(href)`.
- [x] 3.8 Handle `<img class="bbc_img">` as a `WidgetSpan` with `Image.network` inside a bounded `ConstrainedBox`, with `errorBuilder` placeholder. Resolve relative `src` against `baseUrl` when provided.
- [x] 3.9 Flatten `<span class="hljs-*">` descendants inside `<pre>`/`<code>` to their text content.
- [x] 3.10 Detect `<div class="sp-wrap">` spoiler blocks at the block-dispatch level and route them through `spoiler_block.dart` (see 3.12).
- [x] 3.11 Render `<iframe src="...">` as a tappable placeholder (play icon + domain label) that calls `onLinkTap(src)`.
- [x] 3.12 Create `lib/catalog/forum_post_dialog/spoiler_block.dart` — a `StatefulWidget` that shows an `sp-head` label as a tap target and reveals the rendered body on tap. Starts collapsed when the source body has class `folded`.
- [x] 3.13 Drop `<script>` and `<style>` tags entirely. For any unknown tag, recurse into children and preserve text content only.
- [x] 3.14 Ensure malformed / empty input returns an empty list instead of throwing.

## 4. Forum post dialog + header

- [x] 4.1 Create `lib/catalog/forum_post_dialog/forum_post_header.dart` — a widget taking `ForumModDetails` and optional `ForumModIndex` that renders: mod title, author row (avatar from `authorAvatarPath` if available, author name, `authorTitle`, `authorPostCount`), post date, last-edit date (only when different from post date), a compact stats row (views, replies) from the `ForumModIndex` when supplied, and an "Open in Browser" action button.
- [x] 4.2 Create `lib/catalog/forum_post_dialog/forum_post_dialog.dart` exposing `void showForumPostDialog(BuildContext context, {required ForumModDetails details, ForumModIndex? index, required void Function(String) linkLoader})`.
- [x] 4.3 Build the dialog shell: bounded max width and max height, `ForumPostHeader` at the top, a `SingleChildScrollView` body containing `Column(children: htmlToWidgets(details.contentHtml, context, onLinkTap: linkLoader, baseUrl: index?.topicUrl))`, and a close action.
- [x] 4.4 Wire the header's "Open in Browser" action to call `linkLoader(index?.topicUrl ?? ...)`.
- [x] 4.5 Pass `linkLoader` as the `onLinkTap` callback to the renderer so inline links and iframe placeholders behave consistently.

## 5. Wire up `ScrapedModCard`

- [x] 5.1 In `lib/catalog/scraped_mod_card.dart`, read the `forumDetailsForTopic` provider for `widget.forumModIndex?.topicId` inside the card's `onTap` (via `ref.read` from a `ConsumerStatefulWidget` — convert the card if needed).
- [x] 5.2 Update `hasClickableLink` to also be `true` when a non-placeholder `ForumModDetails` exists for the card's `topicId`.
- [x] 5.3 Change the `InkWell.onTap` precedence: (a) if details exist and `!isPlaceholderDetail`, call `showForumPostDialog(...)`; (b) else if a website URL is set, call `linkLoader(websiteUrl)`; (c) else if a direct-download URL is set, call `_showDirectDownloadDialog(...)`.
- [x] 5.4 Confirm the separate `BrowserIcon` still opens the forum externally — its behavior must not change.

## 6. Manual verification against real bundle

- [ ] 6.1 Run the app and open the catalog; confirm the list still loads without jank and `details` is not parsed until a card is clicked.
- [ ] 6.2 Click a mod with a full forum detail: confirm the dialog opens in-app with header (title, author + avatar, post/last-edit dates, views, replies) and rendered body. No external browser window opens.
- [ ] 6.3 Verify rendering of paragraphs, headings, `<strong>`, `<em>`, `bbc_u` underline, `bbc_size` font scaling, `bbc_color` colors (with readable fallback on both light and dark themes), bulleted/ordered lists, blockquotes, inline links, and at least one `bbc_img`.
- [ ] 6.4 Verify `bbc_table` renders with correct rows/columns on a mod that uses tables.
- [ ] 6.5 Verify a spoiler block starts collapsed, expands on tap, and its content renders fully (including nested images).
- [ ] 6.6 Verify `<pre><code>` with hljs spans renders as plain monospace text.
- [ ] 6.7 Verify a YouTube iframe renders as a placeholder and tapping it calls the link loader.
- [ ] 6.8 Click an inline link inside the dialog and confirm it opens externally via the catalog's link loader.
- [ ] 6.9 Click the header's "Open in Browser" action and confirm the original `topicUrl` opens externally.
- [ ] 6.10 Test a mod with `isPlaceholderDetail == true`: confirm the card click falls back to the website / direct-download path.
- [ ] 6.11 Test a mod with no forum entry but a website URL: confirm the card click still opens the website externally (fallback path).
- [ ] 6.12 Test a mod with no forum entry and no website, only direct download: confirm the card click shows the direct-download confirmation dialog.
- [ ] 6.13 Test a malformed / empty HTML payload (e.g. by temporarily feeding the renderer an empty string): confirm the dialog opens without crashing, showing empty content.

## 7. Fix links + add hover URL bar

- [x] 7.1 Rewrite link rendering in `inline_span_builder.dart`: replace `TextSpan(recognizer: TapGestureRecognizer)` with `WidgetSpan(child: MouseRegion + GestureDetector + Text)` so taps are handled by standard widget gesture detection, not text span recognizers.
- [x] 7.2 Add an `onLinkHover` callback to `InlineBuildContext` and pass it through the renderer. Each link `MouseRegion` calls `onLinkHover(url)` on enter and `onLinkHover(null)` on exit.
- [x] 7.3 Thread `onLinkHover` through `htmlToWidgets()` and `_buildInlineText()`.
- [x] 7.4 In `forum_post_dialog.dart`, add a `ValueNotifier<String?>` for the hovered URL. Pass its setter as `onLinkHover` to the renderer. Display it as a bottom bar (like a browser status bar) using `ValueListenableBuilder`.
- [x] 7.5 Remove the now-unused `TapGestureRecognizer` / `recognizers` list infrastructure from `InlineBuildContext`.
- [x] 7.6 Verify links are clickable, hover bar shows the target URL, and the bar disappears when not hovering a link.

## 8. Rendering refinements

- [x] 8.1 Fix `_relativeLuminance` in `inline_span_builder.dart`: add the missing `pow(x, 2.4)` exponent in sRGB linearization so contrast checks are correct (fixes named colors like `green` being incorrectly rejected).
- [x] 8.2 Add `font-family` CSS property support: parse comma-separated `font-family` values and resolve via GoogleFonts (~50 common web fonts mapped) or generic CSS family keywords; unrecognised fonts degrade to the theme font.
- [x] 8.3 Thread `TextAlign` through `_renderNodes` and `_renderBlock` so centered `<div>` containers cascade `TextAlign.center` to child text blocks — each line is individually centered, not just the block widget.
- [x] 8.4 Also parse `text-align: right` and `text-align: justify` from inline styles on any block element.
- [x] 8.5 Fix image full-size toggle: wrap tappable images in `SelectionContainer.disabled` so `SelectableText.rich` doesn't swallow taps. Change cursor to `zoomOut` when image is already expanded.

## 9. Header refinements

- [x] 9.1 Make "Posted" and "Edited" labels bold in the header date display using `Text.rich` with a bold `TextSpan`.
- [x] 9.2 Add `MovingTooltipWidget.text` tooltips to views and replies stats showing the full decimal-formatted count (e.g. "1,234 forum views"), matching the same pattern used on `ScrapedModCard`.
