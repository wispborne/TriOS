## 1. Extend shared JSON comment stripper (opt-in)

- [x] 1.1 Add an optional parameter to `stripJsonComments` in `lib/vram_estimator/selectors/references/_json_utils.dart` — e.g. `bool stripHashLineComments = false` — that when `true` strips `#` through the next newline outside string literals. Default `false` preserves today's exact behavior.
- [x] 1.2 Audit every existing call site of `stripJsonComments` (at minimum: `settings_graphics_references.dart`, `faction_references.dart`, `ship_references.dart`, `weapon_references.dart`, and any others surfaced by grep). Confirm none pass the new flag. Do NOT modify any existing call site.
- [x] 1.3 Add unit tests under `test/vram_estimator/` for the stripper: (a) default-mode input with `#` passes through unchanged (regression guard for existing callers); (b) opt-in mode strips `#` through the next newline; (c) opt-in mode strips `#` at end-of-file with no trailing newline; (d) `#` inside a string literal is preserved in both modes; (e) existing `//` and `/* */` handling is unchanged in both modes.

## 2. Implement the data/config JSON parser

- [x] 2.1 Create `lib/vram_estimator/selectors/references/data_config_json_references.dart` defining class `DataConfigJsonReferences extends ReferenceParser` with `id = 'data-config-json'`, `displayName = 'data/config JSON files'`, `description = 'Image paths found in JSON files under data/config/ (beyond settings.json).'`.
- [x] 2.2 In `collect`, iterate `allFiles`, short-circuit on `ctx.isCancelled()`, and select files whose `PathNormalizer.normalize(relativePath)` starts with `data/config/`, ends with `.json`, and is not exactly `data/config/settings.json`.
- [x] 2.3 For each selected file, strip comments via `stripJsonComments(..., stripHashLineComments: true)`, attempt `json.decode`. On success, recursively walk the tree collecting every leaf `String`. (This is the only call site that passes the opt-in flag.)
- [x] 2.4 On `json.decode` failure, fall back to a regex over the comment-stripped text that extracts every `"…"` literal (handling `\"` escapes), and feed those strings into the same collection path.
- [x] 2.5 Filter collected strings through a path-shape predicate: after `PathNormalizer.normalize`, keep strings that either end in a known image extension (`.png/.jpg/.jpeg/.gif/.webp`) or start with `graphics/`. Emit each kept string via `PathNormalizer.expand` into the result set.
- [x] 2.6 Wrap per-file I/O and parsing in try/catch; on any failure, log via `ctx.verboseOut` with the file path and error, then continue with the next file.

## 3. Register the parser

- [x] 3.1 Add `DataConfigJsonReferences()` to `_allParsers` in `lib/vram_estimator/selectors/referenced_assets_selector.dart` (adjacent to the existing parsers — order within the list is not significant beyond attribution display).
- [x] 3.2 Add `'data-config-json'` to `ReferencedAssetsSelectorConfig.allEnabled` in `lib/vram_estimator/selectors/referenced_assets_selector_config.dart` so the parser is on by default for both new and upgrading users.
- [x] 3.3 Verify the debug panel (reference scan debug, rendered by `reference_scan_debug_panel.dart`) shows the new parser's checkbox via its `displayName` with no panel-level code change. (Panel iterates `registeredReferenceParsers` — new parser appears automatically.)

## 4. Tests

- [x] 4.1 Add `test/vram_estimator/data_config_json_references_test.dart`. (Deviated from the `references/` subdir in the task text to match existing flat layout of reference tests under `test/vram_estimator/`.)
- [x] 4.2 Fixture: a trimmed `custom_entities.json` with `"icon"` and `"interactionImage"` values; assert those paths are emitted and non-path strings (`pluginClass`, `tags`) are not.
- [x] 4.3 Fixture: a trimmed `planets.json` with `"texture"`, `"icon"`, `"starCoronaSprite"`; assert all three paths are emitted.
- [x] 4.4 Fixture: a trimmed `engine_styles.json` with `"glowSprite"`, `"glowOutline"`; assert emitted.
- [x] 4.5 Fixture: a trimmed `hull_styles.json` with `"damageDecalSheet"`, `"damageDecalGlowSheet"`; assert emitted.
- [x] 4.6 Fixture: a file with `#` comments and trailing commas that fails strict `json.decode` — assert the regex fallback still extracts the expected path-shaped strings.
- [x] 4.7 Fixture: `data/config/settings.json` in the file list — assert the parser skips it entirely (zero emissions) and produces no error.
- [x] 4.8 Fixture: a nested subdirectory file `data/config/exerelinFactionConfig/rat_exotech.json` — assert the parser processes it (glob depth is unrestricted).
- [x] 4.9 Fixture: a file outside `data/config/` (e.g. `data/world/foo.json`) — assert the parser does not process it.
- [x] 4.10 Assert the parser emits paths in normalized form (lowercase, forward slashes) and expands extension-less `graphics/...` strings into the full extension-candidate set.

## 5. Manual verification

- [ ] 5.1 Run the VRAM estimator in reference mode against *Random Assortment of Things* (the file that prompted this change). Spot-check in the debug panel / attribution that previously-unreferenced sprites under `graphics/icons/`, `graphics/planets/`, `graphics/fx/` are now attributed to `data-config-json`.
- [ ] 5.2 Compare per-mod totals against the prior run: referenced bucket should grow, unreferenced bucket should shrink by the same amount (no images should move *into* unreferenced as a result of this change).
- [ ] 5.3 With `showPerformance` on, confirm `Fimber.d` emits per-mod timing for `parser=data-config-json` and that its time cost is small relative to JAR/Java scanning.
- [ ] 5.4 Toggle the parser off in the debug panel — confirm the sprites it uniquely attributes move to the unreferenced bucket on the next scan, and back to referenced when re-enabled.
