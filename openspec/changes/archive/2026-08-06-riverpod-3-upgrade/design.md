# Design: Upgrade to Riverpod 3

## Approach

Phase 0 first: wire `TickerMode` into the tab stack while still on Riverpod 2, where its only effect is muting animations on hidden tabs, and verify it on its own. Then the upgrade, in waves, letting the compiler drive the work: bump the dependency, fix what stops compiling, then handle the two things the compiler cannot catch — the `.value` meaning change and the new automatic retry.

The guiding rule for every decision below: apart from pausing, which phase 0 and the upgrade deliver together on purpose, the app should behave exactly as it does today when the branch merges. Anything else that would change behaviour gets switched back off, and gets picked up later on purpose rather than by accident.

Preparation is already in the code, commented out, in nine places across eight files. Uncomment these rather than writing them fresh:

- The `retry:` line at `lib/main.dart:429`.
- A `legacy.dart` import in seven files that use `StateProvider`: `lib/main.dart:12`, `lib/trios/app_state.dart:8`, `lib/utils/util.dart:10`, `lib/chipper/chipper_state.dart:5`, `lib/dashboard/mod_list_basic.dart:6`, `lib/mod_manager/mods_grid_page.dart:10`, `lib/rules_autofresh/rules_hotreload.dart:6`.
- A `legacy.dart` import in `lib/dashboard/game_settings_manager.dart:5` for `StateNotifierProvider`.

## Phase 0: TickerMode on the tab stack

Despite the name, `LazyIndexedStack` (`lib/widgets/lazy_indexed_stack.dart`) is not an `IndexedStack`. It is a `PageView.builder` with swiping disabled. Pages it has shown once stay alive off-viewport, because the viewer pages use `AutomaticKeepAliveClientMixin`. It is used in one place: the main tab stack in `lib/app_shell.dart:300`.

The change: in `itemBuilder`, wrap each built page in `TickerMode(enabled: index == widget.index)`.

One thing to verify rather than assume: when the tab changes, the hidden kept-alive pages must rebuild so their `TickerMode` flips to disabled. The `setState` in `didUpdateWidget` should rebuild all live children, kept-alive ones included — confirm with a temporary debug print of `TickerMode.of(context)` in one page's `build`. If kept-alive pages turn out not to rebuild, drive the `enabled` value from a listener on the page controller instead (`ListenableBuilder` around the `TickerMode`).

Why this goes before the upgrade: on Riverpod 2, `TickerMode` only mutes tickers, which is easy to verify in isolation. Once Riverpod 3 lands, the same wiring pauses provider subscriptions on hidden pages, and a provider whose only listeners are paused stops recomputing.

What pausing means after the upgrade: a paused provider keeps its last state. Code that reads a viewer provider with `ref.read` from somewhere else — the chatbot intents do this — can see stale data if that viewer's tab has not been opened since the data changed. The verify pass checks the chatbot. If it turns out stale, the fix is to keep an active listener on that provider from somewhere always visible, such as the app shell, which exempts it from pausing.

## Phase 1: The upgrade

### Target versions

`flutter_riverpod: ^3.4.2` and `hooks_riverpod: ^3.4.2`. Drop `riverpod_annotation` entirely — it is declared in `pubspec.yaml` but never imported anywhere in `lib/` or `test/`, and there are no `@riverpod` annotations, so nothing depends on it.

`hooks_riverpod` has a single import, in `lib/launcher/launcher.dart`.

### Keep `StateProvider` on the legacy import

`StateProvider`, `StateNotifierProvider`, and `ChangeNotifierProvider` move to `package:flutter_riverpod/legacy.dart` in 3.x. TriOS has 42 `StateProvider` mentions across 19 files, all in `lib/`, none in `test/`, plus one `StateNotifierProvider` in `lib/dashboard/game_settings_manager.dart`. Nine of the 42 are commented-out lines — the seven prepared imports listed above, plus a commented-out provider in `lib/chipper/chipper_state.dart:22` and another in `lib/rules_autofresh/rules_hotreload.dart:15` — so there are 33 live `StateProvider` uses. The compiler finds every site, so exact counts only matter for sizing the work.

Seven of the 19 files only need their prepared import uncommented. The other twelve need the import added. Do not rewrite any of them as `NotifierProvider`. Rewriting is a behaviour risk multiplied by 19 files, for no benefit inside this change. Converting them can happen file by file later, when someone is already working in that file.

