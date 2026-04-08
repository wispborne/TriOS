# Semantic Status Colors

## Problem

The theme system lacks semantic status colors. Success uses `Colors.green`, warning uses a static `vanillaWarningColor`, and info uses `Colors.blue` — all hardcoded, not theme-aware, and missing container/on variants. Theme authors cannot customize these.

## Solution

Add success, warning, info, and neutral color roles to `TriOSThemeExtension`, each with 4 variants (base, on, container, onContainer). Generate them from seed colors using two swappable strategies — `ColorScheme.fromSeed` and tonal MCU palettes — with an in-code toggle to compare.

Theme authors can optionally provide seed colors in `themes.json`; defaults are used otherwise.

## Scope

- Extend `TriOSThemeExtension` with 16 new color properties (4 roles × 4 variants)
- Two generation strategies behind an enum toggle
- Add optional seed fields to `TriOSTheme` and `themes.json` parsing
- Add `BuildContext` convenience getters
- Migrate existing hardcoded usages
