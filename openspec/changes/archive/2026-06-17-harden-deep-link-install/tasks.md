# Harden Deep-Link Install — Tasks

## Fix 1 + 3 — Dialog context & `Ref` (blocker)

- [x] Add a top-level `rootNavigatorKey = GlobalKey<NavigatorState>()` (placed in `deep_link_handler.dart` to avoid a circular import with `main.dart`) and set `navigatorKey: rootNavigatorKey` on the root `MaterialApp` in `lib/main.dart`.
- [x] In `deep_link_confirmation_dialog.dart`, change `showDeepLinkConfirmationDialog`'s `required WidgetRef ref` and `_DeepLinkConfirmationDialog.ref` to `Ref`.
- [x] In `deep_link_handler.dart`, delete `_findContext()` and replace its uses in `_handleInstall` and `_showError` with `rootNavigatorKey.currentContext`.
- [x] In `deep_link_handler.dart`, remove the `as WidgetRef` cast — pass `ref` directly.
- [ ] Verify: a `starsector-mod://install?mod=...` link shows the confirm dialog without crashing (was the `as WidgetRef` runtime error).

## Fix 2 + 6 — Receive URI from argv + liveness-aware single instance (blocker)

This is the fix for the live symptoms (a) no download and (b) new instance every click — both
caused by `main()` discarding argv and leaning on `getInitialLink()`.

- [x] Change `lib/main.dart` `void main()` → `void main(List<String> args)`. (Windows runner already forwards argv via `set_dart_entrypoint_arguments`.)
- [x] In `single_instance_manager.dart`, finish `forwardDeepLinkIfSecondary(args)`: extract the deep-link URI from argv (`extractDeepLinkFromArgs`); if none → false; if no lock file → false; read the PID from the lock and check the process is alive (Windows `tasklist`; macOS/Linux `kill -0` via `Process.runSync`, fallback `ps -p`); if alive → write `pending_deeplink` + return true; if stale → false.
- [x] In `lib/main.dart`, replace the inline `getInitialLink` forwarding block: call `SingleInstanceManager.forwardDeepLinkIfSecondary(args)` and `exit(0)` on true. On the cold-start (non-forward) path, set `pendingDeepLinkUri` from the argv URI.
- [x] Keep `app_links` for macOS: `getInitialLink()` for macOS cold start and `uriLinkStream` (already wired in the handler) for warm start, since macOS delivers via `openURLs`, not argv. Guard the argv path to Windows/Linux so macOS isn't double-handled.
- [x] In `lib/main.dart`, write the current process PID into `running.lock` (replace the timestamp). Crash detection still works (it only checks existence).
- [ ] Verify (cold, Windows): with TriOS closed, click a link → TriOS opens AND downloads (was: opened, no download).
- [ ] Verify (warm, Windows): with TriOS already open, click a link → NO new instance; existing window focuses and installs (was: new instance every time).
- [ ] Verify (stale lock): leave a `running.lock` with a dead PID, click a link → app stays open and installs (does NOT exit).

## Fix 4 — Validate & surface download URL

- [x] In `deep_link_handler.dart._resolveModEntry`, after extracting `directDownloadURL`, reject it (return a `ResolvedModEntry` with an error) if it doesn't parse as http/https. Exposed `deep_link_parser._validateUrl` as public `validateHttpUrl` and reused it.
- [x] In `deep_link_confirmation_dialog.dart`, change `ResolvedModEntry.displayDetail` to show `downloadUrl.host` (the real byte source) instead of `entry.url.host`. Keep the version prefix.
- [ ] Verify: a `.version` link whose `directDownloadURL` points to a different host shows that host in the dialog; a `file://`/non-http download URL is rejected with an error row.

## Fix 5 — Broaden "already installed" matching

