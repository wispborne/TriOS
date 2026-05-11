# Tasks: Enhance Pride Theme

## Infrastructure

- [x] Create `lib/trios/app_lifecycle_provider.dart` — Riverpod provider exposing `AppLifecycleState`
- [x] ~~Create `lib/widgets/rainbow/rainbow_animation_mixin.dart`~~ — Skipped: premature abstraction

## New widgets

- [x] Create `lib/widgets/rainbow/themed_accent_bar.dart` — self-checking animated rainbow bar (8s flow cycle)
- [x] Create `lib/widgets/rainbow/themed_progress_indicator.dart` — rainbow ShaderMask over progress fill, preserves background track
- [x] ~~Create `lib/widgets/rainbow/pride_shimmer.dart`~~ — Removed: app loads too fast

## Animated app icon

- [x] Update `lib/widgets/trios_app_icon.dart` — animated gradient rotation (6s), lifecycle-aware, lazy controller

## Integration

- [x] Update `lib/app_shell.dart` — replaced `RainbowAccentBar` with `ThemedAccentBar`, removed conditionals
- [x] ~~Update `lib/mod_manager/mod_version_selection_dropdown.dart`~~ — Skipped: already self-contained
- [x] Update `lib/themes/theme_manager.dart` — scrollbar thumb lights up magenta on hover/drag
- [x] Swap all 24 files' `CircularProgressIndicator`/`LinearProgressIndicator` to themed versions

## Cleanup

- [x] Remove `RainbowAccentBar` class from `rainbow_accent_bar.dart`, keep `rainbowColors` + `RainbowBorder`
- [x] Verify no remaining `RainbowAccentBar` references

## Verification

- [x] `flutter analyze` — no new warnings
- [ ] Manual test: Pride theme visual verification
- [ ] Manual test: non-Pride theme has no rainbow effects
- [ ] Manual test: animations pause when backgrounded
