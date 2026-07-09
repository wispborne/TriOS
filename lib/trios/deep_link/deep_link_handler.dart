import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/deep_link/deep_link_confirmation_dialog.dart';
import 'package:trios/trios/deep_link/deep_link_parser.dart';
import 'package:trios/trios/deep_link/single_instance_manager.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/logging.dart';
import 'package:window_manager/window_manager.dart';

/// Global [AppLinks] instance, initialized once in main().
late final AppLinks appLinks;

/// Navigator key for the root [MaterialApp] (set on it in main.dart). Lets this
/// non-widget handler obtain a [BuildContext] to show dialogs reliably.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Pending deep link URI from cold start (set before runApp).
String? pendingDeepLinkUri;

/// Ignore a URI seen again within this window — collapses the same link
/// arriving via multiple channels without dropping a different mod.
const _deepLinkDedupeWindow = Duration(seconds: 5);

/// Provider that manages deep link handling.
final deepLinkHandlerProvider = NotifierProvider<DeepLinkHandler, void>(
  DeepLinkHandler.new,
);

/// True while a deep-link install is being prepared — from the link being
/// raised until its confirmation dialog is ready (or the batch is otherwise
/// handled). UI that raised the link (e.g. a catalog Install button) can show
/// a busy indicator during this gap.
final deepLinkProcessing = StateProvider<bool>((ref) => false);

class DeepLinkHandler extends Notifier<void> {
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<FileSystemEvent>? _fileWatchSubscription;
  Timer? _pollTimer;

  /// URIs awaiting the next drain.
  final List<String> _queuedUris = [];

  /// URI -> last-seen epoch millis, for identity de-duplication.
  final Map<String, int> _recentlySeenMillis = {};

  /// Serializes the resolve/append section so concurrent batches don't race.
  bool _resolving = false;

  /// Live data behind the open confirmation dialog (null when none is open).
  /// New links merge into this so they appear in the same dialog.
  ValueNotifier<DeepLinkConfirmData>? _session;

  /// URLs already shown in the current dialog session (avoids duplicate rows).
  final Set<String> _sessionSeenUrls = {};

  @override
  void build() {
    // Listen for app_links stream (works on macOS warm-start).
    _linkSubscription = appLinks.uriLinkStream.listen(
      (uri) => _onUri(uri.toString()),
      onError: (err) => Fimber.w('app_links stream error: $err'),
    );

    // Start file-based IPC watcher for warm-start on Windows/Linux.
    _startFileWatcher();

    // Process pending cold-start URI if any.
    if (pendingDeepLinkUri != null) {
      final uri = pendingDeepLinkUri!;
      pendingDeepLinkUri = null;
      // Defer so the app is fully built before showing dialogs.
      Future.microtask(() => _onUri(uri));
    }

    ref.onDispose(() {
      _linkSubscription?.cancel();
      _fileWatchSubscription?.cancel();
      _pollTimer?.cancel();
    });
  }

