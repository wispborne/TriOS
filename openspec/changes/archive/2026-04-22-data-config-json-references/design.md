## Context

The `pluggable-vram-selectors` change (still in `openspec/changes/`, not yet archived) introduces the `ReferencedAssetsSelector` and a roster of `ReferenceParser`s. One of those is `SettingsGraphicsReferences`, which reads only `data/config/settings.json` and only its `graphics` block.

In practice, Starsector's `data/config/` directory holds many more image-bearing JSON files. Vanilla examples include `custom_entities.json`, `planets.json`, `engine_styles.json`, `hull_styles.json`, `battle_objectives.json`. Mods add more: `modSettings.json`, feature-scoped configs under nested subdirectories (e.g. `exerelinFactionConfig/`, `paintjobs/`, `modFiles/`). A content-heavy mod like *Random Assortment of Things* has ~35 config files spread across ~8 subdirectories, a significant fraction of which contain sprite paths under assorted keys (`"icon"`, `"texture"`, `"glowSprite"`, `"damageDecalSheet"`, `"interactionImage"`, and many ad-hoc variants).

Result today: the reference selector under-counts — real in-use sprites fall into the "unreferenced" bucket. This change closes that gap with a single generic parser.

## Goals / Non-Goals

**Goals:**
- Cover every `.json` file under `data/config/**/` that existing parsers do not already own.
- Be permissive about file format: Starsector's JSONs use `#` line comments in addition to `//` and `/* */`, and some files carry trailing commas or otherwise drift from strict JSON. The parser must degrade gracefully rather than silently drop entire files.
- Be conservative about what counts as a path: match only strings that have a known image extension or begin with `graphics/`. Correctness matters more than recall — the intersection with on-disk files catches the rest.
- Integrate cleanly with the existing `ReferenceParser` plumbing — one new file plus one list entry, per the composition contract in `referenced_assets_selector.dart`.

**Non-Goals:**
- Parse `data/config/settings.json` — `SettingsGraphicsReferences` owns that file and reads more than just path-shaped strings (it walks the `graphics` block structurally).
- Parse CSV files under `data/config/` (e.g. `LunaSettings.csv`, `title_screen_variants.csv`). CSVs are handled by existing `portraits` / `ships` / `weapons` parsers for their well-known schemas; ad-hoc mod CSVs aren't in scope for this pass.
- Parse non-JSON files (`.ini`, `.properties`, loose text).
- Teach the parser per-file schemas. Schema-aware parsing (e.g. "only take the value of `icon`, not the key name") is unnecessary given the path-shape filter.
- Change anything about how GraphicsLib map tagging or the unreferenced bucket are computed downstream.

## Decisions

### 1. Generic file glob vs. schema-per-file parsers

**Decision:** One generic parser that handles every `data/config/**/*.json` file except `settings.json`.

**Rationale:** There are too many files (vanilla + mod-added) with too many ad-hoc schemas to write per-file parsers. A single walker that collects path-shaped strings covers all of them and handles future files for free. Per-file schema parsers would be more precise in theory (e.g. differentiate "sprite" from "name") but the path-shape filter already rejects non-path strings, and every false positive is dropped at the intersection step against on-disk files.

**Alternatives considered:**
- Schema-aware parsers per known file (custom_entities.json, planets.json, etc.). Rejected: huge surface area, brittle against mod-added files.
- Whitelist of known path-valued keys (`"icon"`, `"sprite"`, `"texture"`, …). Rejected: incomplete, misses mod-authored key names, and still requires the path-shape filter as a backstop.

### 2. Path-shape filter

**Decision:** A string qualifies as a reference if, after `PathNormalizer.normalize`, it either (a) ends in a known image extension (`.png/.jpg/.jpeg/.gif/.webp`) or (b) starts with `graphics/`.