Two of the references use `StateProvider.autoDispose` (`lib/dashboard/mod_list_basic.dart:33` and `lib/mod_manager/mods_grid_page.dart:75`). If the legacy version keeps the old `.autoDispose` shape, they need no change. If it does not, they become `StateProvider(isAutoDispose: true)`. Check at the time; both are one-line fixes.

`GameSettingsNotifier` also extends the `StateNotifier` class itself (`lib/dashboard/game_settings_manager.dart:26`), not just the provider. Check that `legacy.dart` exports the class as well as `StateNotifierProvider`; if it does not, add the `state_notifier` package as a direct dependency.

### Drop the `AutoDispose` prefix in the chatbot controller

`lib/chatbot/chatbot_controller.dart` uses `AutoDisposeNotifierProvider` and `AutoDisposeNotifier`. In 3.x these unify with the plain versions: the class becomes `Notifier<ConversationContext>` and the provider becomes `NotifierProvider(..., isAutoDispose: true)`. This is the only file with these types.

### Rename `.valueOrNull`, then audit `.value`

Two separate steps, in this order, because they have different risk.

**Step one is safe.** `AsyncValue.valueOrNull` is removed and `.value` takes over its meaning, so the 92 `.valueOrNull` call sites become `.value` with identical behaviour.

**Step two needs reading, and needs the right search.** A bare search for `.value` returns roughly 900 hits in `lib/`, most of them on `TextEditingController`, `Animation`, `MapEntry`, and other types that have nothing to do with `AsyncValue`. Search instead for AsyncValue reads: the regex `ref\.(watch|read)\([^)]*\)\.value` finds ~170 single-line sites in `lib/`. Then catch the stragglers: chains split across lines, and locals or fields typed `AsyncValue<...>`.

Two facts narrow the audit:

- In 2.6.1, `.value` only threw when the error state had **no previous data**. An error during a refresh already returned the old data without throwing. So only sites reachable on a first load could have relied on the throw.
- Most sites are already written as `.value ?? []` or `?.something`, which treat null as "no data yet". Those get safer, not worse.

The ones to find are where a first-load error today produces a thrown exception that something catches, logs, or reports, and would now produce a silent null. Where the throw mattered, use `.requireValue` or handle the error state explicitly with `hasError`.

### Turn automatic retry off globally — in the app and in tests

3.x retries failing providers by default with exponential backoff, up to 6.4 seconds between attempts. TriOS fetches over the network in several providers — the version checker, the catalog, changelogs. Today a failure surfaces once and stays failed. With retry on, a mod host being down turns into repeated background requests, and the user sees a loading state that never resolves.

App: uncomment the prepared `retry: (retryCount, error) => null` on the `ProviderScope` in `lib/main.dart:429`. That preserves today's behaviour. Individual providers can opt into retry later, where it is actually wanted.

Tests: the app's `ProviderScope` setting does not reach tests. Ten test files build their own `ProviderContainer` (12 uses). In 3.x those containers retry failing providers by default, so a test that asserts an error state can hang or leave pending timers. Give test containers the same `retry` override through one shared helper, so future tests get it for free. Check whether 3.x's `ProviderContainer.test()` exists and already handles this; use it if it does.

### Update the one `ProviderObserver`

`RiverpodDebugObserver` in `lib/utils/logging.dart:426` implements `didAddProvider`, `didDisposeProvider`, `didUpdateProvider`, and `providerDidFail`. In 3.x these take a single `ProviderObserverContext` holding the container, the provider, and mutation information, instead of separate parameters. Only `didUpdateProvider` has a body; it logs when `shouldDebugRiverpod` is on. Rewrite the four signatures and pull `provider` and `container` off the context object.

### Check `ProviderException` against error reporting

3.x wraps a provider failure in a `ProviderException` when the failure is read, with the original error on `.exception`. The concrete places errors now arrive wrapped are `await ref.read(x.future)` and the 8 `requireValue` sites.

A search for `.future` in `lib/` returns 28 hits, but only 8 of them read a provider: `lib/companion_mod/companion_mod_manager.dart:72`, `lib/ship_viewer/engine_styles_manager.dart:184`, and six in `lib/trios/deep_link/deep_link_handler.dart:346-358`. The rest are `Completer.future` and a field named `future` on the version checker's task class. `test/` has 9 more `.future` hits; check those too.

Two things to look at:

- Any `catch` block downstream of those that checks the error type. A `catch (e)` followed by an `is` check against a specific exception type would stop matching.
- Sentry reporting. The observer's `providerDidFail` is empty, so provider errors reach Sentry some other way — the global error handlers set up in `main.dart` and `Fimber.e`. Name the actual path first, then confirm wrapped errors still group sensibly and still carry the original error.

### Check deep-`==` state against the new update filtering

3.x filters all provider updates with `==`; 2.x used `identical` for some provider types. The old and new checks only disagree where a state type's `==` is deeper than identity.

- Plain Dart `List` and `Map` compare by identity. Seven of the 8 `StreamNotifierProvider`s emit `List<...>`; the eighth (`descriptionsNotifierProvider`, `lib/descriptions/descriptions_manager.dart:16`) emits `Map<DescriptionKey, DescriptionEntry>`. Either way two rebuilt collections are never `==`, so the update still goes through and none of the 8 need a check.
- The exposure is state types with a generated deep `==` — every `@MappableClass`. The two plain `StreamProvider`s emit single mappable objects (`ModRepoFile` in `lib/catalog/catalog_manager.dart:19`, `ForumDataBundle` in `lib/catalog/forum_data_manager.dart:24`), and many `Notifier`/`AsyncNotifier` providers hold mappable state. Setting state to an equal-but-distinct copy no longer notifies.
- Usually that is fine — an equal state draws the same UI. It matters where re-emitting an equal value is used as a signal, typically a `ref.listen` that triggers a side effect. The codebase already has one spot that forces notification: `BatchInstallationNotifier` overrides `updateShouldNotify` to always return true (`lib/mod_manager/batch_installation/batch_installation_notifier.dart:48`), which keeps working in 3.x.

Audit: list the providers whose state type is a mappable class or otherwise overrides `==`. For each, check whether anything depends on being notified when the value is equal. Override `updateShouldNotify` where the old behaviour is needed.

### Revisit the test workaround for `.future`

The project has a known problem where awaiting a provider's `.future` in tests times out when the first build is superseded, worked around by listening and polling instead. 3.x changes rebuild behaviour: previous subscriptions are now kept until a rebuild completes. That may fix the underlying problem. Re-test one of the affected tests with a plain `await ... .future` and, if it now works, note that so the workaround can be dropped over time.

## Files that change

| File | Change |
|---|---|
| `lib/widgets/lazy_indexed_stack.dart` | Phase 0: wrap each page in `TickerMode` |
| `pubspec.yaml`, `pubspec.lock` | Version bumps, drop `riverpod_annotation` |
| `lib/main.dart` | Uncomment the `retry` override on `ProviderScope` (line 429) and the legacy import (line 12); it also uses `StateProvider` |
| `lib/utils/logging.dart` | New `ProviderObserver` signatures (line 426) |
| `lib/chatbot/chatbot_controller.dart` | Drop `AutoDispose` prefixes |
| `lib/dashboard/game_settings_manager.dart` | Uncomment legacy import (line 5); may need `state_notifier` as a direct dependency |
| 18 other files using `StateProvider` | Legacy import — uncomment it in the six that already have it prepared, add it to the other twelve |
| 92 sites across `lib/` and `test/` | `.valueOrNull` becomes `.value` |
| Sites among the `ref.watch(...).value` reads | Only where the old throwing behaviour mattered |
| `test/` | Shared container helper with retry disabled (12 `ProviderContainer` uses across 10 files); 21 `overrideWith` uses updated as needed |

## Risks

**The `.value` audit is the biggest risk of this change.** A missed site does not fail to compile and does not fail a test. It shows an empty list where an error should have surfaced. Give this step its own review pass rather than folding it into the general compile-error cleanup.

**Pausing can leave non-viewer features reading stale data.** The chatbot intents read viewer providers with `ref.read` from outside the viewer pages. Once pausing is active, those providers hold old data until their tab is opened. The verify pass checks this directly; the fix, if needed, is an always-visible listener that keeps the provider active.

**Deep-`==` filtering fails quietly.** A suppressed notification is not a crash. The audit is bounded: only providers whose state type has a deep `==`, checked for listen-driven side effects.

**Pausing may not defer the recomputes.** The documentation says paused providers keep their state, but does not spell out rebuild timing. With phase 0 in place, the final CPU trace answers this directly. If the off-screen recomputes still run in full, the upgrade is still correct — record the result and let `mod-toggle-stutter` carry the jank work instead.
