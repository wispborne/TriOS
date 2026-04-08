## MODIFIED Requirements

### Requirement: Strategy constant controls generation
A single constant (`semanticColorStrategy`) controls which strategy is active. ThemeManager's `_buildExtension` SHALL use this constant (via default parameter) rather than hardcoding a strategy.

#### Scenario: _buildExtension respects declared constant
- **WHEN** `_buildExtension` calls `generateAllSemanticColors`
- **THEN** it does not pass an explicit `strategy:` parameter, allowing the default from `semantic_colors.dart` to take effect

#### Scenario: Changing the constant changes behavior
- **WHEN** `semanticColorStrategy` is changed from `fromSeed` to `tonalPalette` (or vice versa)
- **THEN** all generated semantic colors reflect the new strategy without any other code changes
