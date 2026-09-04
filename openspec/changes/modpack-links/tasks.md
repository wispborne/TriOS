# Implementation plan

Tasks are grouped into phases. Each phase ends with something that can be run
and checked. Task numbers keep their original section numbers, so a task keeps
its number even though the phases reorder and split the sections.

## Phase 1 - Format and storage

No UI. Everything later reads and writes these models, and unknown-field
preservation has to be built in from the start rather than retrofitted.
Checked by tests.

### 1 - Shared models and codec

- [x] 1.1 Add ModpackDefinition, ModpackItem, source, catalog-clue, draft, and
      library-entry models under lib/modpacks/.
- [x] 1.2 Use the shared field name items and the UI word mods. Do not introduce
      member terminology.
- [x] 1.3 Generate pack IDs from 16 random bytes as exactly 22 unpadded
      base64url characters. Treat pack and mod IDs as case-sensitive.
- [x] 1.4 Add definition format version 1 separately from the compressed-link
      transport prefix.
- [x] 1.5 Store item status directly as an optional string. Accept Required,
      Recommended, Optional, and trimmed custom single-line values up to 40
      characters. Do not assign a default or attach behavior to the value.
- [x] 1.6 Preserve unknown optional object fields through decode, comparison,
      editing, and encoding. Sort unknown object keys while retaining item
      order and a fixed known-field output order.
- [x] 1.7 Reject unsupported definition formats with an Update TriOS message
      and disable editing, installing, and resharing.
- [x] 1.8 Enforce UTF-8, JavaScript-safe integer versions, bounded strings and
      nesting, a 4 MiB expanded limit, 5,000 items, and a 30,000-character link
      limit.
- [x] 1.9 Keep one codec for links, readable files, and hosted definitions.
- [ ] 1.10 Add golden examples owned by TriOS and copy them into TriLink tests.
- [x] 1.11 Run dart_mappable code generation after model changes.

### 2 - Library and drafts

- [x] 2.1 Add one ModpackStore backed by GenericAsyncSettingsManager and its
      Riverpod notifier. Persist all modpack data in one modpacks.json file.
- [x] 2.2 Make the store the only code that assigns IDs and versions or commits,
      copies, replaces, and deletes packs.
- [x] 2.3 Persist committed definitions and autosaved drafts separately. Allow
      empty and invalid drafts, several draft-only packs, and one draft per ID.
- [x] 2.4 Start the first commit at version 1. Increment once when shared
      content changes, including item order. Do not increment for draft
      autosaves, no-op saves, Copy link, Export, or Publish.
- [x] 2.5 Make Discard restore the committed definition or remove a draft-only
      pack.
- [x] 2.6 Persist the full last successful online definition and timestamp,
      quiet update errors, last export location, and per-item failures keyed by
      item ID and source fingerprint.
- [x] 2.7 Clear a failure after successful installation or a source change. Do
      not record stopped or unstarted items as failures.
- [x] 2.8 Calculate installed coverage, missing items, source problems, update
      availability, and current installation state. Do not persist a pack
      status model.
- [x] 2.9 On corrupt storage, retain the backup and offer Restore backup or
      Start empty. Do not silently replace the file.
- [x] 2.10 Write the chosen item source to ModRecord only when a draft is
      committed. Keep successful catalog recovery's normal immediate ModRecord
      update.

## Phase 2 - Shared grid and field work

Changes the Mod Manager, so it lands on its own where a regression there is
easy to spot. Nothing modpack-specific is built on it yet.

### 4 - Shared grid and field work

- [x] 4.1 Extract the Mod Manager's reusable mod-column builders so the Mod
      Manager and modpack editor can use the full normal column set with
      different visible defaults and independent saved state.
- [x] 4.2 Keep page-specific row context, dependency actions, and sidebars out
      of the shared column builder.
- [x] 4.3 Extend WispGrid with reusable externally controlled checkbox
      selection and cross-grid drag data. Keep modpack behavior out of WispGrid.
- [x] 4.4 Use WispGrid variable-height outer rows for expanded item details.
- [x] 4.5 Add a shared compact Settings-style labelled text field with external
      error text, length limits, and multiline support.
- [x] 4.6 Use MovingTooltipWidget.text instead of Flutter tooltip properties,
      the 8-dip spacing grid, and Row/Column spacing where appropriate.

## Phase 3 - Modpacks library page

