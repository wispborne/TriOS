## ADDED Requirements

### Requirement: Engine-overhead estimate from cache size and GraphicsLib state
TriOS SHALL compute an engine-overhead estimate from (a) the estimator's total texture-cache byte estimate and (b) whether GraphicsLib is enabled in the active install. The function SHALL produce a smaller estimate when GraphicsLib is disabled and a larger estimate (with an additional fixed cost) when GraphicsLib is enabled. The estimate SHALL be used to populate the user-facing engine-overhead row in the totals display.

#### Scenario: GraphicsLib disabled
- **WHEN** the active install has GraphicsLib disabled (or GraphicsLib is not installed)
- **THEN** the engine-overhead estimate SHALL equal `cacheOverheadMultiplier × estimatedCacheBytes`, rounded to whole bytes

#### Scenario: GraphicsLib enabled
- **WHEN** the active install has GraphicsLib enabled
- **THEN** the engine-overhead estimate SHALL equal `graphicsLibFixedOverheadBytes + (cacheOverheadMultiplier × estimatedCacheBytes)`, rounded to whole bytes

#### Scenario: GraphicsLib state cannot be determined
- **WHEN** TriOS cannot read or interpret the active install's GraphicsLib configuration (and is not certain the mod is absent)
- **THEN** the engine-overhead estimate SHALL fall back to the GraphicsLib-enabled branch, and the engine-overhead row's tooltip SHALL indicate that GraphicsLib state was unknown

#### Scenario: Constants are easy to update
- **WHEN** Wisp updates the constants (`graphicsLibFixedOverheadBytes` and `cacheOverheadMultiplier`) based on new profiler data
- **THEN** the change SHALL be limited to the constants in `lib/vram_estimator/engine_overhead.dart` and SHALL NOT require modifications to the estimator's per-mod logic, the totals widget, or any persisted state

### Requirement: Totals display shows three-value breakdown
The VRAM Estimator's user-facing totals area SHALL render three labeled values: the existing texture-cache sum (Mods total), the engine-overhead estimate (Engine overhead), and the sum of the two (Projected GPU memory). Per-mod rows SHALL remain unchanged and continue to show texture-cache estimates only.

#### Scenario: Standard render
- **WHEN** the VRAM Estimator renders its totals area
- **THEN** the area SHALL contain three rows in this order: Mods total, Engine overhead, Projected GPU memory; each row SHALL display the value formatted in MB or GB; the Engine overhead and Projected GPU memory rows SHALL each have a trailing info icon with a tooltip

#### Scenario: Per-mod rows unchanged
- **WHEN** any per-mod row is rendered
- **THEN** that row SHALL continue to show the mod's texture-cache estimate only and SHALL NOT show or attribute any portion of the engine-overhead estimate

#### Scenario: Engine-overhead tooltip when GraphicsLib enabled
- **WHEN** the user hovers the Engine overhead info icon and GraphicsLib is enabled
- **THEN** the tooltip SHALL state that the value covers render buffers, shaders, GraphicsLib's lighting effects, and GPU driver overhead, and SHALL note that the value is independent of which specific mods are enabled

#### Scenario: Engine-overhead tooltip when GraphicsLib disabled
- **WHEN** the user hovers the Engine overhead info icon and GraphicsLib is disabled
- **THEN** the tooltip SHALL state that the value covers render buffers, shaders, and GPU driver overhead (without mentioning GraphicsLib), and SHALL note that the value is independent of which specific mods are enabled

#### Scenario: Projected GPU memory tooltip content
- **WHEN** the user hovers the Projected GPU memory info icon
- **THEN** the tooltip SHALL explain that this is the approximate total GPU memory the game will use with these mods loaded, and SHALL note that it is comparable in magnitude to Task Manager's "Dedicated GPU memory" for `java.exe` within approximately ±10–15%
