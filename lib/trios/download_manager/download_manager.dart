import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/activity_panel/activity_panel_controller.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../mod_manager/batch_installation/batch_installation_notifier.dart';
import '../../mod_records/mod_record.dart';
import '../../mod_records/mod_record_source.dart';
import '../../mod_records/mod_records_store.dart';
import '../../models/mod_info.dart';
import '../../models/mod_variant.dart';
import '../constants.dart';
import 'download_request.dart';
import 'download_status.dart';
import 'download_task.dart';
import 'downloader.dart';

final downloadManager =
    AsyncNotifierProvider<TriOSDownloadManager, List<Download>>(
      TriOSDownloadManager.new,
    );

class TriOSDownloadManager extends AsyncNotifier<List<Download>> {
  final _downloads = List<Download>.empty(growable: true);

  @override
  FutureOr<List<Download>> build() {
    return _downloads;
  }

  /// Adds a download to the download manager.
  /// Displays a toast with the download progress.
  /// If [modInfo] is provided, the download will be a [ModDownload] instead of a [Download],
  /// the toast will display the mod name and version, and the download will be associated with the mod.
  Future<Download?> addDownload(
    String displayName,
    String uri,
    Directory destination, {
    ModInfo? modInfo,
    required DownloadSourceHint? sourceHint,
  }) async {
    return ref
        .read(downloadManagerInstance)
        .addDownload(uri, destination.path, null)
        .then((value) {
          if (value == null) {
            return null;
          }
          // generate guid for id
          final id = const Uuid().v4();
          final download = modInfo == null
              ? Download(id, displayName, value, sourceHint: sourceHint)
              : ModDownload(
                  id,
                  displayName,
                  value,
                  modInfo,
                  sourceHint: sourceHint,
                );
          _downloads.add(download);
          state = AsyncValue.data(_downloads);

          // Let the user know a background download started, unless they're
          // already looking at the Activity Panel.
          if (!ref.read(appSettings.select((s) => s.isActivityPanelOpen))) {
            ref.read(activityStartedPopupProvider.notifier).notifyStarted();
          }

          // Just for debugging.
          value.status.addListener(() async {
            switch (value.status.value) {
              case DownloadStatus.queued:
                Fimber.d("Download queued: $uri");
                break;
              case DownloadStatus.retrievingFileInfo:
                Fimber.d("Retrieving file info: $uri");
                break;
              case DownloadStatus.downloading:
                Fimber.d("Downloading: $uri");
                break;
              case DownloadStatus.paused:
                Fimber.d("Download paused: $uri");
                break;
              case DownloadStatus.completed:
                Fimber.d("Download complete: $uri");
                break;
              case DownloadStatus.failed:
                Fimber.w("Download failed: $uri");
                break;
              case DownloadStatus.canceled:
                Fimber.d("Download canceled: $uri");
                break;
            }
            ref.invalidateSelf(); // Forces a call to build() to re-fetch the list of downloads
          });
          // Also invalidate when install completes or is cancelled, so watchers
          // (Activity Panel, icon badge) can re-filter in-progress vs completed.
          download.installComplete.addListener(() => ref.invalidateSelf());
          download.installCancelled.addListener(() => ref.invalidateSelf());
          return download;
        });
  }

  /// Creates an install-only [Download] entry (no actual download).
  /// The task status is pre-set to [DownloadStatus.completed] so the toast
  /// immediately shows the "Installing..." state.
  Download addInstallation(String displayName, String sourcePath) {
    final id = const Uuid().v4();
    final task = DownloadTask(DownloadRequest(sourcePath, '', null));
    task.status.value = DownloadStatus.completed;
    final download = Download(id, displayName, task);
    download.installComplete.addListener(() => ref.invalidateSelf());
    download.installCancelled.addListener(() => ref.invalidateSelf());
    _downloads.add(download);
    state = AsyncValue.data(_downloads);

    // Let the user know a background install started, unless they're already
    // looking at the Activity Panel.
    if (!ref.read(appSettings.select((s) => s.isActivityPanelOpen))) {
      ref.read(activityStartedPopupProvider.notifier).notifyStarted();
    }
    return download;
  }

  bool isDownloadInProgress(String url) {
    return _downloads.any(
      (d) => d.task.request.url == url && d.isInProgress,
    );
  }