The card library and its toolbar, reachable from navigation. Saved packs can be
listed, searched, sorted, filtered, and deleted.

### 3 - Modpacks library

- [ ] 3.1 Add Modpacks as a first-class main navigation tool, lazy-loaded by
      AppShell. Do not group it with the game-data viewers.
- [ ] 3.2 Build ModpacksPage as a keep-alive ConsumerStatefulWidget with a
      Notifier controller plus separate current and persisted page state.
- [ ] 3.3 Reuse ViewerToolbar, SmartSearchBar, the shared filter engine,
      CollapsedFilterButton, FiltersPanel, and WispAdaptiveGridView.
- [ ] 3.4 Use the current TriOS dark theme and existing theme values. Do not add
      a separate Modpacks color scheme.
- [ ] 3.5 Build non-persisted ModpackCardData from library data, drafts,
      installed mods, updates, failures, and in-memory installation state.
- [ ] 3.6 Mix draft-only and saved cards. Show name, author, pack version, game
      version, installed/total count, and applicable Draft, Unsaved changes,
      Update available, Failed, and Installing labels.
- [ ] 3.7 Put description, homepage, update URL, and installed/missing counts in
      the card hover details. Exclude source problems, failed-install details,
      last-check time, and item-status counts.
- [ ] 3.8 Open saved cards on the full page and draft-only cards in the editor.
      Put secondary actions in overflow except live progress and Stop.
- [ ] 3.9 Add toolbar count, update refresh, New, Import, sorting, smart search,
      and filters for Draft, Unsaved changes, Installing, Update available,
      Missing mods, and Needs sources.
- [ ] 3.10 Default to name ascending and offer Author, Pack version, Game
      version, and Installed count. Temporarily put running installations first.
- [ ] 3.11 Match viewer-page persistence for sort, display, filter visibility,
      locked filters, and search history. Do not persist the current search,
      open pack, editor, or expanded rows.
- [ ] 3.12 Do not add a navigation update counter.
- [ ] 3.21 Show New modpack and Import modpack for an empty library. Show Clear
      search and Clear filters when the current view has no matches.

## Phase 4 - Full pack page

The read-only view of one saved pack and its items. Installation progress on
this page arrives with Phase 8.

### 3 - Full pack page

- [ ] 3.13 Make View and Edit replace the Modpacks page content. Back returns to
      the card library.
- [ ] 3.14 Put Back, Edit, Copy link, Export, Install, and overflow at the top
      of the full page in that order. Put Delete and Duplicate in overflow.
- [ ] 3.15 Show all pack information in one compact read-only block.
- [ ] 3.16 Build the full-page item grid with icon, name, author, status,
      installed state, combined version, and dependency warnings visible by
      default. Offer other normal mod columns hidden by default.
- [ ] 3.17 Show one version when installed and recorded versions match. Show
      installed version followed by (modpack: recorded version) when they differ.
- [ ] 3.18 Default the read-only grid to manual pack order but allow sorting.
      Support multiple expanded rows plus Expand all and Collapse all for
      visible rows.

## Phase 5 - Editor

Packs can be created, edited, autosaved as drafts, and saved locally. No
sharing and no installing yet.

### 5 - Editor

- [ ] 5.1 Use one editor for empty creation, Mod Manager selection, profile
      conversion, draft editing, and saved-pack editing.
- [ ] 5.2 Create and autosave a draft immediately when New modpack opens. Start
      with pack fields expanded, an empty right list, and installed mods left.
- [ ] 5.3 Keep installed mods left and pack items right at every window size.
- [ ] 5.4 Put pack fields above the lists. Use Settings-style text boxes while
      editable and compact read-only values while collapsed.
- [ ] 5.5 Start new or invalid pack fields expanded and valid saved pack fields
      collapsed. Keep this state for the current session only.
- [ ] 5.6 Show one installed-mod row per mod ID, preferring the active variant
      and otherwise the highest installed version.
- [ ] 5.7 Give each side its own search. Support drag-to-add, Add selected,
      drag handles, Remove selected, and bulk Set status.
- [ ] 5.8 Keep the right list in manual order and disable all sorting.
- [ ] 5.9 In a collapsed right row show checkbox, icon, name, author, status,
      source type, source host, and issue indicators.
- [ ] 5.10 In an expanded right row show editable status, source type, full URL,
      note, validation, repair, and Remove.
- [ ] 5.11 Allow several expanded rows and add Expand all and Collapse all for
      currently visible rows. Keep expansion state session-only.
