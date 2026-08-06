# Proposal: Upgrade to Riverpod 3

## Problem

TriOS is on Riverpod 2.6.1. The current release is 3.4.2.

A CPU trace taken while installing mods from the catalog shows the main thread busy 16.0 seconds out of a 30-second capture. About 4.4 seconds of that is provider work running inside frames, in blocks of 300 to 450 milliseconds. All of it belongs to pages that were not on screen: the ship list, the weapon list, the faction spawn weights, and the codex links each recomputed in full five times, once per mod installed. The only page rendering was the mod manager grid.

Riverpod 3 pauses a provider when every listener of that provider is off screen, and pauses providers that are only used by other paused providers. That is the framework's own answer to this problem, and it works out from the provider graph instead of needing a hand-maintained list of which page uses what.

Riverpod 3 decides "off screen" using Flutter's `TickerMode`. The app's tab stack does not set it, so as far as Flutter is concerned every page is always visible.

## Proposed solution

Two phases, in order.

**Phase 0, before touching Riverpod: tell Flutter which tab is visible.** Wrap each page in the tab stack in `TickerMode(enabled: this page is the current tab)`. On Riverpod 2 this does one thing only — animations on hidden tabs stop advancing — so it can be built and verified on its own while everything else is stable.

**Phase 1: the upgrade.** Move from 2.6.1 to 3.4.x. Most of the work is mechanical. The codebase has no code generation (`riverpod_annotation` is a declared dependency but is never imported), no `ProviderRef`/`FutureProviderRef` types in signatures, no `listenSelf`, and no `FamilyNotifier` subclasses. The renames are:

- `StateProvider` (33 live uses across 19 files, all in `lib/`) and one `StateNotifierProvider` move to a `legacy.dart` import. Seven of those files already have the import written and commented out.
- `AsyncValue.valueOrNull` is removed; the 92 call sites become `.value`.
- `AutoDisposeNotifier` and `AutoDisposeNotifierProvider` in the chatbot controller lose the prefix.
- The one `ProviderObserver` takes a new signature.

Two changes need judgement rather than a find-and-replace:

- **`.value` changes meaning.** In 2.6.1, reading `.value` on an error state with no previous data rethrows the error (`common.dart:493` in the pub cache). In 3.x it returns null. There are ~170 `ref.watch(...).value` sites in `lib/` (plus multi-line chains and tests), and any that relied on the throw would go quiet.
- **Automatic retry is on by default** in 3.x, with exponential backoff up to 6.4 seconds. TriOS has providers that hit the network. A failing fetch would retry indefinitely instead of settling into an error state.

Because phase 0 lands first, the upgrade itself turns pausing on. Riverpod's documentation says a paused provider keeps its state; it does not spell out whether a rebuild is deferred until the page is shown. If it is, a page that is not the current tab stops recomputing its providers until it is opened, and that is the payoff. The CPU trace in "How we know it worked" is what settles it. Either way pausing is the one intended behaviour change here — everything else should behave exactly as it does today.

## Scope

- Wrap the tab stack's pages in `TickerMode` and verify hidden tabs are actually muted, while still on Riverpod 2.
- Bump `flutter_riverpod` and `hooks_riverpod` to 3.4.x, drop the unused `riverpod_annotation`.
- Apply the mechanical renames listed above.
- Audit the `.value` call sites for ones that depended on the old throwing behaviour.
- Switch automatic retry off at the app's `ProviderScope`, and in the test suite's `ProviderContainer`s — tests build their own containers, which do not inherit the app's setting.
- Check what `ProviderException` wrapping does to error reporting and to any code that inspects error types.
- Check providers whose state type has a deep `==` (dart_mappable classes) against the new rule that all providers filter updates with `==`.
- Update tests for the changed test helpers.
- After the upgrade, confirm hidden tabs defer their provider work, and that features which read viewer data without watching it from a visible page — the chatbot intents — still see current data.

## Out of scope

- The `mod-toggle-stutter` change. It targets the same jank from the controller side and is revisited after this lands, with the new CPU trace in hand.
- Rewriting `StateProvider` usages as `NotifierProvider`. The legacy import keeps this change mechanical; individual files can be converted later.
- Adopting code generation.
- Moving parsing work off the main thread.

## How we know it worked

Phase 0, on Riverpod 2:

- `flutter analyze` reports nothing new and the full test suite passes.
- With an animation running on one tab, switching to a static tab makes the app stop drawing continuous frames (checked in DevTools). Switching back resumes the animation.
- No other visible change anywhere.

Phase 1, after the upgrade:

- `flutter analyze` reports nothing new against the pre-upgrade baseline.
- The full test suite passes: 687 tests today.
- A manual pass over the app finds no behaviour change, except that opening a viewer tab after installing mods now does its recompute at that moment. The tab should still open acceptably.
- The chatbot's answers about ships and weapons reflect a newly installed mod even when the viewer tabs were never opened. This checks that pausing did not leave other features reading stale data.
- A fresh CPU trace during mod installs shows the off-screen provider recomputes shrunk or gone. If they still run in full, that means pausing does not defer recomputes — record it; it changes what the pause is worth, not whether the upgrade is correct.
