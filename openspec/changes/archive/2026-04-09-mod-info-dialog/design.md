## Context

The mod manager currently shows mod details in a narrow sidebar panel (`ModSummaryPanel`) and offers actions via a context menu. TriOS aggregates data from multiple sources (installed mod_info.json, version checker, catalog/scraped data, forum data, mod records, TriOS metadata) but there's no single view that brings it all together. The sidebar is too narrow for images, forum stats, or a comfortable reading experience.

## Goals / Non-Goals

**Goals:**
- Provide a spacious, comprehensive "mod profile" modal dialog
- Aggregate all available data sources into one view
- Support both installed mods and catalog-only mods
- Include actionable buttons (enable/disable, update, open folder, VRAM, delete)
- Theme the dialog from the mod icon using existing `PaletteGeneratorMixin`
- Horizontal image gallery from catalog data

**Non-Goals:**
- Replacing the sidebar panel (it stays for quick glances)
- Editing mod metadata from the dialog (categories, color tags stay in context menu)
- Downloading/installing catalog-only mods (future work)
- Using catalog images for palette theming (unreliable colors)

## Decisions

### 1. Single widget file with sections
The dialog will be a single `ModInfoDialog` widget in `lib/mod_manager/mod_info_dialog.dart`. Sections (header, gallery, description, status cards, dependencies, versions, actions) will be private methods or small private widgets within the file. This avoids premature file splitting for what is ultimately one dialog.

**Alternative considered:** Separate widget files per section — rejected because the sections are tightly coupled to the dialog's data and won't be reused elsewhere.

### 2. Data aggregation at the call site
The dialog accepts all data sources as parameters: `Mod?` (installed), `ScrapedMod?` (catalog), `ForumModIndex?` (forum stats), `VersionCheckComparison?` (update info). The caller resolves these from providers. The dialog itself is a plain `StatefulWidget` with `PaletteGeneratorMixin`, not a `ConsumerWidget`.

**Alternative considered:** Having the dialog fetch its own data via Riverpod — rejected because the dialog is opened from both mod manager (has `Mod`) and catalog (has `ScrapedMod`), with different data availability. Explicit parameters are clearer.

### 3. Palette theming from mod icon only
The `PaletteGeneratorMixin.getIconPath()` will return the installed mod's icon path. For catalog-only mods with no local icon, the dialog falls back to the default app theme. Catalog images are not used for theming per user requirement.

### 4. Action bar adapts to mod state
The footer action bar renders different buttons based on context:
- **Installed + enabled:** Disable, Update (if available), Open Folder, VRAM Check, Delete
- **Installed + disabled:** Enable (split button with version picker if multiple variants), Open Folder, VRAM Check, Delete
- **Catalog-only:** Links only (Forum, Nexus, etc.), no local actions
- **Game running:** Enable/Disable/Delete buttons disabled

### 5. Image gallery as horizontal ListView
Images from `ScrapedMod.images` rendered in a horizontally scrolling `ListView`. Uses `proxyUrl` with `url` as fallback. Clicking an image could later open a fullscreen viewer, but initially just shows inline thumbnails with a reasonable fixed height (~200px).

### 6. Dialog sizing
Uses `Dialog` with `ConstrainedBox(maxWidth: 800, maxHeight: ~85% of screen)`. Content is scrollable via `SingleChildScrollView`. Following the existing `chatbot_dialog.dart` pattern.

## Risks / Trade-offs

- **[Data sparsity]** Some mods will have very little data (no catalog entry, no forum data, no images). → Sections gracefully hide when data is missing; worst case shows roughly what the sidebar shows, just in a wider layout.
- **[Image loading]** Catalog images are remote URLs that may be slow or broken. → Use `Image.network` with error placeholders; gallery section hidden entirely if no images exist.
- **[Action duplication]** The action bar overlaps with context menu functionality. → Acceptable — the modal is a self-contained view, users expect actions to be available where they're looking at the data.