- [ ] 5.12 Offer None, Required, Recommended, Optional, existing custom
      statuses, and entry of a new custom status. Do not add a status-management
      screen.
- [ ] 5.13 Put Save changes and Discard changes in the editor toolbar. Leave a
      draft intact on Back. Disable Save for invalid drafts and show the next
      version when saving would increment it.
- [ ] 5.14 Warn about required dependencies missing from the pack and offer an
      explicit transitive Add required dependencies action. Do not auto-add.
- [ ] 5.15 Allow dependency cycles, conflicts, missing dependencies, and removal
      of depended-on items without invalidating the pack.

### 9 - Profiles

- [ ] 9.1 Make Create modpack the prominent sharing action on profile cards and
      keep legacy copy/import/export in overflow.
- [ ] 9.2 Preserve legacy shared-profile compatibility.

## Phase 6 - Sharing out

A finished pack can be turned into a link or a file. TriLink already decodes an
earlier draft of the format locally, so its member field names and pack-ID rule
still need to match this format. The live site is deployed separately, after
local testing.

### 7 - Sharing and source validation

- [ ] 7.1 Validate every item source before Copy link, Export, or Publish
      completes. Allow local draft saving without validation.
- [ ] 7.2 Resolve Version Checker sources to a usable download. For fixed
      downloads, connect and begin a response without downloading the archive.
- [ ] 7.3 Show source-check progress as a new section on the pack page, not a
      dialog. Show each result, error, and repair action and allow Cancel.
- [ ] 7.4 Finish the requested Copy or Export automatically when all checks pass.
- [ ] 7.5 Cache successful exact URL/source-type checks in memory for 60 minutes
      and invalidate them when either value changes.
- [ ] 7.6 Let an unreachable update URL coexist with valid item sources so the
      first hosted definition can still be exported.
- [ ] 7.7 Write pretty JSON .trios-modpack files, remember the last export
      location, and confirm before overwriting.
- [ ] 7.8 Keep publishing as an export for the creator to upload. Do not add
      arbitrary-host upload support.

### 9 - TriLink

- [ ] 9.3 Update TriLink in its own repository to decode the shared format,
      display the embedded pack and item data, and launch TriOS without a pack
      database or automatic update fetch.
- [ ] 9.4 Keep TriOS and TriLink golden examples byte-for-byte aligned.

## Phase 7 - Receiving incoming packs

A link or file from someone else previews and can be added to the library.
Installing from it arrives in Phase 8.

### 6 - Incoming packs

- [ ] 6.1 Route links, dropped files, and operating-system file opens through
      one incoming handler before ordinary mod-archive guards.
- [ ] 6.2 Show incoming packs in a dialog using the compact pack information
      block and full-page item table. Offer Add to library, Install, Check for
      update, and Cancel.
- [ ] 6.3 Do not save, install, or contact an incoming update URL on receipt.
      Check only after an explicit request, add/accept, or install action.
- [ ] 6.4 Keep the embedded definition selected while a check runs. Do not let a
      late result change an add or installation already in progress.
- [ ] 6.5 For identical incoming definitions, open the existing saved pack or
      draft. For conflicts, use explicit Replace, Add as copy, discard-draft,
      or Cancel choices without overwriting draft work.
- [ ] 6.6 Block loopback, private, and link-local addresses for update and item
      requests. Revalidate redirects and enforce size and time limits.

## Phase 8 - Background installation

The riskiest phase, because it changes shared download and install code. Land
8.9 and 8.10 first and confirm the existing single-mod and batch install paths
still work before building anything modpack-specific on them.

### 8 - Background installation

- [ ] 8.1 Add preparation that accepts a ModpackLibraryEntry and returns a
      selectable install plan. Add installation that accepts that plan and the
      confirmed selection and returns an observable in-memory run.
- [ ] 8.2 Save, replace, or copy an incoming pack into the library before
      installation starts.
- [ ] 8.3 Always show confirmation. List items in pack order with checkbox,
      icon, name, status, source, note indicator, installed state, version, and
      dependency warnings.
- [ ] 8.4 Select missing installable items by default and keep installed items
      visible but unselected. Allow every item, including Required, to be
      unchecked.
- [ ] 8.5 Recompute dependencies during preparation and keep all warnings
      advisory.
- [ ] 8.6 After start, turn the confirmation dialog into live progress with
      Close and Stop. Closing must not end the run or block use of TriOS.