- [x] In `deep_link_handler.dart._isModAlreadyInstalled`, identify a local variant by the mod's own Version Checker URL: local `masterVersionFile` equals the clicked link URL OR the remote `.version`'s `masterVersionFile`. Then apply the version comparison (local >= remote ⇒ installed; null remote version ⇒ installed on match). **Deliberately NOT matched by `modThreadId` (authors host several mods on one thread → false matches) or `modName` (can collide).** Trade-off: a mod whose `.version` declares no `masterVersionFile` won't be detected as installed (benign — it's re-offered rather than a wanted mod being hidden).
- [x] Expose `deepLinkSkipConfirmation` on the settings page (`settings_page.dart`) as a `CheckboxWithLabel` ("Always install mods from links without confirming"), bound directly to the setting with a tooltip — so a user who ticked "always install" in the dialog can untick it and get the confirmation dialog back.
- [x] Optional `modId` per entry (extensible link format): each `mod`/`dep` value may be a bare URL (legacy) OR a JSON object `{"url":...,"id":...}` — sniffed by a leading `{`; `url` required, `id` optional, unknown keys ignored (room for future fields). When `id` is present, `_isModAlreadyInstalled` matches by exact `mod.id` (bulletproof on shared threads), else falls back to the URL logic. The "Copy install link" generator now emits the JSON form with the mod's id; the confirm dialog shows the id in its provenance lines. Parser: `_parseEntry`; model: `DeepLinkModEntry.modId`.
- [ ] Verify: clicking a link for an already-installed mod (matched by name/thread id, no `masterVersionFile`) shows it as "Already installed" and skips download.

## Fix 7 — "Copy install link" author action