**Rationale:** These two conditions capture the conventional Starsector sprite-path shapes while rejecting ids, plugin class names (dot-separated), tag lists, color arrays, and descriptive text. Condition (b) catches path-shaped strings that a mod author wrote without an extension (the game's resource loader accepts both, and `PathNormalizer.expand` already handles the extension-candidates expansion downstream).

Note: `PathNormalizer.expand` is **not** applied at this parser's level. It's applied by parsers that emit bare ids that may need ext-completion (like ship sprite names). Here, the source string is either already a full path (matches condition a directly) or a `graphics/...` prefix (use `expand` to emit the with-extension variants, same as other parsers).

**Alternatives considered:**
- Match any string containing `/`. Rejected: too lax — matches URLs, plugin class paths like `com/foo/bar`, comments drifted into strings.
- Require both `graphics/` prefix AND extension. Rejected: many path-shaped references omit the extension.

### 3. Robustness: strict JSON parse then regex fallback

**Decision:** Two-phase extraction per file. Phase 1: strip comments (extended to include `#`), call `json.decode`, walk the tree, collect every leaf string, pass through the path-shape filter. Phase 2 (only if `json.decode` throws): regex over the comment-stripped text for `"…"` literals, same filter.

**Rationale:** Starsector's tolerant JSON format (trailing commas, occasionally unquoted keys, embedded `#` comments) will reject some legitimate files from strict parsing. Losing a whole file's references on a single syntax quirk is exactly what this change is trying to avoid. The regex fallback is intentionally narrow: it only runs on parse failure, and the same filter still gates what becomes a reference.

**Alternatives considered:**
- Always use regex. Rejected: loses structural context unnecessarily for well-formed files and risks false positives from commented-out string literals or javadoc-style comments the stripper missed.
- Always use a permissive JSON parser (e.g. `package:json5` or write one). Rejected: adds a dependency / code volume for little gain — the regex fallback is ~10 lines and reaches the same destination.

### 4. Extend `stripJsonComments` to handle `#` — opt-in only

**Decision:** Add a new optional parameter `bool stripHashLineComments = false` to `stripJsonComments`. When `true`, `#` line comments outside string literals are stripped through the next newline. When `false` (the default), behavior is byte-for-byte identical to today. The new `DataConfigJsonReferences` parser is the only caller that passes `true`. Existing callers — `SettingsGraphicsReferences`, `FactionReferences`, `ShipReferences`, `WeaponReferences`, and anything else routing through the utility — are **not** touched.

**Rationale:** `#` is not syntactically meaningful in strict JSON, but we can't guarantee no existing caller depends on it passing through (e.g. a path or id that happens to contain `#`, a code branch that relies on parse failure, a logged raw snippet). Keeping the default off makes the change strictly additive and reviewable in isolation — the new parser opts in because its file corpus (custom_entities.json, planets.json, mod configs) routinely uses `#` comments, while the existing parsers keep their exact current behavior.

**Alternatives considered:**
- Flip the default to `true`. Rejected per user guidance: too much surface area, too easy for a latent dependency on today's behavior to break silently.
- Handle `#` inline inside the new parser (copy-paste the stripper, then also strip `#`). Rejected: duplicates the string-literal state machine, which is the tricky part — easy to diverge over time.
- Write a parallel `stripJsonCommentsWithHash` function. Rejected: same state machine twice; an opt-in flag on the existing function is the minimal delta.

### 5. File scoping

**Decision:** The parser runs against any file whose normalized relative path starts with `data/config/` and ends with `.json`, with the single exception of exact match `data/config/settings.json`.

**Rationale:** Matches the problem statement (user's report was about `data/config/` specifically). Nested paths like `data/config/exerelinFactionConfig/rat_exotech.json` are in scope. Files outside `data/config/` are explicitly out of scope for this parser — other parsers own those (e.g. `.faction`, `.ship`, `.wpn`).

### 6. Parser id and display

**Decision:** `id = 'data-config-json'`; `displayName = 'data/config JSON files'`; `description = 'Image paths found in JSON files under data/config/ (beyond settings.json).'`

**Rationale:** Consistent with the existing kebab-case id convention. Display name matches how the directory is commonly referred to. Description calls out the explicit relationship to `settings-graphics` to avoid user confusion in the debug panel checkbox list.

### 7. On-by-default

**Decision:** Add `'data-config-json'` to `ReferencedAssetsSelectorConfig.allEnabled`.

**Rationale:** Matches every other parser's default and the whole point of adding it — to raise the accuracy floor of reference mode. Users who want to bisect can still disable it in the debug panel.

## Risks / Trade-offs

- [Over-extraction via regex fallback on unusual file formatting] → Path-shape filter + intersection with on-disk images contains the blast radius. Same argument already applies to the JAR and Java-source parsers.
- [False positives from path-shaped strings that aren't asset references (e.g. a string like `graphics/unused_concept.png` mentioned in a docstring)] → If the file doesn't exist on disk, intersection drops it. If it does exist on disk, attributing it to "data-config-json" is arguably correct: whatever the semantic intent, the mod *does* contain the file, and some config *does* mention it. The attribution UI makes this legible.
- [Performance — many small files to open and parse] → Config files are small (most under a few KB) and few per mod (dozens at most). Dominant cost in the selector is still JAR/Java scanning, which this parser is strictly additive to. `ctx.showPerformance` will log parser time so we can measure.
- [Coordination with `pluggable-vram-selectors`] → That change introduces the capability this one extends; both must be applied before archival. If this change applies first, the parser file exists but the selector plumbing doesn't — compile error, caught immediately. No hidden-drift risk.
- [`#` stripper change affects other parsers] → Mitigated by making `#`-stripping opt-in via a new parameter defaulting to `false`. Existing callers pass nothing and get today's behavior unchanged; only the new `DataConfigJsonReferences` opts in. Existing unit tests for the no-flag code path remain valid; new tests cover the opt-in path.