  void cancelDownload(Download download) {
    final status = download.task.status.value;
    if (!status.isCompleted) {
      ref
          .read(downloadManagerInstance)
          .cancelDownload(download.task.request.url);
    } else if (status == DownloadStatus.completed &&
        !download.installComplete.value) {
      cancelInstallation(download);
    }
    _downloads.remove(download);
    ref.invalidateSelf();
  }

  /// Marks a [Download] as cancelled so the toast dismisses immediately.
  void cancelInstallation(Download download) {
    download.installCancelled.value = true;
    download.installComplete.value = true;
  }

  void downloadUpdateViaBrowser(
    VersionCheckerInfo remoteVersion, {
    required bool activateVariantOnComplete,
    ModInfo? modInfo,
  }) {
    if (remoteVersion.directDownloadURL != null) {
      if (!isDownloadInProgress(
        remoteVersion.directDownloadURL!.fixModDownloadUrl(),
      )) {
        downloadAndInstallMod(
          "${remoteVersion.modName ?? "(no name"} ${remoteVersion.modVersion}",
          remoteVersion.directDownloadURL!.fixModDownloadUrl(),
          activateVariantOnComplete: activateVariantOnComplete,
          modInfo: modInfo,
          // A version-checker update isn't a catalog install; the record is
          // keyed by the known mod id, so no catalog source hint is needed.
          sourceHint: null,
        );
      }
    } else if (remoteVersion.modThreadId != null) {
      launchUrl(
        Uri.parse("${Constants.forumModPageUrl}${remoteVersion.modThreadId}"),
      );
    } else if (remoteVersion.modNexusId != null) {
      launchUrl(
        Uri.parse("${Constants.nexusModsPageUrl}${remoteVersion.modNexusId}"),
      );
    }
  }

  void downloadAndInstallMod(
    String displayName,
    String uri, {
    required bool activateVariantOnComplete,
    required DownloadSourceHint? sourceHint,
    ModInfo? modInfo,
    bool skipConfirmation = false,
  }) {
    if (isDownloadInProgress(uri)) return;
    var tempFolder = Directory.systemTemp.createTempSync();

    addDownload(
      displayName,
      uri,
      tempFolder,
      modInfo: modInfo,
      sourceHint: sourceHint,
    ).then((value) async {
      if (value == null) return;
      final status = await value.task.whenDownloadComplete();
      if (status == DownloadStatus.completed) {
        Fimber.d(
          "Downloaded ${value.task.request.url} to ${tempFolder.path}. Installing...",
        );
        // Record download history only when we already know the real mod id.
        // When we don't (every catalog install, where the id isn't known until
        // extraction), the batch-install finalize step writes it, keyed by the
        // real mod id — otherwise the record would orphan under the display name.
        if (modInfo != null) {
          try {
            final modId = modInfo.id;
            ref.read(modRecordsStore.notifier).updateRecord(modId, (existing) {
              final now = DateTime.now();
              final base =
                  existing ??
                  ModRecord(recordKey: modId, modId: modId, firstSeen: now);
              final updatedSources = Map<String, ModRecordSource>.of(
                base.sources,
              );
              updatedSources['downloadHistory'] = DownloadHistorySource(
                lastDownloadedFrom: uri,
                lastDownloadedAt: now,
                lastSeen: now,
              );
              return base.copyWith(sources: updatedSources);
            });
          } catch (e) {
            Fimber.w("Failed to update mod record on download: $e");
          }
        }
        try {
          final downloadedFile = (await tempFolder.list().first).toFile();
          // addLateEntry returns once the entry has settled (installed,
          // failed, or skipped) — not merely once it has been queued.
          await ref
              .read(batchInstallationProvider.notifier)
              .addLateEntry(
                downloadedFile,
                download: value,
                skipConfirmation: skipConfirmation,
              );

          // Clean up the temp folder only after a successful install; on
          // failure, keep the archive so the user can install it manually.
          if (value.task.error == null && tempFolder.existsSync()) {
            tempFolder.deleteSync(recursive: true);
            Fimber.i(
              "Cleaned up downloaded file ${tempFolder.name} at ${tempFolder.path}",
            );
          }
        } catch (e) {
          Fimber.e("Error installing mod from archive", ex: e);
          value.task.error = Exception(
            "Failed to install '$displayName'.\n"
            "Download URL: $uri\n\n$e",
          );
        } finally {
          // Ensure installComplete is always set so the toast can react.
          if (!value.installComplete.value) {
            value.installComplete.value = true;
          }
        }
      } else {
        Fimber.w("Download failed: $status");
      }
    });
  }
}

/// Where a download came from, carried from the click through to install
/// completion. Lives only for the length of a download (not persisted); at
/// install completion it's turned into a persistent `CatalogSource` on the
/// mod's record. Null for downloads that aren't catalog installs.
///
/// [catalogName] is the exact catalog entry name (e.g. "Ashpad"), which is
/// what identifies the entry even when a single forum thread lists several
/// mods. [forumThreadId] and [nexusModsId] are extra clues used as a fallback.
class DownloadSourceHint {
  final String? catalogName;
  final String? forumThreadId;
  final String? nexusModsId;

