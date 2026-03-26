import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/deep_link/deep_link_confirmation_dialog.dart';
import 'package:trios/trios/deep_link/deep_link_parser.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/logging.dart';
import 'package:window_manager/window_manager.dart';

/// Global [AppLinks] instance, initialized once in main().
late final AppLinks appLinks;

/// Pending deep link URI from cold start (set before runApp).
String? pendingDeepLinkUri;

/// Minimum interval between processing deep links (ms).
const _minDeepLinkInterval = 2000;
int _lastDeepLinkTimestamp = 0;

/// Provider that manages deep link handling.
final deepLinkHandlerProvider =
    NotifierProvider<DeepLinkHandler, void>(DeepLinkHandler.new);

class DeepLinkHandler extends Notifier<void> {
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<FileSystemEvent>? _fileWatchSubscription;
  Timer? _pollTimer;

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
    final watchDir = Constants.configDataFolderPath;

    // Check if there's already a pending file (race condition safety).
    _checkPendingFile();

    try {
      _fileWatchSubscription = watchDir
          .watch(events: FileSystemEvent.create | FileSystemEvent.modify)
          .listen((event) {
        if (event.path.endsWith('pending_deeplink')) {
          _checkPendingFile();
        }
      });
    } catch (e) {
      Fimber.w('FileSystemEntity.watch() failed, falling back to polling: $e');
    }

    // Fallback polling every 2 seconds.
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkPendingFile();
    });
  }

  void _checkPendingFile() {
    final file = _pendingDeepLinkFile;
    if (file.existsSync()) {
      try {
        final uri = file.readAsStringSync().trim();
        file.deleteSync();
        if (uri.isNotEmpty) {
          // Bring window to foreground.
          windowManager.show();
          windowManager.focus();
          _onUri(uri);
        }
      } catch (e) {
        Fimber.w('Error reading pending_deeplink: $e');
      }
    }
  }

  File get _pendingDeepLinkFile =>
      File('${Constants.configDataFolderPath.path}/pending_deeplink');

  void _onUri(String rawUri) {
    // Rate limiting.
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastDeepLinkTimestamp < _minDeepLinkInterval) {
      Fimber.d('Deep link rate-limited: $rawUri');
      return;
    }
    _lastDeepLinkTimestamp = now;

    Fimber.i('Deep link received: $rawUri');

    final request = parseDeepLink(rawUri);
    if (request == null) {
      Fimber.w('Failed to parse deep link: $rawUri');
      return;
    }

    switch (request.action) {
      case DeepLinkAction.install:
        _handleInstall(request);
    }
  }

  Future<void> _handleInstall(DeepLinkRequest request) async {
    // Guard: check if game is running.
    final isGameRunning = ref.read(AppState.isGameRunning).value == true;
    if (isGameRunning) {
      Fimber.w('Deep link install blocked: game is running.');
      _showError('Cannot install mods while Starsector is running.');
      return;
    }

    // Guard: check mods folder is configured.
    final modsFolder = ref.read(AppState.modsFolder).value;
    if (modsFolder == null) {
      Fimber.w('Deep link install blocked: mods folder not configured.');
      _showError(
        'Please configure your Starsector game directory before installing mods via links.',
      );
      return;
    }

    // Resolve all mod entries (fetch .version files, check if installed).
    final httpClient = ref.read(triOSHttpClient);
    final mainMod = await _resolveModEntry(request.mainMod, httpClient);
    final deps = await Future.wait(
      request.dependencies.map((dep) => _resolveModEntry(dep, httpClient)),
    );

    // Check if we should skip the confirmation dialog.
    final skipConfirmation = ref.read(
      appSettings.select((s) => s.deepLinkSkipConfirmation),
    );

    if (!skipConfirmation) {
      // We need a BuildContext. Use the navigator key from the app.
      final context = _findContext();
      if (context == null) {
        Fimber.w('No BuildContext available for deep link dialog.');
        return;
      }

      final confirmed = await showDeepLinkConfirmationDialog(
        context,
        mainMod: mainMod,
        dependencies: deps,
        ref: ref as WidgetRef,
      );
      if (!confirmed) {
        Fimber.i('Deep link install cancelled by user.');
        return;
      }
    }

    // Install main mod.
    if (!mainMod.alreadyInstalled && mainMod.error == null) {
      _downloadAndInstall(mainMod);
    }

    // Install dependencies that aren't already installed.
    for (final dep in deps) {
      if (!dep.alreadyInstalled && dep.error == null) {
        _downloadAndInstall(dep);
      }
    }
  }

  void _downloadAndInstall(ResolvedModEntry entry) {
    ref.read(downloadManager.notifier).downloadAndInstallMod(
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
      return ResolvedModEntry(
        entry: entry,
        downloadUrl: entry.url,
      );
    }

    // Fetch .version file.
    try {
      final response = await httpClient.get(
        entry.url.toString(),
        allowSelfSignedCertificates: true,
      );

      var data = response.data;
      if (data is List<int>) {
        data = utf8.decode(data);
      }

      if (response.statusCode != 200) {
        return ResolvedModEntry(
          entry: entry,
          downloadUrl: entry.url,
          error: 'HTTP ${response.statusCode}',
        );
      }

      final String body = data;
      final versionInfo = VersionCheckerInfoMapper.fromJson(body.fixJson());

      // Check if already installed.
      final isInstalled = _isModAlreadyInstalled(versionInfo);

      if (!versionInfo.hasDirectDownload) {
        return ResolvedModEntry(
          entry: entry,
          modName: versionInfo.modName,
          modVersion: versionInfo.modVersion?.toString(),
          downloadUrl: entry.url,
          alreadyInstalled: isInstalled,
          error: 'No direct download URL in .version file',
        );
      }

      return ResolvedModEntry(
        entry: entry,
        modName: versionInfo.modName,
        modVersion: versionInfo.modVersion?.toString(),
        downloadUrl: Uri.parse(versionInfo.directDownloadURL!),
        alreadyInstalled: isInstalled,
      );
    } catch (e) {
      Fimber.w('Error fetching .version file: ${entry.url}', ex: e);
      return ResolvedModEntry(
        entry: entry,
        downloadUrl: entry.url,
        error: e.toString(),
      );
    }
  }

  bool _isModAlreadyInstalled(VersionCheckerInfo versionInfo) {
    if (versionInfo.modName == null) return false;
    final mods = ref.read(AppState.mods);

    // Try to find a mod that matches by checking version checker info.
    for (final mod in mods) {
      for (final variant in mod.modVariants) {
        final localVci = variant.versionCheckerInfo;
        if (localVci == null) continue;
        // Match by masterVersionFile URL if available.
        if (localVci.masterVersionFile != null &&
            versionInfo.masterVersionFile != null &&
            localVci.masterVersionFile == versionInfo.masterVersionFile) {
          // Compare versions — if local is >= remote, it's already installed.
          if (versionInfo.modVersion != null &&
              localVci.modVersion != null &&
              localVci.modVersion!.compareTo(versionInfo.modVersion!) >= 0) {
            return true;
          }
        }
      }
    }
    return false;
  }

  BuildContext? _findContext() {
    // Walk the element tree to find a valid context.
    // This is a best-effort approach for showing dialogs from a non-widget context.
    BuildContext? result;
    try {
      final binding = WidgetsBinding.instance;
      void visitor(Element element) {
        result = element;
      }

      binding.rootElement?.visitChildren(visitor);
    } catch (_) {}
    return result;
  }

  void _showError(String message) {
    final context = _findContext();
    if (context == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot Install Mod'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
