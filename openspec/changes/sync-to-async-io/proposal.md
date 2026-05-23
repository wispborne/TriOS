# Proposal: Convert Synchronous I/O to Async

## Problem

The codebase has ~150+ synchronous file/process I/O calls (`readAsStringSync`, `writeAsStringSync`, `existsSync`, `listSync`, `Process.runSync`, etc.) scattered across ~30 files. These block the Dart event loop and can cause UI jank — especially during:

- App startup (settings loading via `loadSync`/`writeSync`)
- Mod installation and management (directory listings, file copies)
- Archive extraction (synchronous file reads in 7-Zip wrapper)
- Cache operations (synchronous reads/writes in `CachedJsonFetcher`)

While some sync calls are harmless (e.g., a single `existsSync` check), others perform multi-file directory scans or read large files on the main isolate.

## Proposed Solution

Convert sync I/O calls to their async equivalents where the call site can support `await`. Prioritize by impact:

1. **Settings persistence** — `app_settings_logic.dart` uses `protectSync`/`readAsStringSync`/`writeAsStringSync`. Convert to async lock + async I/O.
2. **Directory listings** — `listSync()` calls in mod scanning, ship/weapon managers, self-updater. Convert to `list()` streams or `await list().toList()`.
3. **File reads/writes in managers** — `readAsStringSync`/`writeAsStringSync` in cache, enabled mods, VM params, mod profiles.
4. **Process execution** — `Process.runSync` calls for 7-Zip, `uname`, `chmod`. Convert to `Process.run`.

## Scope

- Convert sync calls where the call site is already async or can be made async without major refactoring.
- Skip sync calls in synchronous-only contexts (e.g., `late final` initializers, constructors) unless the surrounding code can be restructured simply.
- Skip trivial `existsSync` guard checks where converting would add complexity with no real benefit.

## Non-Goals

- Moving I/O to separate isolates (that's a bigger effort).
- Changing the settings architecture (just the I/O layer).
- Refactoring call-site control flow beyond what's needed for `async`/`await`.
