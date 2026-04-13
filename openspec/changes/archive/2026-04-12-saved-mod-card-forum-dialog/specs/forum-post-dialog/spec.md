## ADDED Requirements

### Requirement: Forum post dialog entry point
The system SHALL provide a dialog (`showForumPostDialog`) that opens from the catalog mod card and displays the forum post content for a given `ForumModDetails`. The dialog SHALL NOT launch an external browser to render the post.

#### Scenario: Open dialog for a mod with forum details
- **WHEN** the user clicks a `ScrapedModCard` whose `forumModIndex` is non-null and whose `ForumModDetails` is available
- **THEN** a Flutter dialog opens showing the mod's header bar and the rendered post body, without launching an external browser

#### Scenario: Close dialog
- **WHEN** the user clicks the close action or dismisses the dialog
- **THEN** the dialog closes and focus returns to the catalog

#### Scenario: Dialog sizing
- **WHEN** the dialog is opened for any post
- **THEN** the dialog has a bounded max width and max height, and the post body scrolls vertically if the content exceeds the dialog height

### Requirement: Forum post dialog header bar
The dialog SHALL display a header bar containing the mod title, the author (with avatar if `authorAvatarPath` is available and resolvable), the post date (with bold "Posted" label), the last-edit date (with bold "Edited" label, when different from the post date), and the forum stats (views and replies with tooltips showing full decimal-formatted counts, matching ScrapedModCard) taken from the matching `ForumModIndex` when one is supplied.

The header SHALL also contain an "Open in Browser" action that delegates the mod's `topicUrl` to the catalog's existing link loader, and a fullscreen toggle button that persists its state across dialog instances.

#### Scenario: Header with full metadata
- **WHEN** the dialog opens for a post whose `ForumModDetails` has author, avatar, post date, and last-edit date, and whose `ForumModIndex` is supplied
- **THEN** the header shows title, author with avatar, post date, last-edit date, and a stats row with views and replies

#### Scenario: Header with missing avatar
- **WHEN** `authorAvatarPath` is null or fails to load
- **THEN** the header still renders the author row without the avatar and does not crash

#### Scenario: Header with missing index stats
- **WHEN** the caller does not supply a `ForumModIndex`
- **THEN** the header renders without the views/replies row

#### Scenario: Open in browser from header
- **WHEN** the user clicks the "Open in Browser" action in the header
- **THEN** the `topicUrl` from the `ForumModIndex` is passed to the catalog's link loader, opening it externally

### Requirement: Card click opens forum post dialog
The system SHALL change the primary click behavior of `ScrapedModCard` so that when a `ForumModDetails` is available for the mod's `topicId`, clicking the card opens the Forum Post Dialog instead of opening the forum website in an external browser.

#### Scenario: Card click with details available
- **WHEN** the user clicks a card whose mod has a `forumModIndex` and whose `ForumModDetails` is available and is not a placeholder
- **THEN** the Forum Post Dialog opens and no external browser is launched

#### Scenario: Card click with a placeholder detail
- **WHEN** the user clicks a card whose `ForumModDetails` has `isPlaceholderDetail == true`
- **THEN** the system does NOT open the dialog and instead falls back to the website / direct-download behavior

#### Scenario: Card click with only a website URL
- **WHEN** the user clicks a card whose mod has no available `ForumModDetails` but does have a website URL
- **THEN** the system falls back to the previous behavior of passing the URL to the link loader

#### Scenario: Card click with only a direct-download URL
- **WHEN** the user clicks a card whose mod has no available `ForumModDetails` and no website URL but has a direct-download URL
- **THEN** the system falls back to showing the existing direct-download confirmation dialog

#### Scenario: Card click with no links at all
- **WHEN** the user clicks a card whose mod has no `ForumModDetails`, no website URL, and no direct-download URL
- **THEN** the card does not respond to tap (no clickable affordance), matching existing behavior

### Requirement: HTML-to-widget renderer
The system SHALL provide a pure function that parses an HTML string using `package:html` and returns a list of Flutter widgets representing the parsed content, styled against the current `ThemeData`. The renderer SHALL NOT use `WebView`, `flutter_html`, or any browser engine.

The renderer SHALL handle the SMF BBC element subset actually produced in `forum-data-bundle.json`:

- **Block**: `<p>`, `<h1>`–`<h6>`, `<div>` (including `align="center"` attribute and `text-align` inline style — centering cascades through child blocks so each individual text line is centered, not just the block), `<ul>`, `<ol>`, `<li>`, `<blockquote>`, `<pre>` (with hljs spans flattened to plain monospace text), `<hr>`, `<table class="bbc_table">` / `<tbody>` / `<tr>` / `<td>`
- **Inline**: `<br>`, `<strong>`, `<b>`, `<em>`, `<i>`, `<u>`, `<span class="bbc_u">`, `<del>`, `<s>`, `<strike>`, `<sub>`, `<sup>`, `<tt>`, `<code>`, `<span>`
- **SMF class/style handling**:
  - `<span class="bbc_size" style="font-size: Npt">` — font size scaled relative to the theme's body text
  - `<span class="bbc_color" style="color: ...">` — parsed color (hex, rgb/rgba, and CSS named colors), with a correct WCAG relative-luminance contrast check and fallback to the theme body color when contrast is below threshold
  - `<span class="bbc_font" style="font-family: ...">` — resolved via GoogleFonts when a known web font name is used (e.g. Georgia → Merriweather, Courier New → Roboto Mono, Comic Sans MS → Comic Neue); generic CSS families (serif, sans-serif, monospace) fall back to system defaults; unrecognised fonts keep the theme font
  - `<a class="bbc_link" href="...">` — styled link; taps call the renderer's `onLinkTap` callback
  - `<img class="bbc_img" src="...">` — rendered as `Image.network` inside a bounded box; relative URLs resolved against the supplied `baseUrl`; load errors show a placeholder; standalone images (not inside a link) are clickable to toggle between constrained and full 1:1 size with horizontal scroll; SVG URLs show a styled badge placeholder with alt text
