# Tasks

## 1. Groundwork

- [x] 1.1 Get the user's sign-off on the draft text in `design.md`.
- [x] 1.2 Check that the AI-answer fields used as fallbacks are parsed in `forum_llm_data.dart`: `needs`, `optionalNeeds`, `canRemove`, `removalCompatibility` and `updateNotes` (added by `catalog-extras-data`), and `canAdd`, `aiUse` and `isTool` (added by `catalog-search`).
- [x] 1.3 Add `images` to `ForumModDetails` (the field is already in the details file). Regenerate the mappers.
- [x] 1.4 Move `_setModEnabled` from `catalog_mod_card.dart` into `lib/catalog/catalog_mod_actions.dart`. Point the card's menu at it.
- [x] 1.5 Make the section widgets in `mod_summary_widget.dart` public: source code, license, donation links, changelog, save compatibility. The hover tooltip stays the same.

## 2. Related-mods rules

- [x] 2.1 Write `related_mods.dart`: `moreByAuthor()` and `similarMods()`, following the rules in `design.md`.
- [x] 2.2 Add tests: shared author goes to More by, not Similar; limit of five; sort order; cleaned categories used when present, raw ones otherwise; author names compared ignoring case.

## 3. Picture viewer

- [x] 3.1 Write `lib/widgets/picture_viewer.dart`: full-screen route, `InteractiveViewer` zoom and pan, arrow keys, `+` / `-` / `0`, Escape, "{i} of {n}", caption, "Open original".
- [x] 3.2 Show the AI caption only when `Settings.enableAiFeatures` is on.
- [x] 3.3 Give `_InlineImage` in `inline_span_builder.dart` an `onTap` that opens the viewer on the post's pictures, replacing "toggle full size".

## 4. Dialog frame

- [x] 4.1 Write `catalog_details_dialog.dart`: `showCatalogDetailsDialog()`, the 1200 px frame, full screen, a 320 px side column next to a tab area. Each side scrolls on its own.
- [x] 4.2 Wrap it in `DialogPager` over a copy of `displayedMods`. Add the Back history: following a link adds to it, Back removes one, Previous / Next clear it.
- [x] 4.3 Write `details_header.dart`: image, name, authors, mod version, WIP and Tool badges, "From the forum thread X" (it opens the Add-ons tab), Back, the pager buttons, Open in built-in browser, Open in web browser, Full screen, Close.
- [x] 4.4 Hide empty tabs. Hide the tab bar when only one tab is left.

## 5. Tabs

- [x] 5.1 `description_tab.dart`: AI summary through `summary_resolver.dart`, then the forum post with the existing link handling (moved from `forum_post_dialog.dart`: link check, install on click, hovered-link status bar), then the Discord post. Long posts fold.
- [x] 5.2 `gallery_tab.dart`: picture grid from extras `gallery[]`, else catalog images plus forum `details.images`, with duplicates removed. "Show {n} small pictures". Clicking opens the viewer.
- [x] 5.3 `updates_tab.dart`: the author changelog section, then release history from extras `releases[]`, with the "some are missed" note.
- [x] 5.4 `addons_tab.dart`: the "Also in this thread" download rows from today's dialog, in two groups: add-ons, and other versions of this mod.

## 6. Side column

- [x] 6.1 `get_it_panel.dart`: this mod's download row with the split button and "Other download options". For installed mods: state, Enable / Disable, mute toggle.
- [x] 6.2 `links_panel.dart`: source code, license, support links, forum thread, Discord, NexusMods.
- [x] 6.3 `compatibility_panel.dart`: game version badge, Requires chips (✓ when installed; open the mod when in the catalog; greyed out otherwise; small Install button when a download is known), Optional chips, and the add / update / remove answers with the author's words.
- [x] 6.4 `details_panel.dart`: mod version, categories with "Original categories", Added, Last edited, Last release, Thread last posted, AI use (with uses, tools and the author's quote on hover).
- [x] 6.5 `related_mods_panel.dart`: More by {author} and Similar mods, five rows each, each opening that mod in the dialog.
- [x] 6.6 `same_name_panel.dart`: shown under the header when extras `sameNameMods` is not empty.

## 7. Switch over

- [x] 7.1 Make every catalog card open `showCatalogDetailsDialog`. Remove the `hasDetailsToShow` check so Discord-only cards are clickable too.
- [x] 7.2 Delete `forum_post_dialog.dart` and `catalog_mod_details_dialog.dart`. Delete the parts of `forum_post_header.dart` that nothing uses any more.
- [x] 7.3 Mark `Settings.catalogShowDialogHeaderSummary` `@Deprecated`. Remove its unused watch in `catalog_page.dart` (~l.1008).

## 8. Bug fixes

- [x] 8.1 Change the Summary heading icon in `mod_summary_widget.dart` (~l.145) from `Icons.save` to `Icons.notes`.
- [x] 8.2 In `catalog_mod.dart` (~l.347), make `topicUrl` fall back to the catalog's forum URL, not the post title. Add a test.
- [x] 8.3 Pass the entry's Discord answers to `gatherCatalogMod` in the new dialog, as the card does.

## 9. Check

- [x] 9.1 Widget test: a Discord-only mod's dialog offers the same main download as its card.
- [x] 9.2 Widget test: follow a link, press Back, press Next. The shown mod and the Back button are right after each step.
- [x] 9.3 Widget test: with AI features off, the dialog shows no AI summary and no AI captions, and still shows the AI-use row.
- [x] 9.4 Widget test: with no extras loaded, the dialog opens and hides release history, the same-name panel and the Discord post.
- [x] 9.5 Run `fvm flutter analyze` and the catalog tests.
- [ ] 9.6 Ask the user to check the dialog by hand: a forum mod, a Discord-only mod, an installed mod with an update, the picture viewer, and paging.
