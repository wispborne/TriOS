# Harden Deep-Link Install — Design

All changes are surgical edits to the existing `wip-deep-links` code. No new
architecture; the download/install pipeline (`downloadAndInstallMod`) is reused as-is.

## Fix 1 + 3 — Reliable dialog context, `Ref` instead of `WidgetRef`

The two are coupled: both are about giving the handler a dependable way to show dialogs.

**Navigator key.** Add a top-level key and attach it to the root `MaterialApp`
(`lib/main.dart:501`):

```dart
final rootNavigatorKey = GlobalKey<NavigatorState>();
// ...
return MaterialApp(
  navigatorKey: rootNavigatorKey,
  ...
);
```

In `deep_link_handler.dart`, replace `_findContext()` (the `visitChildren` walk) with
`rootNavigatorKey.currentContext`. Both `_handleInstall` (confirm dialog) and `_showError`
use it. If `currentContext` is null (app not yet mounted), the existing cold-start
`Future.microtask` defer in `build()` already runs after the first frame; keep that.

**`Ref` not `WidgetRef`.** The confirm dialog only uses `ref` for
`ref.read(appSettings.notifier).update(...)`. `Ref` exposes `.read`, so:

- In `deep_link_confirmation_dialog.dart`, change `showDeepLinkConfirmationDialog`'s
  `required WidgetRef ref` and the `_DeepLinkConfirmationDialog.ref` field to `Ref`.
