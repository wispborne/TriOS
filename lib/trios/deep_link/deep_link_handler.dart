import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/version_checker.dart';
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
          newDeps.map((e) => _resolveModEntry(e, httpClient)),
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

  void _downloadAndInstall(ResolvedModEntry entry) {
    ref
        .read(downloadManager.notifier)
        .downloadAndInstallMod(
          entry.displayName,
          entry.downloadUrl.toString().fixModDownloadUrl(),
          activateVariantOnComplete: false,
        );
  }

  Future<ResolvedModEntry> _resolveModEntry(
    DeepLinkModEntry entry,
    TriOSHttpClient httpClient,
  ) async {
    if (entry.source == DeepLinkModSource.directDownload) {
      return ResolvedModEntry(entry: entry, downloadUrl: entry.url);
    }

    // Fetch .version file.
    try {
      final versionInfo = await fetchRemoteVersionCheckerInfo(
        entry.url.toString(),
        httpClient,
      );

      // Check if already installed.
      final isInstalled = _isModAlreadyInstalled(
        versionInfo,
        entry.url,
        entry.modId,
      );

      if (!versionInfo.hasDirectDownload) {
        return ResolvedModEntry(
          entry: entry,
          modName: versionInfo.modName,
          modVersion: versionInfo.modVersion?.toString(),
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
          modVersion: versionInfo.modVersion?.toString(),
          downloadUrl: entry.url,
          alreadyInstalled: isInstalled,
          error: "The mod's download link isn't a valid http/https URL.",
        );
      }

      return ResolvedModEntry(
        entry: entry,
        modName: versionInfo.modName,
        modVersion: versionInfo.modVersion?.toString(),
        downloadUrl: resolvedUrl,
        alreadyInstalled: isInstalled,
      );
    } on VersionFileFetchException catch (e) {
      return ResolvedModEntry(
        entry: entry,
        downloadUrl: entry.url,
        error: "Couldn't fetch the mod's version file (HTTP ${e.statusCode}).",
      );
    } catch (e) {
      Fimber.w('Error fetching .version file: ${entry.url}', ex: e);
      return ResolvedModEntry(
        entry: entry,
        downloadUrl: entry.url,
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

  void _showError(String message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    showAlertDialog(context, title: 'Cannot Install Mod', content: message);
  }
}
