# Tasks

TriOS must ship scheme support before pack links are publicized. The TriLink
work lives in its separate repository and releases with the receiving flow.

## 1 - Models and formats

- [ ] 1.1 Add the strict shared definition models: required pack UUID, name,
      positive integer version, members, optional metadata, display-only
      Starsector-version label, optional update URL, and raw unknown-key storage
      on every extensible object so `dart_mappable` cannot discard future
      fields during decoding.
- [ ] 1.2 Add member models with required mod ID, HTTP/HTTPS URL, explicit
      source type, optional display snapshots, optional plain-text creator note
      of at most 2,000 characters, and optional catalog hints.
- [ ] 1.3 Add separate local models for incomplete drafts keyed by pack ID,
      saved check times, quiet check errors, failed members, and the last export
      location.
- [ ] 1.4 Run dart_mappable generation for every new or changed generated
      model.
- [ ] 1.5 Implement content comparison for save-time version bumps and exact
      definition comparison for imports and updates. Include member order,
      notes, the Starsector-version label, metadata, sources, catalog hints,
      preserved unknown fields, ID, and integer version where applicable.
- [ ] 1.6 Implement payload encoding and decoding: JSON, zlib deflate,
      unpadded base64url, the `1.` format prefix, a 30,000-character inbound
      limit, a 4 MiB expanded limit, and a 5,000-member limit.
- [ ] 1.7 Refuse unknown payload formats with an update-TriOS message and
      reject malformed, duplicate-member, non-positive-version, or unsafe-URL
      definitions.
- [ ] 1.8 Read Hjson/JSON modpack files and write pretty JSON with the
      `.trios-modpack` extension and a filename slugged from the pack name.
- [ ] 1.9 Preserve unknown optional fields through reading, comparison,
      editing, payload generation, and file export. Test unknown keys on pack,
      member, and nested objects rather than relying on generated decoding.
- [ ] 1.10 Test strict shared definitions separately from incomplete local
      drafts.
- [ ] 1.11 Test payload round trips, decompression and member limits, and
      confirm a realistic 400-member pack is near the measured size.

## 2 - Library and update checking

- [ ] 2.1 Add a persisted Modpacks library and per-pack draft store using the
      generic settings manager and notifier pattern. Allocate a UUID when a new
      pack enters the editor and preserve multiple unfinished packs.
- [ ] 2.2 Calculate installed and missing members from `AppState.mods` by mod
      ID without persisting pack-level installation status.
- [ ] 2.3 Calculate source problems and retained per-member installation
      failures for each library entry.
- [ ] 2.4 Add automatic update checks with cached results and a cooldown.
- [ ] 2.5 Add manual refresh that bypasses the cooldown and keeps background
      failures quiet.
- [ ] 2.6 Implement the integer-version rules for newer, equal, conflicting,
      and older online definitions. Equal-version content conflicts offer
      Replace existing, Add as a copy, and Cancel.
- [ ] 2.7 Implement the different-ID comparison flow with Replace existing,
      Add as another modpack, and Cancel.
- [ ] 2.8 Accept online changes as one complete definition, highlight changed
      member sources, require separate confirmation for an update-address
      change, and retain removed mods on disk unchanged.
- [ ] 2.9 Add tests for update versions, content conflicts, different IDs,
      failed checks, and manual refresh.
- [ ] 2.10 Start checking an incoming definition's update address immediately
      without blocking its embedded preview. Keep the embedded definition
      usable with a warning when the check fails.

## 3 - Creation and editing

- [ ] 3.1 Build the two-pane editor with installed mods on the left and pack
      members on the right.
- [ ] 3.2 Add cross-pane drag-and-drop without exposing the editor to the
      app-wide file-drop handler.
- [ ] 3.3 Add checkbox selection with Add selected and Remove selected.
- [ ] 3.4 Prevent duplicate member IDs and choose the active installed variant,
      then the highest variant, when several are present.
- [ ] 3.5 Resolve initial sources in the agreed override, Version Checker,
      catalog, and download-history order.
- [ ] 3.6 Show and edit source type, Tracks latest release, and Fixed download.
- [ ] 3.7 Prefill the editable Starsector-version label from the current
      installation when known. Show and edit per-member creator notes, keeping
      notes collapsed on demand in dense member lists.
- [ ] 3.8 Persist the selected source as the mod record's preferred share
      source while retaining an independent copy in the pack.
- [ ] 3.9 Copy known catalog name, forum topic ID, and Nexus ID into member
      recovery hints.
- [ ] 3.10 Detect missing required dependencies transitively and add them only
      through an explicit Add required dependencies action.
- [ ] 3.11 Warn before removing a member required by another member without
      blocking the removal.
- [ ] 3.12 Preserve each pack's draft automatically and flag missing IDs, URLs,
      or source types without blocking local saving.
- [ ] 3.13 Validate every member source before Copy share link, Export, or
      Publish update. Cache successful results in memory for 60 minutes by
      unchanged URL and source type, retry failures on the next attempt, show
      progress, and block the action on failure.
- [ ] 3.14 Increment the integer version once when Save changes commits changed
      shared content, including order or note changes, and never for draft-only
      editing or a no-op save.
- [ ] 3.15 For packs with update URLs, add Save as a new modpack, Update this
      modpack, and Cancel. Generate a new ID and clear the update URL for the
      copy, and reset its version to 1.
- [ ] 3.16 Add creation from an empty pack and from selected Mod Manager rows.
- [ ] 3.17 Add creation from a mod profile and leave unresolved profile members
      visible in the editor.
- [ ] 3.18 Add Copy share link, Export, and Publish update. Do not require the
      update address to resolve before these actions; the first export may be
      the file the creator will upload there. Remember the export location and
      ask before overwriting.