- [ ] 8.7 Keep one in-memory run per pack ID. Reject a second start internally
      and open the existing progress instead. Allow different packs to run
      concurrently.
- [ ] 8.8 Share a fair global limit of two downloads and the existing
      configurable one-through-six extraction/install limit across all packs.
- [ ] 8.9 Extend the existing downloader with an awaitable shared handle, final
      normalized address, shared transfer, scan, and progress.
- [ ] 8.10 Move batch archive inspection and selected-ID extraction into
      reusable non-dialog code used by both the current batch UI and modpacks.
- [ ] 8.11 Require an archive to contain its declared mod ID. Install only
      selected declared IDs, ignore and report extras, and fail wrong or missing
      IDs with catalog recovery available.
- [ ] 8.12 Stop by finishing active operations safely and starting no new ones.
      Keep completed installs, skip automatic enabling, and discard the attempt
      after active work settles.
- [ ] 8.13 Do not persist jobs or queues. A later Install action, including
      after restart, creates a new plan from the library and current mod list.
- [ ] 8.14 Keep successful installs after other failures and expose stored
      failures on the pack page.
- [ ] 8.15 Try catalog recovery clues, then exact name, then visible likely
      matches. Never automatically install a fuzzy match.
- [ ] 8.16 Offer unchecked Enable installed items after installation. When
      selected and not stopped, enable every installed pack item through normal
      Mod Manager behavior and dependency confirmation.
- [ ] 8.17 Keep the separate confirmed Enable installed items action. Never
      rewrite a saved profile; rely on explicit-profile-saving for Modified
      loadout behavior.

### 3 - Installation progress on the full pack page

- [ ] 3.19 Show installation progress above the item grid, replace Install with
      Stop while running, and show per-item progress or results in the grid.
- [ ] 3.20 Keep the existing Activity Panel behavior unchanged.

## Phase 9 - Online updates

Saved packs with an update URL can find, compare, and accept a newer hosted
definition.

### 6 - Online updates

- [ ] 6.7 Check saved update URLs in the background with the existing cooldown
      style and provide manual refresh. Do not open passive dialogs or toasts.
- [ ] 6.8 Treat another ID from an update URL as a broken update. Do not replace
      the saved pack; offer the returned definition only as a separate pack.
- [ ] 6.9 Block update acceptance while a draft exists until the person commits
      it, saves it as a copy, or discards it.
- [ ] 6.10 Review saved updates in a dialog over the full page. Reuse it for
      incoming conflicts.
- [ ] 6.11 Group the comparison into Pack information, Added items, Removed
      items, and Changed items. Call out status, source, note, and recorded
      version changes in one list, striking old values and placing new values
      beside them where useful.
- [ ] 6.12 Accept an update as one complete definition. Do not merge fields.
      Confirm an update-URL change explicitly, and offer normal missing-item
      installation afterward.

## Phase 10 - Tests and documentation

Each phase carries its own tests as it lands. This phase is the full sweep
before release.

### 10 - Tests and documentation

- [ ] 10.1 Test codec round trips, fixed ordering, unknown-field preservation,
      unknown formats, limits, malformed input, and golden examples.
- [ ] 10.2 Test store ownership, draft autosave, commit/discard/copy/replace,
      version rules, corruption recovery, and calculated card data.
- [ ] 10.3 Test update safety, redirects, delayed results, duplicate handling,
      draft conflicts, full-definition replacement, and persisted last success.
- [ ] 10.4 Test source selection, validation caching, repair, ModRecord timing,
      dependency warnings, and catalog recovery.
- [ ] 10.5 Test shared downloads, archive ID checks, selected-ID extraction,
      extra mods, per-item failures, Stop, restart behavior, same-pack rejection,
      concurrent packs, fairness, and optional enabling.
- [ ] 10.6 Test the library, full page, editor, incoming dialog, update dialog,
      source-check section, viewer-style persistence, card sorting/filtering,
      expansion, and combined version display.
- [ ] 10.7 Update the player guide, technical format documentation, glossary,
      and any existing modpack ADR to match the final design.
- [ ] 10.8 Run code generation, formatting, targeted tests, all Flutter tests,
      Flutter analysis, and custom lint.
- [ ] 10.9 Manually verify creation, editing, drafts, sharing, incoming links
      and files, background installation, Stop, catalog recovery, updates, and
      profile interactions without changing the Activity Panel.
