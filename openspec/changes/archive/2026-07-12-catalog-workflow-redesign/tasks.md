# Tasks — Catalog Workflow Redesign

## Slice 1 — Card redesign

- [x] Extract a shared game-version-bucket matching helper from `extractVersionGroups` logic in `lib/utils/catalog_search.dart` (installed version vs. `gameVersionReq`)
- [x] Color-code `_ScrapedModGameVersionReq` badge using the helper and `AppState.starsectorVersion` (match = positive tint, older = muted warning, unknown = current neutral); update tooltip to include "Your game: <version>"
- [x] Replace `CatalogDownloadButton`'s icon FAB with a compact labeled button (Install / Get / Update / Installed ✓ / disabled), keeping `_resolveState` logic
- [x] Remove enable/disable from the button's installed state; add Enable/Disable entries to the card context menu (shown only when installed)
- [x] Remove the `Blur` wrappers on update state (button and left status strip)
- [x] Re-anchor the multi-candidate tie chooser `MenuAnchor` to the labeled button
- [x] Add "active <relative time>" freshness text to the card stats row from `ForumModIndex.lastPostDate` via `relativeTimestamp()`; dim when older than 1 year; tooltip with exact date; hidden when no data
- [x] Remove `BrowserIcon`/`DiscordIcon`/`NexusModsIcon` column from the card; add a Links section (Forum / Discord / Copy Discord link / NexusMods) to the card context menu
- [x] Add "+N more in this thread" hint when `llm.mods.length > 1`; clicking opens the details dialog
- [~] Get user sign-off on all new card strings — button labels & installed-click confirmed; still need sign-off on "active X ago", "+N more in this thread", badge tooltip, context-menu labels

## Slice 2 — Unified details dialog

- [x] Make card click always open a details dialog: cached forum HTML → existing `showForumPostDialog`; otherwise → new fallback dialog
- [x] Build the fallback details dialog from scraped data (same shell/header/download strip; body = image, description/summary, AI paragraph per `AiSummaryMode` with attribution)
- [x] Remove the "Clicking a mod opens..." section from the catalog overflow menu; mark the `catalogCardClickAction` settings field `@Deprecated` (no migration)
- [x] Simplify `_dispatchCardLink` into an explicit "open in embedded browser" handler; add "Open in system browser" / "Open in embedded browser" actions to the dialog header and card context menu
- [x] Restructure `ForumPostHeader` downloads into per-mod rows ordered main → addon → separate → unknown, with role captions
- [x] Implement the per-row split button: main click runs `primaryCandidate` for that mod; `▾` menu lists all candidates with host names and low-confidence markers; mirrors only in the menu
- [x] Handle manual-step-only mods: button label "Open download page", click opens the link
- [x] Add the dependencies line under the main mod row from LLM `requires` (✓ when installed; "Install incl. dependencies" when primary is a TriOS deep link)
- [x] Keep the scraped-links fallback (no LLM data) as a single row with a split button
- [x] Get user sign-off on dialog strings — approved; "Downloads", "Also in this thread", "add-on"/"separate mod" role tags, split-button "Install"/"Open download page", deps line "Also needs: … ✓" and "Install incl. dependencies" (user's edit), header/menu "Open in your web browser"/"Open in the built-in browser"

## Slice 3 — Toolbar

- [x] Expose an updates count from `CatalogPageController` (entries with `versionCheck?.hasUpdate == true`)
- [x] Show the updates count as a primary-color badge next to the Status → "Has Update" filter (visible only when count > 0), instead of a toolbar pill
- [x] Rename `CatalogSortKey` labels (Popular, Most Discussed, Recently Active, Newest)
- [x] Get user sign-off on pill and sort label strings

## Slice 4 — Addon findability

- [x] Add nullable `partOfThreadTitle` field to `ScrapedMod`; run `dart run build_runner build --delete-conflicting-outputs`
- [x] Synthesize catalog entries for non-main `llm.mods` (addon/separate/extra-unknown), mapping fields from the LLM mod + parent thread; dedupe against existing entries by normalized name
- [x] Show "part of <thread title>" on synthesized cards
- [x] Point synthesized cards' install button at that specific `ForumLlmMod`'s downloads in `resolveDownloadCandidates`
- [x] Open the parent thread's details dialog on synthesized-card click
- [x] Verify with the "Hartley's mods" thread (5 mods): all appear in search, install correctly, dedupe works
- [x] Get user sign-off on the "part of" string — approved "part of <thread>" (card line) with tooltip "Part of the "<thread>" forum thread. Click the card to see the whole thread."

## Wrap-up

- [x] `flutter analyze` clean (0 errors; no new lints introduced by this change)
- [x] Manual verification pass by user (per project convention: don't run the app yourself)