- [ ] 3.19 Refuse share links longer than 30,000 characters. Say that the pack
      is too large for a link and suggest shortening its description or member
      notes, removing members, or exporting a `.trios-modpack` file.

## 4 - Modpacks page

- [ ] 4.1 Add Modpacks to `TriOSTools`, the app shell, and navigation.
- [ ] 4.2 Build the library view with name, author, version, Starsector-version
      label, description, installed count, source problems, last successful
      check, and update availability.
- [ ] 4.3 Add search and filters for Updates available, Missing mods, and Needs
      sources.
- [ ] 4.4 Add a passive update count to the navigation item without background
      dialogs or toasts.
- [ ] 4.5 Add View, Edit, Install missing, Retry failed, Review update, and
      Enable installed members actions when applicable.
- [ ] 4.6 Build definition comparisons for incoming duplicates, online
      updates, conflicts, different IDs, changed member sources, and changed
      update addresses.
- [ ] 4.7 Delete only the library entry and draft after confirming that no mods
      will be disabled or uninstalled.
- [ ] 4.8 Add viewer and controller tests for calculated counts, filters,
      actions, and update badges.

## 5 - Links, files, and previews

- [ ] 5.1 Parse `modpack=` from the registered scheme while tolerating the
      extra slash Windows inserts after `install`.
- [ ] 5.2 Reject links containing both `modpack` and the existing `mod` or
      `dep` parameters.
- [ ] 5.3 Extend TriLink URL conversion for fragment-based modpack payloads
      without changing existing single-mod links.
- [ ] 5.4 Route modpack files dropped anywhere in TriOS before game-running,
      folder-write, archive, and log guards.
- [ ] 5.5 Register operating-system file opening where supported and send it
      through the same preview path as a drop.
- [ ] 5.6 Build one preview for links and files with Add to library, Install,
      Cancel, the Starsector-version label, and member notes. Never add or
      install on receipt alone.
- [ ] 5.7 On install, add the pack to the library automatically. On preview
      cancellation, retain nothing.
- [ ] 5.8 Reuse the existing entry when an identical ID and definition arrive.
- [ ] 5.9 For a changed definition with an existing ID, show Replace existing,
      Add as a copy, and Cancel.
- [ ] 5.10 Check drafts as well as committed definitions. Open identical drafts
      and otherwise offer Discard draft and replace, Add incoming as a copy, or
      Cancel without silently losing unsaved work.
- [ ] 5.11 Show the embedded preview immediately while resolving a reachable
      higher online version and explain the embedded and current versions.
- [ ] 5.12 Test warm and cold app starts, file drops on every page, operating-
      system opens, duplicates, and malformed inputs.

## 6 - Installation and recovery

- [ ] 6.1 Resolve Version Checker and fixed-download members through the normal
      deep-link and download services.
- [ ] 6.2 Build non-skippable pack confirmation with checkboxes defaulting to
      missing, installable members and an unchecked Enable installed members
      after installation option.
- [ ] 6.3 Show installed members, source failures, fixed downloads, unresolved
      dependencies, the Starsector-version label, and member notes in
      confirmation.
- [ ] 6.4 Install selected members through the existing download manager and
      batch installer with `activateVariantOnComplete: false`.
- [ ] 6.5 Preserve successful installs when other members fail and retain
      per-member failures for Retry failed.
- [ ] 6.6 Search catalog recovery hints, then exact names, after source failure.
- [ ] 6.7 Show likely fuzzy matches for explicit selection and never install
      one automatically.
- [ ] 6.8 Record successful catalog recovery in the normal mod record without
      editing or versioning the pack.
- [ ] 6.9 Add the confirmed Enable installed members action and run the same
      normal mod-manager enable and dependency behavior from the installation
      option. After partial failure, enable every pack member that is installed.
- [ ] 6.10 Do not expose bulk enabling until `explicit-profile-saving` has
      removed automatic profile rewriting and added derived loadout comparison.
      Do not add a runtime feature flag.
- [ ] 6.11 Test partial selection, partial failure, retry, catalog recovery,
      fixed downloads, profile tracking, and no automatic enabling.

## 7 - Profile sharing transition

- [ ] 7.1 Make Create modpack the prominent sharing action on profile cards.
- [ ] 7.2 Move Copy legacy profile into the profile overflow menu.
- [ ] 7.3 Keep the existing legacy profile importer and duplicate-ID handling
      working unchanged.
- [ ] 7.4 Test profile-to-pack source resolution and legacy import/export
      compatibility.

## 8 - TriLink launcher page (separate repository)

These release requirements are implemented and tracked in the TriLink
repository, not in this TriOS worktree.

- [ ] 8.1 Read `#modpack` from the URL fragment and decode the embedded
      definition entirely in the browser.
- [ ] 8.2 Show the embedded name, author, integer version, Starsector-version
      label, description, member notes, and member list without fetching the
      update URL.
- [ ] 8.3 Fire the registered TriOS scheme with the same versioned payload.
- [ ] 8.4 Resolve fallback member links only when the person expands that
      section, never all at once.
- [ ] 8.5 Show an error for mixed single-mod and modpack parameters.
- [ ] 8.6 Test large payloads and preserve existing single-mod behavior.

## 9 - Documentation and verification

- [x] 9.1 Update the player guide, technical link format, glossary, and ADR.
- [ ] 9.2 Run code generation, formatting, targeted tests, all Flutter tests,
      Flutter analysis, and custom lint.
- [ ] 9.3 Manually verify creation, drag-and-drop, incomplete drafts, sharing,
      add-without-installing, partial installation, catalog recovery, online
      updates, and profile interactions.
