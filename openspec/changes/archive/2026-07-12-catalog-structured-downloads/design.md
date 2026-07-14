# Design

## Background

Where downloads happen on the catalog page today:

- `CatalogDownloadButton` resolves its state from
  `mod.urls[ModUrlType.DirectDownload]` and `mod.getBestWebsiteUrl()`
  ([scraped_mod_card.dart:827](../../../lib/catalog/scraped_mod_card.dart#L827)),
  then downloads via `confirmAndDownloadModViaManager`
  ([download_confirm.dart](../../../lib/catalog/download_confirm.dart)).
- The card's right-click `ContextMenuRegion` has a "Copy Download URL" item
  ([scraped_mod_card.dart:94](../../../lib/catalog/scraped_mod_card.dart#L94)).
- The forum post dialog renders the post HTML; links route through
  `_onLinkTap`, which sniffs whether a URL is a downloadable file
  ([forum_post_dialog.dart:53](../../../lib/catalog/forum_post_dialog/forum_post_dialog.dart#L53)).

The deep link system: `trilink.wispborne.com/open.html?mod=<json>&dep=<json>`
uses the **same query format** as `starsector-mod://install?mod=...&dep=...`
([deep_link_parser.dart](../../../lib/trios/deep_link/deep_link_parser.dart)).
`DeepLinkHandler` queues raw URI strings via its private `_onUri`
([deep_link_handler.dart:136](../../../lib/trios/deep_link/deep_link_handler.dart#L136))
and drives the whole confirm/resolve/install flow, including dependencies and
already-installed detection.

Data facts that shaped decisions (July 7 bundle): 694 mods have exactly one
link; 130 have 2+; 12 have multiple `direct`/`high` links (and at least one of
those ties is a full download vs a *patch*); all 10 `trios` links are marked
`confidence: low`, so confidence must not outrank kind.

## Key decisions

### 1. A pure candidate resolver, one list for every surface

New file `lib/catalog/catalog_download_resolver.dart`:

```dart
class DownloadCandidate {
  final String url;            // resolvedDirectUrl ?? url for forum links
  final String label;          // llm label, or "Direct download" / "Website"
  final DownloadCandidateKind kind;   // triosDeepLink, catalogDirect,
                                      // forumDirect, forumMirror, website
  final LlmDownloadConfidence? confidence;
  final String? sourceHost;
  final String? fileName;
  final bool requiresManualStep;
}

List<DownloadCandidate> resolveDownloadCandidates(
  ScrapedMod mod,
  ForumLlmMod? llmMainMod,
)
```

Returned sorted: `triosDeepLink` > `catalogDirect` > `forumDirect`
(high > medium > low > unknown) > `forumMirror` (same) > `website`.
`catalogDirect` (the scraped catalog's existing URL) stays above forum
`direct` links so every mod that one-click-downloads today keeps the exact
same primary action. Being a pure function over models, the card button, the
context menu, and the dialog all share it, and it unit-tests trivially.

The *primary* candidate is `candidates.first`. The *tie set* is every
candidate matching the first's kind and confidence. Tie sets bigger than one
trigger the chooser (decision 4). `requiresManualStep` links sort within
their tier but are excluded from being primary — they can't be one-clicked,
so a manual-step link only ever appears in menus (opened via `linkLoader`).

### 2. Trilink links become in-app deep links

In `deep_link_parser.dart`, add:

```dart
/// https://trilink.wispborne.com/open.html?mod=...&dep=... shares the
/// starsector-mod:// query format; swap scheme+host, keep the query.
String? trilinkToDeepLinkUri(String url)
```

Returns `starsector-mod://install?<original query>` when the host is
`trilink.wispborne.com` and a `mod` param exists, else null (candidate falls
back to plain link handling).

### 3. A public entry point on `DeepLinkHandler`

Add `void handleUriString(String rawUri)` that delegates to `_onUri`. This
reuses de-duplication, queueing, and the confirmation dialog exactly as if
the link had arrived from the OS. Executing a `triosDeepLink` candidate =
`ref.read(deepLinkHandler.notifier).handleUriString(trilinkToDeepLinkUri(url))`.

### 4. Card button: same button, chooser only when needed

`CatalogDownloadButton` gains the candidate list (the card already receives
`forumModIndex`; pass `forumModIndex?.llm?.mainMod` through):

- **State resolution:** the existing `_CatalogDownloadState` logic stays, but
  "has direct download" becomes "has a one-click candidate" (anything above
  `website`). A `triosDeepLink` primary shows the existing download icon with
  tooltip "Install with TriOS (installs dependencies too)".
- **Single primary (the ~95% case):** click executes it — deep link flow for
  `triosDeepLink`, `confirmAndDownloadModViaManager` otherwise. Identical
  look to today.
- **Tie set > 1:** click opens a `MenuAnchor` on the button listing the tied
  candidates — label, source host, kind icon — instead of downloading.
  No extra affordance crammed into the 32px button; the right-click menu
  (decision 5) is the always-available full list.
- Installed/enabled/update states keep their current precedence; only the
  "which URL do we download" part changes.

### 5. Card context menu: full downloads list

Replace the single "Copy Download URL" item with a "Downloads" section
listing **all** candidates (not just the tie set): label, host, kind icon.
Left-click downloads/executes that candidate (browser for
`requiresManualStep`); keep a copy-URL affordance (e.g. a "Copy link" subitem
or right-click hint in the tooltip). Every menu item gets a
`MovingTooltipWidget.text` tooltip showing the full URL.

### 6. Forum post dialog: downloads section

The dialog header already had a "File download link(s)" strip
(`ForumPostHeader`) built from links scraped out of the post HTML
(`details.links`). Rather than add a second, differently-styled section, reuse
that one strip and change only its *source*:

- The strip is now purely presentational: it takes a prioritized
  `List<DownloadCandidate>` plus an `onDownload(candidate)` callback and renders
  the same buttons as before (kind icon instead of a generic download icon).
- The dialog fills that list from the topic's LLM data when present
  (`forumDownloadCandidates` across every `ForumLlmMod`, main mod first — this
  is where `addon` links surface), and falls back to mapping the scraped
  `details.links` into candidates when there's no LLM data. LLM downloads
  therefore *replace* the scraped ones, never duplicate them.
- Clicking routes like the card via `executeDownloadCandidate`: trios → deep
  link handler, manual-step / website → `linkLoader`, else
  `confirmAndDownloadModViaManager`. This *bypasses* the HTML link-sniffing
  path (`_onLinkTap`) — we already know these are downloads.
- No new plumbing: the dialog already receives `ForumModIndex`, so it reads
  `index?.llm` directly.

## Files changed

- `lib/catalog/catalog_download_resolver.dart` — new: candidate model +
  resolver.
- `lib/trios/deep_link/deep_link_parser.dart` — `trilinkToDeepLinkUri`.
- `lib/trios/deep_link/deep_link_handler.dart` — public `handleUriString`.
- `lib/catalog/download_candidate_actions.dart` — new: shared
  `executeDownloadCandidate`, kind icon, and subtitle helpers.
- `lib/catalog/scraped_mod_card.dart` — button candidates + tie menu;
  context-menu downloads list.
- `lib/catalog/forum_post_dialog/forum_post_header.dart` — the "File download
  link(s)" strip made source-agnostic (renders `DownloadCandidate`s).
- `lib/catalog/forum_post_dialog/forum_post_dialog.dart` — feeds the strip LLM
  candidates when present, else the scraped links.
- `test/catalog_download_resolver_test.dart`,
  `test/deep_link_trilink_test.dart` — new.

## Risks / edge cases

- **Patch archives.** Even outside tie sets, a lone link can be a patch
  ("Patch (0.3.1 → 0.3.1b)"). Labels are always shown in menus and tooltips
  so the user can tell; the resolver can't.
- **Low-confidence primaries.** A `direct/low` link can become the primary
  when nothing better exists (per decision: go down the scale). The
  confirmation dialog before download is the safety net.
- **Stale trios links.** Trilink payloads pin versions from scrape time; the
  deep link flow already fetches the `.version` file and installs the
  current release, so staleness self-corrects.
- **Dead links.** Forum posts contain ancient Dropbox/Bitbucket URLs. The
  download manager's existing error handling covers failures; no special
  casing.
- **Topics without llm data** (183) — resolver gets `null` and returns
  exactly today's candidates (catalog direct + website); behavior unchanged.
- **Link-count outliers** (one mod has 18 links) — menus scroll; no cap.
