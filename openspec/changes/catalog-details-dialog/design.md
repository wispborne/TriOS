# Design

## Layout

```
┌──────────────────────────────────────────────────────────────────┐
│ ‹ Back   [image] Name               ‹ ›  [built-in] [web] [⛶] [×]│
│          by Author · v1.2 · WIP · Tool                           │
│          From the forum thread "X"                               │
│ ⚠ Other mods have the same name (only when there are some)       │
├───────────────────────────────────────────┬──────────────────────┤
│ Description | Gallery 12 | Updates | Add-ons │ Get it             │
│                                           │ Links                │
│   (tab content, scrolls)                  │ Compatibility        │
│                                           │ Details              │
│                                           │ More by <author>     │
│                                           │ Similar mods         │
└───────────────────────────────────────────┴──────────────────────┘
```

- Dialog width goes up from 900 to 1200 px at most. The side column is a fixed 320 px wide.
- The tab area and the side column scroll on their own.
- Full screen works as today.

## Where each part gets its data

"Extras" means the mod's record in `mod-catalog-extras.json`, from the `catalog-extras-data` change, looked up by catalog id. "Fallback" is what's shown when that file hasn't loaded.

| Part | Source | Fallback |
|---|---|---|
| Name in the header | extras `displayName`, else catalog `name` | catalog `name` |
| Mod version | catalog `modVersion` | same |
| WIP badge | forum index `isWip` | same |
| Tool badge | extras `isTool` | AI answer `isTool` |
| AI summary | `summary_resolver.dart` and `effectiveCatalogAiSummaryModeProvider`, as today | same |
| Forum post | `ForumModDetails.contentHtml`, as today | same |
| Discord post | extras `discordPostHtml` | hidden |
| Gallery | extras `gallery[]` | catalog `images` plus the forum post's `details.images` |
| AI picture captions | extras `gallery[].aiCaption`, `aiKind`, `aiFit` | hidden |
| Author changelog | AI answer `extras.changelog`, as today | same |
| Release history | extras `releases[]` | hidden |
| Add-ons | the "Also in this thread" rows the dialog builds today | same |
| Get it | `catalog_download_resolver.dart`, same ranking as the card | same |
| Links | AI answer `sourceCode`, `license`, `supportLinks` | same |
| Required / optional mods | extras `needs[]`, `optionalNeeds[]` (with catalog ids) | AI answer `extras.needs`, `optionalNeeds`, matched by name |
| Add / update / remove answers | extras `canAdd`, `canUpdate`, `canRemove` and their texts | AI answer `canAdd`, `saveCompatibility`, `canRemove`, `removalCompatibility`, `updateNotes` |
| Categories | extras cleaned categories, raw ones on request | catalog `categories`, no "Original categories" toggle |
| Added / Last edited | extras `addedOn`, `editedOn` | forum `postDate`, `lastEditDate` |
| Last release | extras `lastReleaseDate` | hidden |
| Thread last posted | forum index `lastPostDate` | same |
| AI use | extras `aiUse` | AI answer `extras.aiUse` |
| Same-name panel | extras `sameNameMods[]` | hidden |
| More by / Similar | worked out in TriOS (below) | same, with raw categories |

## Decisions

### New folder, old dialogs deleted

The dialog lives in `lib/catalog/details_dialog/`:

- `catalog_details_dialog.dart`: `showCatalogDetailsDialog()`, the dialog's outer frame, paging and the Back history.
- `details_header.dart`: title area, badges and header buttons.
- `description_tab.dart`, `gallery_tab.dart`, `updates_tab.dart`, `addons_tab.dart`.
- `get_it_panel.dart`, `links_panel.dart`, `compatibility_panel.dart`, `details_panel.dart`, `related_mods_panel.dart`, `same_name_panel.dart`.
- `related_mods.dart`: the More by / Similar rules, as plain functions with no widgets, so they can be tested.

The picture viewer is `lib/widgets/picture_viewer.dart`, since other pages may want it later.

`forum_post_dialog.dart` and `catalog_mod_details_dialog.dart` are deleted. Parts of `forum_post_header.dart` move into the new files: the download row and its split button, the role tag, and the link status bar. The rest is deleted. `html_to_widgets.dart`, `inline_span_builder.dart` and `spoiler_block.dart` stay as they are, except for the picture click below.

### Paging and Back

`DialogPager` pages through a copy of `CatalogPageState.displayedMods`, taken when the dialog opens. Inside the pager, the dialog keeps a list of mods the user followed links to.

- Following a link (Similar, More by, required chip, same-name row) adds the current mod to that list and shows the new one.
- Back takes the last mod off the list and shows it. The button is hidden when the list is empty.
- Previous / Next and the arrow keys clear the list and step from the grid mod the pager is on.

So Previous / Next always mean "the grid's order". Back only undoes link-following. This keeps both buttons predictable.

### Get it reuses TriOS's download code

- The panel shows the first download group, which is this mod's own row. It uses the same split button as today: Install or Open download page, plus the ▾ "Other download options" menu. Downloads run through `executeDownloadCandidate` with the same `DownloadSourceHint`.
- For an installed mod, the panel also shows the installed state ("Enabled" / "Installed, disabled"), an Enable or Disable button, and a mute toggle.
- `_setModEnabled` moves from `catalog_mod_card.dart` to a shared function in `lib/catalog/catalog_mod_actions.dart`, so the card menu and the panel use the same code.
- The mute toggle uses the same metadata call as `buildMenuItemToggleMuteUpdates`.

### Requirements replace "Also needs"

