# Spec: Semantic Color Extension

## Requirements

1. `TriOSThemeExtension` exposes 16 color properties: success, warning, info, neutral × (base, on, container, onContainer).
2. Colors are generated from seed colors, not manually specified per-variant.
3. Two generation strategies exist behind `SemanticColorStrategy` enum:
   - `fromSeed`: Uses `ColorScheme.fromSeed()` to derive variants from the seed.
   - `tonalPalette`: Uses `material_color_utilities` `TonalPalette` with M3 tone mappings.
4. A single constant (`semanticColorStrategy`) controls which strategy is active. ThemeManager's `_buildExtension` SHALL use this constant (via default parameter) rather than hardcoding a strategy.
5. Both strategies respect `Brightness` (dark vs light) and produce appropriate contrast.
6. `TriOSTheme` accepts optional seed colors (`successSeed`, `warningSeed`, `infoSeed`, `neutralSeed`).
7. `themes.json` parsing reads optional `successSeed`, `warningSeed`, `infoSeed`, `neutralSeed` hex strings.
8. Default seeds are used when theme doesn't specify them.
9. `TriOSThemeExtension.lerp()` interpolates all 16 color fields.
10. `BuildContext` extension provides a `statusColors` getter for ergonomic access.
11. Existing hardcoded usages in widget code are migrated to use the extension.

## Acceptance Criteria

- Switching `semanticColorStrategy` between `fromSeed` and `tonalPalette` produces visually distinct but functionally equivalent results.
- All 4 semantic roles render correctly in both dark and light themes.
- Theme authors can override seed colors via `themes.json` and see the effect.
- Existing snackbar, dependency, and compatibility color behavior is preserved.
