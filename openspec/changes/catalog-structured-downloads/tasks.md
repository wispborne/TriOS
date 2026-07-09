# Tasks

## Candidate resolver

- [x] Create `lib/catalog/catalog_download_resolver.dart` with
      `DownloadCandidate`, `DownloadCandidateKind`, and
      `resolveDownloadCandidates(ScrapedMod, ForumLlmMod?)` sorted per
      design.md (trios > catalog direct > forum direct by confidence >
      mirror by confidence > website).
- [x] Exclude `requiresManualStep` links from being the primary candidate;
      keep them in the list for menus.
- [x] Add `test/catalog_download_resolver_test.dart`: no llm data (today's
      candidates only), trios beats direct/high, catalog direct beats forum
      direct, confidence ordering, manual-step never primary, tie-set
      computation (same kind + confidence as first).

## Deep link plumbing

- [x] Add `trilinkToDeepLinkUri(String url)` to
      `lib/trios/deep_link/deep_link_parser.dart` (host check + scheme swap,
      null when not a valid trilink). Unit-test with a real trilink URL and
      with non-trilink URLs.
- [x] Add public `handleUriString(String rawUri)` to `DeepLinkHandler`
      delegating to `_onUri`.

## Card download button

- [x] Pass the topic's `ForumLlmMod?` (via `forumModIndex?.llm?.mainMod`) into
      `CatalogDownloadButton` and build candidates with the resolver.
- [x] Treat any one-click candidate as "has direct download" in
      `_resolveState`; keep installed/enabled/update precedence unchanged.
- [x] Execute the primary candidate on click: trios → `handleUriString`,
      otherwise `confirmAndDownloadModViaManager`.
- [x] When the tie set has more than one candidate, open a `MenuAnchor` on the
      button instead: one item per tied candidate with label, source host,
      and kind icon; tooltip shows the full URL.
- [x] Tooltip for a trios primary: "Install with TriOS" wording that mentions
      dependencies are installed too (draft final text for user sign-off).

## Card context menu

- [x] Replace "Copy Download URL" with a "Downloads" section listing all
      candidates (label, host, kind icon); click executes the candidate,
      manual-step links open via `linkLoader`.
- [x] Keep a copy-URL affordance and give every new icon/menu item a
      `MovingTooltipWidget.text` tooltip.

## Forum post dialog

- [x] Reuse the header's existing "File download link(s)" strip instead of a
      new section: make it source-agnostic (renders `DownloadCandidate`s) and
      feed it LLM candidates when present, else the scraped HTML links. LLM
      links replace the scraped ones rather than showing a second list.
- [x] Route clicks like the card (trios → deep link, manual-step →
      `linkLoader`, else download manager), bypassing the HTML link sniffer.

## Verify

- [ ] Mod with a trios link (e.g. Grand.Colonies, Knights of Ludd,
      FleetBuilder): card button opens the in-app deep link install dialog,
      dependencies included; no browser opens.
- [ ] Mod with one direct link: behavior identical to today.
- [ ] "AI War" (multiple direct/high links): click shows the chooser with
      "Download" and "Patch (0.3.1 → 0.3.1b)" labels.
- [ ] Mod with only a website link and llm direct links: now one-click
      downloads instead of opening the browser.
- [ ] Right-click any card: full downloads list with tooltips.
- [ ] Forum dialog for a multi-mod topic: grouped downloads with subheadings.
- [ ] Mod with no llm data: card and menus behave exactly as before.
- [x] `flutter test` passes (396 tests); `flutter analyze` clean on changed
      files (2 remaining warnings are pre-existing dead code, untouched).
- [ ] User sign-off on new user-facing strings (menu labels, tooltips).