- The download section's "Also needs: X ✓, Y" line is dropped. The Compatibility panel's required-mod chips carry the ✓ instead.
- A required mod that isn't installed shows a small Install button on its chip when the dialog has a download group for it. This keeps today's ability to install a dependency from the dialog.
- "Also in this thread" rows move to the Add-ons tab, still with their Install buttons.

### Reusing the summary widget's sections

`mod_summary_widget.dart` already draws the source code, license, donation links, changelog and save-compatibility sections. Those section widgets become public and the dialog uses them. The hover tooltip keeps using `ModSummaryWidget` as it is.

### The header summary toggle goes away

The header no longer shows the summary block, so its show/hide button has nothing to do. `Settings.catalogShowDialogHeaderSummary` gets the same `@Deprecated` note as `catalogCardClickAction`, to avoid a settings migration. The unused watch of it in the overflow menu (`catalog_page.dart` ~l.1008) is removed.

### Discord post uses the forum renderer

The scraper builds `discordPostHtml` from Discord's markdown and passes it through the same clean-up as forum posts (`cleanPostHtml`). It only uses tags the forum renderer already handles: `p`, `strong`, `em`, `u`, `s`, `code`, `pre`, `blockquote`, lists, links and `br`. So `htmlToWidgets` draws it with no new code. It gets its own heading, "Discord post", and folds like the forum post does.

### Picture viewer

- It opens as its own full-screen route above the dialog, so its arrow keys never reach `DialogPager`.
- Zoom and pan use `InteractiveViewer`.
- **Keys:** the left and right arrows move between pictures, `+` and `-` zoom, `0` resets the zoom, and Escape closes the viewer.
- Below the picture: the caption, "3 of 12", and an "Open original" button.
- The AI caption is shown only when `Settings.enableAiFeatures` is on.
- **From the gallery:** the viewer pages through the gallery's pictures.
- **From the forum or Discord post:** it pages through that post's pictures. `_InlineImage` gets an `onTap` that opens the viewer, replacing today's "toggle full size".

### Small pictures

When extras are loaded, gallery pictures with `small: true` are hidden behind a "Show N small pictures" button. Without extras, nothing is hidden. TriOS doesn't measure pictures itself.

### More by author and Similar mods

Both are worked out from `CatalogPageState.allMods`, not just the filtered grid, so a mod hidden by the current filters can still show up.

- **More by author:** catalog mods that share at least one author with this mod, compared ignoring case, including extras `otherAuthorNames`. Up to five, newest first by Last release, then Last edited, then Added.
- **Similar mods:** catalog mods with no shared author and at least one shared category. Up to five, sorted by how many categories they share, then newest first. Categories are the cleaned ones from extras, else the raw catalog ones.

This is Starmodder's rule (`site/views/mod.js`, `theAuthorsOtherMods` and `modsLikeThis`).

### Same-name panel

Each row shows title, authors, thread last posted, game version and mod version.

- A row with a catalog id opens that mod in the dialog.
- A row without one opens its forum thread through the dialog's link loader.

### Bug fixes

- **Summary icon:** the Summary heading in `mod_summary_widget.dart` (~l.145) uses `Icons.save`. Change it to `Icons.notes`.
- **Topic URL:** in `catalog_mod.dart` (~l.347), `topicUrl` falls back to `forumDetails.title` when the forum index has no URL. Fall back to the catalog's forum URL (`urls[ModUrlType.Forum]`) instead.
- **Discord answers:** the old forum post dialog called `gatherCatalogMod` without `discordThreads` (~l.165-172). The new dialog passes them the way `catalog_mod_card.dart` does (~l.182-186).

## Draft text for sign-off

None of these strings are final until the user approves them. Most come from Starmodder.

- **Tabs:** "Description", "Gallery", "Updates", "Add-ons"
- **Panels:** "Get it", "Links", "Compatibility", "Details", "More by {author}", "Similar mods"
- **Header:** "From the forum thread {title}", "Back"
- **Same-name panel:** "Other mods have the same name"
- **Compatibility:**
  - "Starsector {version}", "Requires", "Optional"
  - "Add mid-game?", "Update mid-game?", "Remove from game?"
  - Answers: "Yes", "No", "Maybe", "Unknown"
- **Details:**
  - "Mod version", "Category", "Original categories"
  - "Added", "Last edited", "Last release", "Thread last posted", "AI use"
  - AI use values: "None", "Unknown", "Not checked yet"
- **Description tab:** "Forum post", "Discord post", "About this mod"
- **Gallery:** "Show {n} small pictures", "No screenshots in this mod's posts."
- **Picture viewer:** "{i} of {n}", "Open original", "AI description: {caption}"
- **Updates:**
  - "Release history", "{new} (was {old})", "Full changelog"
  - Note: "Releases are prone to error."
- **Add-ons:** "Add-ons in the same thread", "Other versions of this mod"
- **Get it:** "Enabled", "Installed, disabled", "Enable", "Disable"
- **Added in the UI pass:** "Game version", "Required by {mod}." (requirement hover), "Recent updates" and "Release history" as card titles

## Before `catalog-extras-data` lands

The dialog can be built and used first. It reads every extras field through one nullable lookup, and every part has the fallback in the table above. Once the extras file loads, the dialog shows more with no further change.

The fallbacks for required mods, optional mods, the add / remove answers, update notes, AI use and the Tool flag read AI-answer fields that TriOS doesn't parse yet. `catalog-extras-data` adds them to `forum_llm_data.dart` as part of its fallbacks. If this change is built first, it adds those fields itself, and `catalog-extras-data` reuses them.
