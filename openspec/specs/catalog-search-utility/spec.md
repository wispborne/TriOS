### Requirement: Version comparison function
The utility SHALL provide a `compareVersions(String a, String b)` function that compares Starsector-style version strings. It SHALL handle numeric segments, letter suffixes (a, b, c), pre-release suffixes (dev, alpha, beta, rc), mixed separators (dots, hyphens), and unequal segment lengths. It SHALL return negative if a < b, positive if a > b, zero if equal.

#### Scenario: Compare numeric versions
- **WHEN** comparing "0.97" and "0.96"
- **THEN** the result is positive (0.97 > 0.96)

#### Scenario: Compare versions with letter suffixes
- **WHEN** comparing "0.97a" and "0.97"
- **THEN** "0.97a" is treated as greater than "0.97"

#### Scenario: Compare versions with RC suffixes
- **WHEN** comparing "0.97a-RC11" and "0.97a-RC5"
- **THEN** RC11 is greater than RC5

#### Scenario: Compare pre-release ordering
- **WHEN** comparing versions with "alpha" and "beta" suffixes
- **THEN** alpha < beta < rc in ordering

### Requirement: Version normalization function
The utility SHALL provide a `normalizeBaseVersion(String rawVersion)` function that strips non-version characters, removes RC/pre-release suffixes, and applies version aliases (e.g., "0.9.5" maps to "0.95"). The result SHALL be usable as a grouping key for the version dropdown.

#### Scenario: Normalize RC version
- **WHEN** normalizing "0.97a-RC11"
- **THEN** the result is "0.97"

#### Scenario: Apply version alias
- **WHEN** normalizing "0.9.5a"
- **THEN** the result is "0.95" (via alias mapping)

#### Scenario: Normalize clean version
- **WHEN** normalizing "0.96"
- **THEN** the result is "0.96"

### Requirement: Name comparison function
The utility SHALL provide a `nameCompare` function that sorts mod names alphabetically but places names starting with non-alphanumeric characters (brackets, symbols) at the end.

#### Scenario: Normal names sort alphabetically
- **WHEN** comparing "Arsenal Expansion" and "Blackrock Drive Yards"
- **THEN** Arsenal Expansion comes first

#### Scenario: Bracket names sort last
- **WHEN** comparing "[REDACTED]" and "Arsenal Expansion"
- **THEN** "[REDACTED]" is placed after "Arsenal Expansion"

### Requirement: Filter population helpers
The utility SHALL provide functions to extract unique categories and normalized version groups from a list of `ScrapedMod` items. The version helper SHALL build a mapping of base version to the set of raw version strings, filtered to groups with 3+ mods.

#### Scenario: Extract categories
- **WHEN** given a list of mods with various categories
- **THEN** returns a sorted list of unique non-empty category strings

#### Scenario: Extract version groups
- **WHEN** given a list of mods with various `gameVersionReq` values
- **THEN** returns a map of base version to raw version set, excluding groups with fewer than 3 mods, sorted newest-first
