## Context

TriOS has mod information spread across four disconnected systems:
1. **Installed mods** — `ModVariant`/`ModInfo` from scanning the mods folder
2. **Version checker** — `VersionCheckerInfo` with forum thread IDs, Nexus IDs, download URLs (from `.version` files)
3. **Mod catalog** — `ScrapedMod` from the remote ModRepo.json (cached locally)
4. **User metadata** — `ModsMetadata` with favorites, colors, timestamps

These are linked at runtime by mod ID when available, but there is no persistent cross-reference. The mod catalog (`ScrapedMod`) doesn't even carry a mod ID — it's matched by name/author heuristics. When the app restarts, all cross-referencing must be re-derived.

## Goals / Non-Goals

**Goals:**
- Persistent local store mapping each mod to all known identifiers: mod ID, forum thread ID, Nexus ID, catalog name, download URLs, install history
- Auto-population on startup by cross-referencing installed mods, version checker data, and the catalog
- Enrichment on user actions (download, install, browse)
- Lookup providers to query by any known identifier
- Synthetic keys for catalog-only mods (not yet installed)

**Non-Goals:**
- Replacing `ModsMetadata` (user preferences stay separate)
- Replacing the in-memory `Mod`/`ModVariant` runtime model
- Full-text search or complex querying (simple map lookups suffice)
- Syncing records across devices

## Decisions

### 1. Persistence: JSON file via GenericAsyncSettingsManager
**Choice**: Single `trios_mod_records-v1.json` file using the existing `GenericAsyncSettingsManager` pattern.
**Rationale**: Consistent with all other persistent state in the app. Gets debounced writes (300ms), mutex locking, auto-backup on corruption for free. The data set is small (hundreds of mods at most), so a flat JSON map is efficient.
**Alternative considered**: SQLite — rejected as overkill; adds a dependency and breaks from existing patterns.

### 2. Record key: mod ID with synthetic fallback
**Choice**: Use `modId` as the primary key. For catalog-only mods without a known mod ID, generate a synthetic key: `catalog:{normalized_name}`.
**Rationale**: Mod ID is the canonical identifier across all systems. Synthetic keys allow tracking catalog mods before installation. Once a catalog mod is installed and its real ID discovered, the synthetic record is merged into the real-ID record.
**Alternative considered**: Using name alone — rejected because names are not unique and change over time.

### 3. Data model: `ModRecord` with typed source sub-entries and user overrides
**Choice**: A `@MappableClass` with a `sources` map (`Map<String, ModRecordSource>`) for auto-populated data and a `userOverrides` map (same type) for user-edited fields. A sealed `ModRecordSource` hierarchy provides typed subtypes (`InstalledSource`, `VersionCheckerSource`, `CatalogSource`, `DownloadHistorySource`). A `resolvedSources` getter merges overrides onto sources field-by-field.
**Rationale**: Separating auto-populated data from user edits ensures auto-population never overwrites manual corrections. Each source subtype has an `applyOverridesFrom()` method for field-level merging (override wins when non-null). Overrides are sparse — only changed fields are stored.

### 4. Population strategy: startup scan + action enrichment
**Choice**: On app startup (after mod variants are loaded and catalog is cached), run a cross-reference pass. Additionally, enrich records when the user downloads, installs, or browses a mod.
**Rationale**: Startup population ensures records are always reasonably complete. Action enrichment captures information that's only available at interaction time (e.g., the URL the user downloaded from).

### 5. Cross-referencing: mod ID → version checker → catalog matching
**Choice**: Link installed mods to catalog entries by matching:
1. Forum thread ID (from VersionCheckerInfo.modThreadId ↔ ScrapedMod forum URL)
2. Nexus ID (from VersionCheckerInfo.modNexusId ↔ ScrapedMod Nexus URL)
3. Name + author fuzzy match as fallback
**Rationale**: Thread ID and Nexus ID are the most reliable unique identifiers shared between version checker files and the catalog. Name matching is a last resort.

### 6. File location and naming
**Choice**: `trios_mod_records-v1.json` in `Constants.configDataFolderPath` (the app support directory).
**Rationale**: Consistent with `trios_mod_metadata-v1.json`, `trios_settings-v1.json`, etc.

### 7. User overrides: separate layer from auto-populated data
**Choice**: `ModRecord` has two parallel maps: `sources` (auto-populated) and `userOverrides` (user-edited via dialog). `resolvedSources` merges them with override fields winning when non-null.
**Rationale**: Auto-population rebuilds sources with fresh `lastSeen` timestamps on every run, which would overwrite any user edits stored in `sources`. A separate override layer ensures user corrections persist across auto-population cycles. Overrides are sparse (only non-null fields differ from auto data), keeping the JSON clean.
**Alternative considered**: (a) Field-level `userModified` flags — more complex, requires tracking per-field edit state. (b) Source-level replacement — user override replaces the entire source, which shadows future auto-discovered fields (e.g., a new changelog URL).

## Risks / Trade-offs

- **Stale records** — A mod is uninstalled but its record persists. → Mitigation: Records are informational, not authoritative. Mark records with a `lastSeen` timestamp. The UI should always cross-check against live mod state.
- **Synthetic key collisions** — Two catalog mods with similar names get the same synthetic key. → Mitigation: Normalize names aggressively (lowercase, strip special chars) and include author if available.
- **Catalog matching accuracy** — Name/author fuzzy matching may produce false positives. → Mitigation: Prefer thread ID and Nexus ID matching; only use name matching when those are unavailable. Flag low-confidence matches.
- **File size** — With hundreds of mods, the JSON file could grow. → Mitigation: At ~500 bytes per record and ~500 mods max, the file stays under 250KB. Well within acceptable bounds.
- **Override null ambiguity** — `null` in an override field means "no override" (use auto value), so a user cannot explicitly blank a field that auto-population sets. → Mitigation: Acceptable edge case; in practice, users add information, not remove it.
