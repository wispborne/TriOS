<!--
This delta extends the `vram-estimator` capability introduced by the in-flight
`pluggable-vram-selectors` change. Both changes must be archived before or
together with this one; listing the new requirements as ADDED (rather than
MODIFIED) avoids coupling the two archives and lets the new parser stand on
its own once both land.
-->

## ADDED Requirements

### Requirement: ReferencedAssetsSelector parses image references in data/config JSON files

`ReferencedAssetsSelector` SHALL include a reference parser that walks every JSON file under `data/config/` in the mod (at any depth, including nested subdirectories) EXCEPT `data/config/settings.json`, and emits every string value that looks like an image path. A string SHALL be considered path-shaped if, after normalization via `PathNormalizer`, it either (a) ends in a known image extension (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`), or (b) starts with `graphics/`. Non-path-shaped strings (ids, plugin class names, tag lists, descriptive text) SHALL NOT be emitted.

The parser SHALL tolerate Starsector's permissive JSON dialect: `#` line comments (in addition to the already-supported `//` and `/* */`) SHALL be stripped before parsing via an opt-in flag on the shared `stripJsonComments` utility, and when strict `json.decode` fails the parser SHALL fall back to extracting quoted string literals from the comment-stripped text via regex. The path-shape filter SHALL apply uniformly to both strict-parse and fallback outputs.

#### Scenario: Icon path in a nested custom-entities JSON is referenced
- **WHEN** a mod contains `data/config/custom_entities.json` with an entry whose `"icon"` value is `"graphics/icons/warning_beacon.png"`, and that file exists on disk
- **THEN** `ReferencedAssetsSelector` SHALL return `graphics/icons/warning_beacon.png` with provenance `referenced` and attribution including the `data-config-json` parser id

#### Scenario: Planet texture in planets.json is referenced
- **WHEN** a mod contains `data/config/planets.json` with a planet definition whose `"texture"` value is `"graphics/planets/star_white.jpg"`, and that file exists on disk
- **THEN** `ReferencedAssetsSelector` SHALL return `graphics/planets/star_white.jpg` with provenance `referenced`

#### Scenario: Nested subdirectory JSON is parsed
- **WHEN** a mod contains `data/config/exerelinFactionConfig/rat_exotech.json` whose content references `"graphics/factions/exotech_logo.png"` under any key, and that file exists on disk
- **THEN** `ReferencedAssetsSelector` SHALL return `graphics/factions/exotech_logo.png` with provenance `referenced`

#### Scenario: Non-path strings are not emitted
- **WHEN** a `data/config/*.json` file contains string values such as `"TERRAIN_7"`, `"assortment_of_things.abyss.entities.hyper.AbyssalFracture"`, `"has_interaction_dialog"`, or `"Fracture"`
- **THEN** `ReferencedAssetsSelector` SHALL NOT treat any of those strings as an image reference

#### Scenario: settings.json is not parsed by this parser
- **WHEN** the mod contains `data/config/settings.json`
- **THEN** the `data-config-json` parser SHALL skip it (leaving `SettingsGraphicsReferences` as the sole owner); a path referenced only by `settings.json` SHALL be attributed to `settings-graphics` and not to `data-config-json`

#### Scenario: Files with # comments are parsed successfully
- **WHEN** a `data/config/*.json` file uses `#` line comments (a common Starsector convention) and is otherwise valid JSON
- **THEN** the parser SHALL strip `#` comments before decoding and SHALL collect path-shaped strings from the result

#### Scenario: Malformed JSON falls back to regex extraction
- **WHEN** a `data/config/*.json` file fails strict `json.decode` after comment stripping (for example, a trailing comma or an unquoted key)
- **THEN** the parser SHALL fall back to a regex-based quoted-string extractor over the comment-stripped text and apply the same path-shape filter to its output

#### Scenario: File read or parse failures are non-fatal
- **WHEN** a `data/config/*.json` file cannot be read from disk or both strict and fallback extraction fail
- **THEN** the parser SHALL log the failure via the selector context's verbose output and SHALL continue processing remaining files, yielding whatever references it collected from the other files

#### Scenario: Parser participates in the common parser plumbing
- **WHEN** a scan runs under `ReferencedAssetsSelector`
- **THEN** the `data-config-json` parser SHALL be registered in the selector's parser list, SHALL be enabled by default via `ReferencedAssetsSelectorConfig.allEnabled`, SHALL honor `enabledParserIds`, SHALL contribute to attribution under the id `data-config-json`, and SHALL emit per-parser timing via `Fimber.d` when `showPerformance` is on

### Requirement: stripJsonComments gains an opt-in flag for # line comments

The shared `stripJsonComments` utility SHALL accept a new optional parameter that enables `#` line-comment stripping. The parameter SHALL default to a value that preserves today's behavior exactly, so existing callers that do not pass the flag SHALL receive byte-for-byte identical output to the pre-change implementation. When the flag is enabled, the utility SHALL strip `#` through the next newline when the `#` appears outside a string literal. String literal contents SHALL be preserved unchanged in both modes. The existing handling of `//` and `/* */` comments SHALL remain unchanged.

#### Scenario: Default behavior is unchanged for existing callers
- **WHEN** `stripJsonComments` is called without the `#`-stripping flag, on input `{ "key": "value" # trailing\n}`
- **THEN** the output SHALL be identical to the pre-change output for the same input (the `#` and the text after it SHALL pass through unmodified)

#### Scenario: Opt-in flag strips # comments outside strings
- **WHEN** `stripJsonComments` is called with the `#`-stripping flag enabled, on input `{ "key": "value" # trailing comment\n}`
- **THEN** the output SHALL have the `#` and everything up to the newline removed, yielding `{ "key": "value" \n}`

#### Scenario: # inside a string literal is preserved in both modes
- **WHEN** `stripJsonComments` is called on input `{ "key": "prefix#suffix" }` with the flag either enabled or disabled
- **THEN** the output SHALL contain the literal `prefix#suffix` unchanged

#### Scenario: Only the new parser opts in
- **WHEN** the VRAM reference parsers run
- **THEN** only `DataConfigJsonReferences` SHALL pass the `#`-stripping flag to `stripJsonComments`; `SettingsGraphicsReferences`, `FactionReferences`, `ShipReferences`, `WeaponReferences`, and any other existing caller SHALL continue to call `stripJsonComments` without the flag