  const DownloadSourceHint({
    this.catalogName,
    this.forumThreadId,
    this.nexusModsId,
  });

  /// Builds a hint from a catalog entry, so call sites can't assemble it wrong.
  factory DownloadSourceHint.fromCatalogMod(CatalogMod mod) {
    final urls = mod.getUrls();
    return DownloadSourceHint(
      catalogName: mod.name,
      forumThreadId: extractForumThreadId(urls[ModUrlType.Forum]),
      nexusModsId: extractNexusModId(urls[ModUrlType.NexusMods]),
    );
  }
}

class Download {
  final String id;
  final String displayName;
  final DownloadTask task;

  /// Where this download came from, when it's a catalog install; null otherwise.
  /// Read at install completion to link the real mod to its catalog entry.
  final DownloadSourceHint? sourceHint;

  /// Tracks file-count progress during mod installation (extraction).
  final ValueNotifier<TriOSDownloadProgress?> installProgress = ValueNotifier(
    null,
  );

  /// Set to true when installation (extraction) is complete.
  final ValueNotifier<bool> installComplete = ValueNotifier(false);

  /// Set to true when the user cancelled the installation dialog without
  /// installing anything. The toast should dismiss immediately.
  final ValueNotifier<bool> installCancelled = ValueNotifier(false);

  /// Set to the installed [ModVariant] after installation completes (for plain
  /// [Download] objects that don't carry [ModInfo]).
  final ValueNotifier<ModVariant?> installedVariant = ValueNotifier(null);

  Download(this.id, this.displayName, this.task, {this.sourceHint});

  /// Whether installation completed with an error.
  bool get hasInstallError => installComplete.value && task.error != null;

  bool get isInProgress {
    final status = task.status.value;
    if (!status.isCompleted) return true;
    return status == DownloadStatus.completed && !installComplete.value;
  }
}

class ModDownload extends Download {
  final ModInfo modInfo;

  ModDownload(
    super.id,
    super.displayName,
    super.task,
    this.modInfo, {
    super.sourceHint,
  });
}

extension DownloadVariantResolution on Download {
  /// Resolves the installed [ModVariant] for this download, gated on download
  /// completion. Returns `null` while the download is still in progress to
  /// prevent matching an already-installed old version during an update.
  ModVariant? resolveInstalledVariant(WidgetRef ref) {
    if (!task.status.value.isCompleted) return null;
    if (this is ModDownload) {
      final modDownload = this as ModDownload;
      // Prefer installedVariant.value (set by the batch installer to the newly
      // installed variant) over the smolId search, which may match an older
      // version that still exists on disk during an update.
      return installedVariant.value ??
          ref
              .read(AppState.modVariants)
              .value
              .orEmpty()
              .firstWhereOrNull(
                (v) => v.smolId == modDownload.modInfo.smolId,
              );
    }
    return installedVariant.value;
  }

  /// Like [resolveInstalledVariant] but uses [ref.watch] for reactive rebuilds.
  ModVariant? watchInstalledVariant(WidgetRef ref) {
    if (!task.status.value.isCompleted) return null;
    if (this is ModDownload) {
      final modDownload = this as ModDownload;
      // Prefer installedVariant.value (set by the batch installer to the newly
      // installed variant) over the smolId search, which may match an older
      // version that still exists on disk during an update.
      return installedVariant.value ??
          ref
              .watch(AppState.modVariants)
              .value
              .orEmpty()
              .firstWhereOrNull(
                (v) => v.smolId == modDownload.modInfo.smolId,
              );
    }
    return installedVariant.value;
  }
}