  void _startFileWatcher() {
    // Deep links are forwarded to the lock owner's PID, so only the primary
    // (lock-owning) instance may drain the pending dir. A coexisting instance
    // (e.g. dev + release running together) must not also consume them, or the
    // two race and a link meant for the primary gets handled by the wrong one.
    if (!SingleInstanceManager.ownsLock()) {
      Fimber.i('Not the lock owner; skipping forwarded deep-link watcher.');
      return;
    }
    final dir = SingleInstanceManager.pendingDeepLinkDir;
    if (!dir.existsSync()) {
      try {
        dir.createSync(recursive: true);
      } catch (e) {
        Fimber.w('Could not create pending deep link dir: $e');
      }
    }

    // Drain anything already waiting (links forwarded during our startup).
    _drainPendingDir();

    try {
      _fileWatchSubscription = dir
          .watch(events: FileSystemEvent.create | FileSystemEvent.modify)
          .listen((_) => _drainPendingDir());
    } catch (e) {
      Fimber.w('FileSystemEntity.watch() failed, falling back to polling: $e');
    }

    // Fallback polling every 2 seconds (some Linux setups have inotify limits).
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _drainPendingDir();
    });
  }

  void _drainPendingDir() {
    final uris = SingleInstanceManager.drainPendingDeepLinks();
    if (uris.isEmpty) return;
    // A forwarded link means the user clicked while we were running — surface us.
    windowManager.show();
    windowManager.focus();
    for (final uri in uris) {
      _onUri(uri);
    }
  }

  /// Public entry point for links raised from inside the app (e.g. a catalog
  /// card's trios download). Feeds [rawUri] through the same queue, de-dupe,
  /// and confirmation flow as a link arriving from the OS.
  void handleUriString(String rawUri) => _onUri(rawUri);

  void _onUri(String rawUri) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Identity de-dupe: collapse the same link arriving via multiple channels
    // (cold-start + stream), without dropping a *different* mod clicked moments
    // later (which the old time-only gate did).
    final lastSeen = _recentlySeenMillis[rawUri];
    if (lastSeen != null &&
        now - lastSeen < _deepLinkDedupeWindow.inMilliseconds) {
      Fimber.d('Deep link de-duplicated: $rawUri');
      return;
    }
    _recentlySeenMillis[rawUri] = now;
    _recentlySeenMillis.removeWhere(
      (_, t) => now - t > _deepLinkDedupeWindow.inMilliseconds,
    );

    Fimber.i('Deep link received: $rawUri');
    _queuedUris.add(rawUri);
    ref.read(deepLinkProcessing.notifier).state = true;

    // Hop to a microtask so a same-turn burst (e.g. several files drained from
    // the pending dir at once) all queue before the drain runs. The drain loop
    // + `_resolving` guard coalesce the rest; no timer/latency needed.
    scheduleMicrotask(_drainAndProcess);
  }

  Future<void> _drainAndProcess() async {
    // Serialize resolve/append so concurrent batches don't race. The
    // confirmation dialog itself is shown OUTSIDE this lock (below), so links
    // clicked while it's open can still be resolved and merged into it.
    if (_resolving) return;
    if (_queuedUris.isEmpty) return;
    _resolving = true;
    bool createdSession = false;
    try {
      // On a cold start the deep link can arrive before the mod list (and the
      // mods-folder path) have finished their first load. Until then the
      // "already installed" checks read an empty mod list and every mod looks
      // missing, and the mods-folder guard can wrongly fire. Wait for the first
      // load to settle so the checks see the real installed mods.
      await _ensureModsLoaded();

      while (_queuedUris.isNotEmpty) {
        final uris = List<String>.from(_queuedUris);
        _queuedUris.clear();
        final requests = uris
            .map(parseDeepLink)
            .whereType<DeepLinkRequest>()
            .where((r) => r.action == DeepLinkAction.install)
            .toList();
        if (requests.isEmpty) continue;

        // Guards (cheap; re-checked per batch).
        if (ref.read(AppState.isGameRunning).value == true) {
          Fimber.w('Deep link install blocked: game is running.');
          _showError('Cannot install mods while Starsector is running.');
          continue;
        }
        if (ref.read(AppState.modsFolder).value == null) {
          Fimber.w('Deep link install blocked: mods folder not configured.');
          _showError(
            'Please configure your Starsector game directory before installing mods via links.',
          );
          continue;
        }

        // New entries this batch: each link's `mod` is a primary, its `dep`s
        // are deps. Skip URLs already shown this session (no duplicate rows);
        // a primary wins over a dependency.
        final batchPrimaryUrls = <String>{
          for (final r in requests) r.mainMod.url.toString(),
        };
        final newPrimaries = <DeepLinkModEntry>[];
        final newDeps = <DeepLinkModEntry>[];
        for (final r in requests) {
          if (_sessionSeenUrls.add(r.mainMod.url.toString())) {
            newPrimaries.add(r.mainMod);
          }
        }
        for (final r in requests) {
          for (final dep in r.dependencies) {
            final key = dep.url.toString();
            if (batchPrimaryUrls.contains(key)) continue;
            if (_sessionSeenUrls.add(key)) newDeps.add(dep);
          }
        }
        if (newPrimaries.isEmpty && newDeps.isEmpty) continue;

        final httpClient = ref.read(triOSHttpClient);
        final resolvedMods = await Future.wait(
          newPrimaries.map((e) => _resolveModEntry(e, httpClient)),
        );
        final resolvedDeps = await Future.wait(
          newDeps.map(
            (e) => _resolveModEntry(e, httpClient, isDependency: true),
          ),
        );

        final skipConfirmation = ref.read(
          appSettings.select((s) => s.deepLinkSkipConfirmation),
        );
        if (skipConfirmation) {
          for (final e in [...resolvedMods, ...resolvedDeps]) {
            if (!e.alreadyInstalled && e.error == null) _downloadAndInstall(e);
          }
          // No dialog session exists in skip mode, so the row-dedupe set has no
          // session to scope it to; release these URLs now, or the same link
          // would only ever install once per app run.
          for (final e in [...newPrimaries, ...newDeps]) {
            _sessionSeenUrls.remove(e.url.toString());
          }
          continue;
        }

        if (_session == null) {
          // First batch: create the session; this flush will show the dialog.
          _session = ValueNotifier(
            DeepLinkConfirmData(mods: resolvedMods, dependencies: resolvedDeps),
          );
          createdSession = true;
        } else {
          // A dialog is already open — merge into it so it updates live.
          final cur = _session!.value;
          _session!.value = DeepLinkConfirmData(
            mods: [...cur.mods, ...resolvedMods],
            dependencies: [...cur.dependencies, ...resolvedDeps],
          );
        }
      }
    } finally {
      _resolving = false;
      // Resolution is done; the confirmation dialog (if any) opens right
      // after this. Busy indicators watching this can stop now.
      ref.read(deepLinkProcessing.notifier).state = false;
    }

    // Only the flush that created the session shows the dialog (others merged).
    if (createdSession) {
      final session = _session!;
      final context = rootNavigatorKey.currentContext;
      List<ResolvedModEntry>? selected;
      if (context == null || !context.mounted) {
        Fimber.w('No BuildContext available for deep link dialog.');
      } else {
        // The dialog returns exactly the entries the user chose to install.
        selected = await showDeepLinkConfirmationDialog(
          context,
          data: session,
          ref: ref,
        );
      }
      _session = null;
      _sessionSeenUrls.clear();

      if (selected != null && selected.isNotEmpty) {
        for (final e in selected) {
          _downloadAndInstall(e);
        }
      } else {
        Fimber.i('Deep link install cancelled or nothing selected.');
      }

      // Links that arrived after the dialog closed start a fresh session.
      if (_queuedUris.isNotEmpty) Future.microtask(_drainAndProcess);
    }
  }

  /// Waits for the mod list the install checks rely on to finish loading.
  /// Reading `.future` returns immediately once things are ready, so this is
  /// only a real wait on a cold start. Errors are swallowed — if a provider
  /// fails to load we fall through and let the per-batch guards handle it.
  Future<void> _ensureModsLoaded() async {
    try {
      // The mod scan quietly returns an empty list until these paths resolve
      // (see reloadModVariants / getModsVariantsInFolder). On a cold start
      // they're still loading when the link arrives, so wait for them first —
      // otherwise the "already installed" checks run against an empty mod list
      // and every mod looks missing.
      await ref.read(AppState.gameFolder.future);
      await ref.read(AppState.gameCoreFolder.future);
      await ref.read(AppState.modsFolder.future);
      await ref.read(AppState.enabledModIds.future);

      // If the mod list was first built (empty) before those paths were ready,
      // its cached value is stale. Reload it now that the paths are set. An
      // empty result on a warm start means the user genuinely has no mods, so
      // the extra scan is a no-op.
      final variants = await ref.read(AppState.modVariants.future);
      if (variants.isEmpty) {
        ref.invalidate(AppState.modVariants);
        await ref.read(AppState.modVariants.future);
      }
    } catch (e) {
      Fimber.w('Deep link: error waiting for mods to load: $e');
    }
  }

  void _downloadAndInstall(ResolvedModEntry entry) {
    ref
        .read(downloadManager.notifier)
        .downloadAndInstallMod(
          entry.displayName,
          entry.downloadUrl.toString().fixModDownloadUrl(),
          activateVariantOnComplete: false,
          // The deep-link confirmation dialog already asked the user; don't make
          // the batch installer re-ask about already-installed mods.
          skipConfirmation: true,
        );
  }

  Future<ResolvedModEntry> _resolveModEntry(
    DeepLinkModEntry entry,
    TriOSHttpClient httpClient, {
    bool isDependency = false,
  }) async {
    // A dependency's version is a *minimum required version*: when a locally
    // installed copy already meets it (or the link omits a version and the dep
    // is installed at all), the dependency is satisfied and won't be installed
    // by default. We still resolve its real download URL below (rather than
    // short-circuiting on entry.url) so that if the user manually selects it in
    // the confirmation dialog, we download the actual archive — not the
    // .version file itself, which isn't a valid archive.
    final dependencySatisfied =
        isDependency && isDependencySatisfied(ref.read(AppState.mods), entry);

    if (entry.source == DeepLinkModSource.directDownload) {
      // No .version file to fetch, so the link-provided id + version are all we
      // have to decide whether this mod is already installed.
      return ResolvedModEntry(
        entry: entry,
        modVersion: entry.modVersion,
        downloadUrl: entry.url,
        alreadyInstalled:
            dependencySatisfied ||
            _isDirectDownloadAlreadyInstalled(entry.modId, entry.modVersion),
      );
    }

    // Fetch .version file.
    try {
      final versionInfo = await fetchRemoteVersionCheckerInfo(
        entry.url.toString(),
        httpClient,
      );

      // Check if already installed.
      final isInstalled =
          dependencySatisfied ||
          _isModAlreadyInstalled(versionInfo, entry.url, entry.modId);

      if (!versionInfo.hasDirectDownload) {
        return ResolvedModEntry(
          entry: entry,
          modName: versionInfo.modName,
          modVersion: versionInfo.modVersion?.toString() ?? entry.modVersion,
          downloadUrl: entry.url,
          alreadyInstalled: isInstalled,
          error:
              "The mod's version file has no download link and cannot be automatically installed.",
        );
      }

      // The .version file is fetched from the network and otherwise trusted —
      // re-validate its download URL is http/https before we'll download it.
      final resolvedUrl = validateHttpUrl(versionInfo.directDownloadURL!);
      if (resolvedUrl == null) {
        return ResolvedModEntry(
          entry: entry,
          modName: versionInfo.modName,
          modVersion: versionInfo.modVersion?.toString() ?? entry.modVersion,
          downloadUrl: entry.url,
          alreadyInstalled: isInstalled,
          error: "The mod's download link isn't a valid http/https URL.",
        );
      }

      return ResolvedModEntry(
        entry: entry,
        modName: versionInfo.modName,
        modVersion: versionInfo.modVersion?.toString() ?? entry.modVersion,
        downloadUrl: resolvedUrl,
        alreadyInstalled: isInstalled,
      );
    } on VersionFileFetchException catch (e) {
      return ResolvedModEntry(
        entry: entry,
        modVersion: entry.modVersion,
        downloadUrl: entry.url,
        alreadyInstalled: dependencySatisfied,
        error: "Couldn't fetch the mod's version file (HTTP ${e.statusCode}).",
      );
    } catch (e) {
      Fimber.w('Error fetching .version file: ${entry.url}', ex: e);
      return ResolvedModEntry(
        entry: entry,
        modVersion: entry.modVersion,
        downloadUrl: entry.url,
        alreadyInstalled: dependencySatisfied,
        error: "Couldn't read the mod's version file.",
      );
    }
  }

  bool _isModAlreadyInstalled(
    VersionCheckerInfo versionInfo,
    Uri linkUrl,
    String? modId,
  ) {
    // Identify the local mod by, in order of reliability:
    //  1. mod id, when the link supplied one (exact; unaffected by shared
    //     forum threads), else
    //  2. the mod's own Version Checker (.version) URL — the clicked link or
    //     its declared masterVersionFile.
    // Deliberately NOT matched by forum thread id (authors host several mods on
    // one thread) or mod name (can collide) — both cause false matches.
    // Normalize all .version URLs with fixUrl before comparing so that a
    // GitHub blob vs raw (or Dropbox dl=0 vs dl=1) form of the same link still
    // matches.
    final linkUrlStr = fixUrl(linkUrl.toString());
    final remoteMaster = versionInfo.masterVersionFile?.let(fixUrl);
    final remoteVersion = versionInfo.modVersion;
    final mods = ref.read(AppState.mods);

    for (final mod in mods) {
      final matched =
          (modId != null && mod.id == modId) ||
          mod.modVariants.any((v) {
            final localMaster = v.versionCheckerInfo?.masterVersionFile?.let(
              fixUrl,
            );
            return localMaster != null &&
                (localMaster == linkUrlStr ||
                    (remoteMaster != null && localMaster == remoteMaster));
          });
      if (!matched) continue;

      // Matched. "Already installed" only when a local version is >= the remote
      // one (otherwise it's an update and should download). With no remote
      // version, or no comparable local version, treat the match as installed.
      if (remoteVersion == null) return true;
      var sawLocalVersion = false;
      final remoteResult = RemoteVersionCheckResult(null, versionInfo, null);
      for (final v in mod.modVariants) {
        if (v.versionCheckerInfo?.modVersion == null) continue;
        sawLocalVersion = true;
        // Reuse the canonical local-vs-remote comparison so "already installed"
        // stays in sync with how the rest of the app decides updates
        // (>= 0 ⇒ local is the same version or newer).
        final cmp = VersionCheckComparison.compareLocalAndRemoteVersions(
          v.versionCheckerInfo,
          remoteResult,
        );
        if (cmp != null && cmp >= 0) return true;
      }
      return !sawLocalVersion;
    }
    return false;
  }

  /// Already-installed check for direct-download links, which carry no
  /// `.version` file to fetch. The link-provided [modId] is the only reliable
  /// key here (a download URL isn't a stable identity), so match on it; then,
  /// if the link also provided [versionString], report installed only when a
  /// local copy is the same version or newer — an older local copy is an update
  /// and should download. An id match with no provided version, or no
  /// comparable local version, counts as installed.
  bool _isDirectDownloadAlreadyInstalled(String? modId, String? versionString) {
    if (modId == null) return false;
    final mods = ref.read(AppState.mods);

    for (final mod in mods) {
      if (mod.id != modId) continue;

      if (versionString == null) return true;
      final remoteVersion = Version.parse(versionString, sanitizeInput: false);
      var sawLocalVersion = false;
      for (final v in mod.modVariants) {
        final localVersion = v.bestVersion;
        if (localVersion == null) continue;
        sawLocalVersion = true;
        // Same version or newer locally ⇒ already installed (>= 0).
        if (localVersion >= remoteVersion) return true;
      }
      return !sawLocalVersion;
    }
    return false;
  }

  void _showError(String message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    showAlertDialog(context, title: 'Cannot Install Mod', content: message);
  }
}