- **Spoiler blocks** (`<div class="sp-wrap">` containing `<div class="sp-head">` and `<div class="sp-body">`) render as a collapsible widget that starts collapsed when the body has class `folded`
- **Iframes** (`<iframe src="...">`) render as a tappable placeholder that calls `onLinkTap(src)` — no embedded player
- **Unsupported tags** degrade gracefully: their text content is preserved, their structure is dropped. `<script>` and `<style>` tags SHALL be dropped entirely (tag and text content).

#### Scenario: Render paragraphs and inline formatting
- **WHEN** the input HTML contains `<p>Hello <strong>world</strong></p><p>Second</p>`
- **THEN** the renderer returns two block widgets; the first contains rich text with "Hello " plus a bold "world", and the second contains "Second"

#### Scenario: Render bbc_size font sizing
- **WHEN** the input HTML contains `<span class="bbc_size" style="font-size: 20pt;"><strong>Big</strong></span>`
- **THEN** the rendered span shows "Big" in bold at a larger font size than the body text

#### Scenario: Render bbc_color
- **WHEN** the input HTML contains `<span class="bbc_color" style="color: #ff6600;">Orange</span>`
- **THEN** the rendered span shows "Orange" in an orange tone, unless that color has very low contrast against the dialog surface, in which case the theme body color is used

#### Scenario: Render bbc_u underline
- **WHEN** the input HTML contains `<span class="bbc_u">Underlined</span>`
- **THEN** the rendered span has a `TextDecoration.underline` applied

#### Scenario: Render bulleted list
- **WHEN** the input HTML contains `<ul class="bbc_list"><li>One</li><li>Two</li></ul>`
- **THEN** the renderer produces a widget that presents a bulleted list with "One" and "Two"

#### Scenario: Render numbered list
- **WHEN** the input HTML contains `<ol><li>First</li><li>Second</li></ol>`
- **THEN** the renderer produces a list with "1. First" and "2. Second"

#### Scenario: Render link via callback
- **WHEN** the input HTML contains `<a class="bbc_link" href="https://example.com">link</a>`
- **THEN** the rendered span is styled as a link and tapping it invokes the provided `onLinkTap` callback with `https://example.com`, NOT opening a browser directly from the renderer

#### Scenario: Render bbc_img with absolute URL
- **WHEN** the input HTML contains `<img src="https://example.com/pic.png" alt="" class="bbc_img">`
- **THEN** the renderer emits an `Image.network` widget pointing to that URL, inside a constrained box with a bounded max width, with an error builder for broken images

#### Scenario: Resolve relative image URL against baseUrl
- **WHEN** the input HTML contains `<img src="/uploads/pic.png" class="bbc_img">` and `baseUrl` is `https://fractalsoftworks.com/forum/index.php?topic=123.0`
- **THEN** the renderer resolves the `src` to an absolute URL under `fractalsoftworks.com` before passing it to `Image.network`

#### Scenario: Render spoiler block collapsed
- **WHEN** the input HTML contains `<div class="sp-wrap sp-wrap-default"><div class="sp-head">Spoiler</div><div class="sp-body folded"><p>Hidden</p></div></div>`
- **THEN** the renderer emits a collapsible widget showing "Spoiler" as the tap target, with "Hidden" hidden until the user taps to expand

#### Scenario: Render bbc_table
- **WHEN** the input HTML contains `<table class="bbc_table"><tbody><tr><td>A</td><td>B</td></tr><tr><td>C</td><td>D</td></tr></tbody></table>`
- **THEN** the renderer emits a Flutter `Table` with two rows and two columns containing "A", "B", "C", "D"

#### Scenario: Render pre with flattened hljs
- **WHEN** the input HTML contains `<pre><code><span class="hljs-keyword">if</span> (x)</code></pre>`
- **THEN** the rendered block is a monospace container showing the text "if (x)" without any colored syntax highlighting

#### Scenario: Render iframe as placeholder
- **WHEN** the input HTML contains `<iframe src="https://www.youtube.com/embed/abc123"></iframe>`
- **THEN** the renderer emits a tappable placeholder widget; tapping it invokes `onLinkTap("https://www.youtube.com/embed/abc123")`

#### Scenario: Drop scripts and styles
- **WHEN** the input HTML contains `<script>alert(1)</script>` or `<style>body{}</style>`
- **THEN** the rendered output contains neither the tags nor their text content

#### Scenario: Unknown tag degrades to text
- **WHEN** the input HTML contains `<marquee>Hi <strong>there</strong></marquee>`
- **THEN** the rendered output still contains the text "Hi there" with "there" bolded, but no marquee-specific behavior

#### Scenario: Malformed HTML does not crash
- **WHEN** the input HTML is malformed, empty, or null-ish
- **THEN** the renderer returns a non-null list (possibly empty) and does not throw
