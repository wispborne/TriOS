# One details dialog for every catalog mod

Status: ready-for-agent

## Why

Clicking a catalog card opens one of two dialogs today:

- The forum post dialog (`forum_post_dialog.dart`), when TriOS has the mod's forum post.
- A thinner catalog details dialog (`catalog_mod_details_dialog.dart`), when it doesn't. Discord-only mods land here.

The thin dialog leaves out the AI-found and version-checker download links, so a Discord-only mod can show an Install button on its card and none in its dialog. Its body only appears when the header summary is hidden.

Neither dialog shows the mod version, the dates, the categories, optional mods, the add / update / remove mid-game answers, or the AI-use statement. TriOS already downloads most of that. Starmodder's mod page shows all of it, plus a gallery, the Discord post, release history, a same-name warning, and lists of similar mods.

This is change 5 of the Starmodder port. It needs `catalog-extras-data` for the fields only Starmodder's build makes. The rest works without it.

## What changes

- One dialog for every catalog mod. It replaces both dialogs. Every card opens it.
- **Tabs:** Description (AI summary, forum post, Discord post), Gallery, Updates (author changelog and release history), Add-ons. Empty tabs are hidden.
- **Side column:** Get it, Links, Compatibility, Details, More by author, Similar mods.
- **Header:** title, authors, mod version, WIP and Tool badges, "From the forum thread X". Same buttons as today: Open in built-in browser, Open in web browser, Full screen, Close.
- **Get it:** TriOS's Install / Update / Installed button with its "Other download options" menu. Installed state, Enable/Disable and Mute move here. TriOS keeps its own download ranking.
- **Compatibility:** game version, required mods as chips that open that mod (✓ when installed), optional mods, and the add / update / remove mid-game answers with the author's words.
- **Details:** mod version, categories (with the original ones on request), Added, Last edited, Last release, thread last posted, and AI use.
- **Same-name warning** when other mods share this name.
- **Gallery** with a new full-screen picture viewer. Pictures inside the forum post open it too. AI captions hide when AI features are off.
- **Discord post**, drawn by the same code that draws the forum post.
- **More by author** and **Similar mods**, five each, worked out in TriOS.
- Clicking another mod inside the dialog replaces the content and shows a Back button. Previous / Next step through the grid's current list.
- Three bug fixes found during the Starmodder survey:
  - The Summary heading uses the save icon.
  - With a forum post, a missing topic URL falls back to the post's title.
  - The forum post dialog doesn't pass Discord answers when it builds the download list.
- Bring two out-of-date specs in line with the code: `catalog-card-click-action` and `catalog-adaptive-grid`.

## Out of scope

- The Mods page's "View Mod Details..." dialog (`mod_context_menu.dart`). It stays as it is.
- Starmodder's "See raw info", "Report a problem" and takedown buttons. TriOS keeps its Debug Info menu item.
- YouTube previews inside the forum post. Embedded videos stay as links.
- Download order. TriOS's ranking already uses the version checker, which Starmodder doesn't have.
- Favorites, author pages and rows view. These were turned down during planning.
- New filters, search, sorts and card badges. Those are the `catalog-search` and `catalog-filters-and-sort` changes.

## Notes

- The card's right-click "View Mod Details..." item sits behind `if (false)` (`catalog_mod_card.dart` ~l.204). The unused `_showDescriptionDialog` (~l.764) is dead code too. Clicking the card already opens the dialog, so this change doesn't turn the menu item back on. Neither is deleted here.
- Every new piece of visible text needs the user's sign-off before it's final. The draft strings are listed in `design.md`.
