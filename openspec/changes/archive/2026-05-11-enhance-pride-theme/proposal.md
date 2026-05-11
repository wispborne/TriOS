# Enhance Pride Theme

## Problem

The Pride theme currently has minimal visual differentiation — static rainbow gradient bars, static rainbow borders on a few widgets, and a static gradient on the app icon. All effects are hardcoded via `if (rainbowAccent)` branches scattered across 4+ feature files (~12 conditional checks). Adding more pride-specific visuals would multiply this scatter.

## Proposed Solution

Add five visual enhancements to make the Pride theme feel alive and distinct, while consolidating the `rainbowAccent` branching into self-checking wrapper widgets so feature code doesn't need to know about rainbow mode.

### New visual effects

1. **Animated accent bars (A)** — The sidebar/toolbar rainbow bars get a slow, continuous gradient flow (~8-10s cycle). Colors drift along the axis like a lava lamp, not spin.
2. **Rainbow scrollbar thumb (C)** — Scrollbar thumbs use a rainbow gradient. Small surface area, only visible during interaction.
3. **Animated app icon (E)** — The icon's gradient slowly rotates or shifts angle over time, like it's gently breathing with color.
4. **Rainbow progress indicators (I)** — `LinearProgressIndicator` and `CircularProgressIndicator` use a rainbow gradient shader. Loading states become brief pride moments.
5. **Shimmer on activation (M)** — A one-time shimmer sweeps across the sidebar when the Pride theme activates (on switch or app startup). Not repeating.

### Architecture cleanup

Consolidate `if (rainbowAccent)` checks: instead of call sites branching, wrapper widgets check internally and render the appropriate variant. Feature code uses the wrapper and stays theme-agnostic.

### Performance constraint

All animations must pause when TriOS is in the background. No wasted CPU cycles on invisible effects.

## Scope

- Five visual enhancements listed above
- Refactor existing rainbow widgets into self-checking wrappers
- Background-pause mechanism for all pride animations

## Non-goals

- Generalizing the gradient system to support arbitrary theme gradients (Option 2 from exploration — future work)
- Changing the Pride theme's base colors
- Adding rainbow effects to every possible widget