- In `deep_link_handler.dart:177`, drop the `as WidgetRef` cast and pass `ref` directly
  (a `Notifier`'s `ref` is already a `Ref`).

This removes the runtime cast crash with no behavior change.

## Fix 2 + 6 — Receive the URI from argv, liveness-aware single-instance

**Live root cause (confirmed against a working launcher website).** Two reported symptoms —
(a) nothing downloads, (b) a new instance opens on every click even when one is running —
trace to a single bug: `lib/main.dart` declares `void main()` with **no `args` parameter**,
so the URI that the Windows runner already forwards on argv
(`set_dart_entrypoint_arguments`, `windows/runner/main.cpp:25`) is discarded. Reception then
leans entirely on `appLinks.getInitialLink()`, which returns null on Windows; when it does,
the cold path stores nothing (→ no download) and the warm path skips the forward block
entirely (→ new instance). `SingleInstanceManager.forwardDeepLinkIfSecondary` /
`extractDeepLinkFromArgs` were built to read argv but are never called (dead code, fix 6).
The `ref as WidgetRef` crash (fix 1) is latent — execution never reaches it until reception
is fixed.

**Platform split for reception:**

- **Windows/Linux** — argv is the source of truth. Change `main` to `void main(List<String>
  args)`; the native runner already passes the URI. Use
  `SingleInstanceManager.extractDeepLinkFromArgs(args)`.
- **macOS** — keep `app_links` (`getInitialLink()` for cold start, `uriLinkStream` for warm),
  because macOS delivers the URL via `application:openURLs:`, not argv.

The secondary bug on top of reception: forwarding keys off mere existence of `running.lock`,
which is also the crash-detection marker and is routinely stale.

**Liveness signal.** Write the current PID into `running.lock` (the crash-detection code
already writes a timestamp there — switch it to the PID, or add the PID, keeping crash
detection working since it only checks existence). On a possible-secondary launch, read the
PID and check whether that process is actually alive:

- Windows: `tasklist /FI "PID eq <pid>"` and look for the pid, or `Process.killPid(pid, ProcessSignal.sigterm)` dry-run alternatives — prefer a read-only check via `tasklist`.
- macOS/Linux: `Process.killPid(pid, ProcessSignal.sigusr... )` is intrusive; use a
  read-only check (`kill -0` semantics) via `Process.runSync('kill', ['-0', '$pid'])`
  (exit 0 = alive). Fallback to `ps -p <pid>`.

Forward (write `pending_deeplink` + `exit(0)`) **only if the PID is alive**. If the lock is
stale (no such process), treat as "not running": delete/overwrite the stale lock and let
this instance handle the deep link as a cold start.

**One home for the logic.** `forwardDeepLinkIfSecondary` in `SingleInstanceManager` becomes
the single source of truth — it takes the URI (from argv on Windows/Linux, app_links on
macOS) and does the liveness check. `lib/main.dart` (now `void main(List<String> args)`)
calls it instead of the inline `getInitialLink` block and `exit(0)`s on a `true` return.
The cold-start path stores `pendingDeepLinkUri` from the same URI when not forwarding. This
removes the dead code (fix 6) and restores reception (the no-download / new-instance
symptoms) in one move.

Note: `app_links.getInitialLink()` supplies the launch URI on all desktop platforms;
`SingleInstanceManager` already has `extractDeepLinkFromArgs` for the raw-args path. Use
whichever main.dart already has in hand — keep it to one.

## Fix 4 — Validate and surface the real download URL

In `deep_link_handler.dart._resolveModEntry`, after reading `directDownloadURL` from the
fetched `.version` file, validate its scheme before using it:

```dart
final resolved = Uri.tryParse(versionInfo.directDownloadURL!);
if (resolved == null || (resolved.scheme != 'http' && resolved.scheme != 'https')) {
  return ResolvedModEntry(..., error: 'Download URL is not http/https');
}
```

Reuse the same http/https rule as `deep_link_parser._validateUrl` (extract a shared helper
if convenient).

**Surface the source.** `ResolvedModEntry.displayDetail` currently shows `entry.url.host`
— for a `.version` link that's the `.version` host, not the file host. Change it to show
`downloadUrl.host` (the actual byte source) so the confirmation dialog reflects where the
download comes from. Keep showing the version when present.

## Fix 5 — Broaden "already installed" matching

A `.version` file has **no mod id** (fields: `modName`, `masterVersionFile`, `modNexusId`,
`modThreadId`, `modVersion`, `directDownloadURL`, `changelogURL`). So matching cannot key on
mod id. Broaden `_isModAlreadyInstalled` to match a local variant when **any** of these
agree (in priority order), then version-compare:

1. `masterVersionFile` equal (current behavior), or
2. `modThreadId` equal (both non-null), or
3. `modName` equal, case-insensitive (both non-null).

If a match is found, keep the existing rule: installed counts as "already installed" only
when local `modVersion >= remote modVersion`; otherwise it's an update and should download.
If remote `modVersion` is null, fall back to "matched ⇒ already installed" (no version info
to compare).

## Fix 7 — "Copy install link" author action

Add a menu item to `lib/mod_manager/mod_context_menu.dart` that builds and clipboard-copies
a `starsector-mod://install?mod=<encoded>` link for the selected mod/variant.

**Which URL goes in `mod=`.** The handler auto-detects `.version` URLs and resolves
metadata, so prefer the variant's `versionCheckerInfo?.masterVersionFile`. Fall back to
`versionCheckerInfo?.directDownloadURL`. If neither exists, disable the menu item with a
`MovingTooltipWidget.text` explaining the mod has no version/download URL to link to.

```dart
final url = vci?.masterVersionFile ?? vci?.directDownloadURL;
final link = 'starsector-mod://install?mod=${Uri.encodeComponent(url)}';
// Clipboard.setData(ClipboardData(text: link)); + showSnackBar(info)
```

Show a `showSnackBar` info confirmation after copying. Per the project convention, attach a
tooltip to the menu item.

**Documented limitation (no code).** A raw `starsector-mod://` link fails when clicked from
a forum post (forum opens it in a new window; browsers block custom-protocol launch from a
fresh new-window navigation). The copied link works for address-bar paste, Discord, and a
future https landing page. This limitation is recorded in `proposal.md`; the landing page is
out of scope here.

## Fix 8 — Handle multiple links (queue + dedupe + single dialog)

Today each link is processed independently and a time-only rate limiter
(`_minDeepLinkInterval`) drops anything within 2s — including a *different* mod —
while the single overwrite-only `pending_deeplink` file loses concurrent warm
clicks, and two cold clicks can both become primary.

**Reception (no loss).** Replace the single `pending_deeplink` file with a
`pending_deeplinks/` directory; each forwarding secondary writes a uniquely-named
file (`<pid>_<n>.deeplink`) so concurrent writers never overwrite each other. The
primary watches the directory (plus the existing poll fallback) and drains *all*
`*.deeplink` files, reading and deleting each.

**Dedupe by identity, not time.** Drop the blanket time gate. Instead track
recently-seen URIs and ignore a URI seen again within a few seconds (this still
collapses the same link arriving via multiple channels — cold-start + stream —
without dropping a genuinely different mod).

**One dialog for a burst.** Incoming URIs are appended to an in-memory queue;
`_onUri` schedules a microtask to drain it (no debounce timer — a same-turn burst
queues together before the drain runs, and the drain loop below coalesces the rest
at zero latency). Draining parses each link, collects every mod entry (each link's
`mod` as a primary plus its `dep`s), dedupes by URL, resolves all in parallel, and
shows **one** confirmation dialog. Because the dialog isn't shown until the
`while (queue not empty)` loop empties, and the `_resolving` guard funnels
concurrent clicks into that same loop, a fast burst lands in one dialog with no
delay.

**One live dialog (merge).** The drain loop coalesces a burst into the first
dialog, but a link clicked *after* the dialog is open must fold into the *same*
dialog, not pop a second one. The dialog is driven by a `ValueNotifier<DeepLinkConfirmData>`
(`_session`) and rendered through a `ValueListenableBuilder`, so appending entries
rebuilds it live. A `_resolving` flag serializes only the resolve/append section
(not the dialog `await`), so a batch that arrives while the dialog is open resolves
its links and merges them into `_session`; the open dialog grows. Exactly one flush
— the one that finds `_session == null` and creates it inside the serialized
section — owns showing the dialog; all others merge. A `_sessionSeenUrls` set
prevents duplicate rows when the same URL is clicked twice. On close, `_session` is
reset and everything still in it is installed (if confirmed); links that arrive
afterward start a fresh session.
The dialog generalizes from a single `mainMod` to a `List<ResolvedModEntry> mods`
(primary mods) alongside the existing dependencies/already-installed sections.

**Cold-start race.** `SingleInstanceManager` acquires `running.lock` via an atomic
`createSync(exclusive: true)` and writes its PID. This subsumes the old crash
detection: fresh create ⇒ clean start; create fails + owner alive ⇒ forward (deep
link) or coexist (normal launch); create fails + owner dead/unparseable ⇒ stale
lock, take it over and set `didPreviousSessionCrash`. A brief retry covers the
microsecond window where the winner has created but not yet written its PID. The
clean-exit delete only removes the lock if this process owns it (PID match), so a
coexisting second instance can't delete the primary's lock.

## Files touched

| File | Change |
|------|--------|
| `lib/main.dart` | `void main(List<String> args)`; add `rootNavigatorKey`, set on `MaterialApp`; replace inline `getInitialLink` forwarding with `SingleInstanceManager` call fed by argv (Windows/Linux) / app_links (macOS); write PID to `running.lock` |
| `lib/trios/deep_link/deep_link_handler.dart` | Use `rootNavigatorKey.currentContext`; drop `as WidgetRef`; validate resolved download URL; broaden `_isModAlreadyInstalled`; remove `_findContext()` |
| `lib/trios/deep_link/deep_link_confirmation_dialog.dart` | `WidgetRef` → `Ref`; `displayDetail` shows `downloadUrl.host` |
| `lib/trios/deep_link/single_instance_manager.dart` | Implement liveness-aware `forwardDeepLinkIfSecondary`; becomes the one forwarding path |
| `lib/mod_manager/mod_context_menu.dart` | New "Copy install link" item |

## Risks / open questions

- **Liveness check via subprocess** (`tasklist` / `kill -0` / `ps`) adds a small startup
  cost on a deep-link launch only. Acceptable; it runs only when a lock exists.
- **PID reuse**: a stale PID could coincidentally match a live unrelated process. Low risk;
  the window is small and worst case is one missed forward (handled as cold start). Could be
  hardened later by also storing process start time, but not in scope.
- **Landing page** (forum-click transport) remains the main unresolved item for real-world
  forum adoption — tracked as a future change.