/// True when a dependency [entry] is already satisfied by [mods]. A
/// version-bearing entry treats its version as a *minimum* — satisfied when an
/// installed copy is `>=` it. A version-less entry is satisfied whenever the
/// dependency is installed at all (install only if missing).
bool isDependencySatisfied(List<Mod> mods, DeepLinkModEntry entry) {
  final installed = installedVersionForDependency(mods, entry);
  if (installed == null) return false;
  final minString = entry.modVersion;
  if (minString == null) return true;
  return installed >= Version.parse(minString, sanitizeInput: false);
}

/// Highest locally-installed version among [mods] of the mod a dependency
/// [entry] points to, or null if not installed. Matches by mod id when the link
/// supplied one, else (for a `.version` entry) by the link URL vs a local
/// variant's `masterVersionFile`, both normalized with [fixUrl]. No network.
Version? installedVersionForDependency(List<Mod> mods, DeepLinkModEntry entry) {
  final modId = entry.modId;
  final linkUrlStr = fixUrl(entry.url.toString());

  for (final mod in mods) {
    final matched =
        (modId != null && mod.id == modId) ||
        (entry.source == DeepLinkModSource.versionFile &&
            mod.modVariants.any((v) {
              final localMaster = v.versionCheckerInfo?.masterVersionFile?.let(
                fixUrl,
              );
              return localMaster != null && localMaster == linkUrlStr;
            }));
    if (!matched) continue;
    return mod.findHighestVersion?.bestVersion;
  }
  return null;
}