- [x] In `lib/trios/context_menu_items.dart`, add `buildMenuItemCopyInstallLink(modVariant, context)`; registered it in `mod_context_menu.dart` next to "Open Forum Page". Builds `starsector-mod://install?mod=${Uri.encodeComponent(url)}` where `url` is `versionCheckerInfo?.masterVersionFile ?? versionCheckerInfo?.directDownloadURL`.
- [x] If neither URL exists: matched the existing `buildMenuItemOpenForumPage` convention — greyed "(unavailable)" label (`iconOpacity: 0.5`) + an explanatory `showSnackBar` on tap. (The `flutter_context_menu` `MenuItem` has no tooltip slot, so `MovingTooltipWidget` doesn't apply here.)
- [x] On tap: copy to clipboard (`Clipboard.setData`) and `showSnackBar` an info confirmation.
- [ ] Verify: the copied link installs the mod when pasted into the OS run dialog / browser address bar (not forum-click — documented limitation).

## Fix 8 — Multiple links (queue + dedupe + single dialog)

- [x] `single_instance_manager.dart`: replaced the single `pending_deeplink` file with a `pending_deeplinks/` directory; forwarding writes a uniquely-named `<pid>_<micros>.deeplink` file (no overwrite). Exposed `pendingDeepLinkDir` + `drainPendingDeepLinks()`.
- [x] `single_instance_manager.dart`: added atomic `acquireLockOrForward({String? deepLink})` using `createSync(exclusive: true)` + PID write, subsuming crash detection. Returns `LockAcquisition` (freshStart / tookOverStaleLock / coexistingInstance / forwardedAndShouldExit). Brief retry (`_readOwnerPidWithRetry`) on the empty-mid-create window. Exposed `isProcessAlive` + `ownsLock`.
- [x] `lib/main.dart`: replaced the separate forward + crash-detection blocks with a single `acquireLockOrForward` call; `exit(0)` on forwardedAndShouldExit; `didPreviousSessionCrash` from the result. Clean-exit delete now guarded by `SingleInstanceManager.ownsLock()`.
- [x] `deep_link_handler.dart`: replaced the time-only rate limiter with URI-identity dedupe (`_recentlySeenMillis`, 5s window); enqueue incoming URIs and `scheduleMicrotask(_drainAndProcess)` (no debounce timer — the drain loop coalesces bursts at zero latency).
- [x] `deep_link_handler.dart`: `_drainAndProcess` loops `while (queue not empty)` → parses all → collects primary + dependency entries → dedupes by URL (primary wins) → runs guards → resolves in parallel → one dialog → installs all non-installed/non-error entries. File watcher now drains all `*.deeplink` files from `pending_deeplinks/`.
- [x] `deep_link_confirmation_dialog.dart`: driven by a `ValueListenable<DeepLinkConfirmData>` via `ValueListenableBuilder` so it updates live; renders the mods list + dependencies + a combined already-installed section, in a `SingleChildScrollView`.
- [x] `deep_link_handler.dart`: merge links clicked while a dialog is open into the *same* dialog via a `_session` `ValueNotifier` (no stacking, no follow-up dialog). `_resolving` serializes resolve/append (not the dialog await); one flush owns the dialog, others merge; `_sessionSeenUrls` dedupes rows.
- [ ] Verify (click during open dialog): click a link, then click another *while the first dialog is open* → the second mod appears in the same dialog; confirming once installs all.
- [x] Error presentation polish (from real-run screenshot): user-facing error strings instead of raw parser/exception dumps (full error still logged); name falls back to the URL filename (e.g. "RandomAssortmentOfThings") not the bare host; errored entries excluded from the install count, shown in a muted "Couldn't load (N)" section, and the install button shows the real count (`Download & Install (N)`, disabled at 0).
- [x] Bucket precedence (from 2nd screenshot): already-installed wins over a download error (a mod we already have isn't a "problem"), so an installed mod with no download link shows under "Already installed", not "Couldn't load" — fixed the contradictory ✓-icon-with-error tile. When nothing is installable because it's all already installed, the intro reads "You already have everything from this link." rather than "can't install anything".
- [x] Tile color follows precedence too: `hasError` excludes already-installed, so an installed mod's "Already installed" detail no longer renders in the error color (3rd screenshot).
- [x] Provenance for tracing (requested): each tile shows small, selectable URL lines (icon + URL) — the source link, plus the resolved download URL when a `.version` points elsewhere. Lets the user read/copy exactly which link/version-checker file was used and where it resolves. (Raw `starsector-mod://` deep link itself not surfaced — per-mod URLs cover tracing; can add if wanted.)
- [x] Restyle after the bulk install dialog (`mod_install_selection_dialog.dart`): `ConstrainedBox(minWidth 400, maxWidth 620)` instead of fixed width; `Flexible` + `SingleChildScrollView` for the list with the "always install" toggle pinned below a `Divider` (via `CheckboxWithLabel`); each mod in a `Card.outlined` with a status icon, name, detail, and the icon-prefixed provenance lines; section headers via a small helper.
- [x] Group by role, not status: main mods at the top, then a single "Dependencies (N)" group (already excludes deps that are also main mods, deduped by URL upstream). Within each role, sort to-install → couldn't-load → already-installed. Removed the separate "Already installed"/"Couldn't load" sections — status is conveyed per-tile (icon, detail, strikethrough) and by sort order.
- [x] Per-mod checkboxes (like the batch install dialog): selectable entries are `CheckboxListTile`s in a `Card.outlined` (primary border when selected); errored entries are non-selectable (error-icon `ListTile`). Default selection mirrors batch logic — pre-select installable entries that aren't already present (same mod id + version, via `alreadyInstalled`); already-installed and errored start unchecked. Selection is keyed by source URL and reconciled as links merge in (new entries get the default applied once, without overriding the user's picks). The dialog now returns the chosen `List<ResolvedModEntry>` (or null), and the handler installs exactly that; button reads "Download & Install (N)" / disabled "No mods selected".
- [x] Explain the non-selectable state (from screenshot): an already-installed mod whose link has no download (e.g. LazyLib) was showing an error icon with no reason. Now it gets a check icon (it's satisfied, not a problem) and an italic note surfacing the reason ("…no direct download link.") so the user understands why it has no checkbox. Restored the strikethrough on already-installed names.
- [ ] Verify (errors): a link with a malformed `.version` or a dep with no direct download shows a clean reason under "Couldn't load", the count/button reflect only installable mods, and confirming installs only the good ones.
- [ ] Verify (multi, warm): click 3 different links quickly with TriOS open → one dialog lists all 3 (+ deps), no instance spawned, all install.
- [ ] Verify (dedupe): the same link firing via cold-start + stream is shown once, not twice.
- [ ] Verify (cold race): two quick clicks with TriOS closed → one window, one dialog with both mods.

## Wrap-up

- [x] Analysis clean for touched files. (Local Flutter SDK 3.44.0 < project pin 3.44.2 blocked `flutter analyze`; used `dart format` (parses without pub resolution — all files valid) + the IDE analyzer via the `idea` connector — all 7 touched files report zero errors after re-index. Remaining warnings are pre-existing only: `main.dart` `chipper/utils` import + `print`s.)
- [x] No leftover unused imports/symbols from these edits: removed `_findContext` and the now-unused `constants` import in the handler; dialog `WidgetRef`→`Ref` keeps `flutter_riverpod`; new `flutter/services` + `deep_link_parser` imports are used. Added a `context.mounted` guard before the confirm dialog. Ran `dart format` on all touched files.
- [ ] Manual smoke test of the full path: register protocol → click/paste a real `.version` link → dialog shows correct name + download host → install completes. *(Manual — needs a build with Flutter 3.44.2.)*
