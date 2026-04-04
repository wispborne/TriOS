import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../mod_manager/mod_install_source.dart';
import '../../mod_manager/mod_manager_logic.dart';
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
              ? Download(id, displayName, value)
              : ModDownload(id, displayName, value, modInfo);
          _downloads.add(download);
          state = AsyncValue.data(_downloads);

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
    _downloads.add(download);
    state = AsyncValue.data(_downloads);
    return download;
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
      downloadAndInstallMod(
        "${remoteVersion.modName ?? "(no name"} ${remoteVersion.modVersion}",
        remoteVersion.directDownloadURL!.fixModDownloadUrl(),
        activateVariantOnComplete: activateVariantOnComplete,
        modInfo: modInfo,
      );
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
    ModInfo? modInfo,
  }) {
    var tempFolder = Directory.systemTemp.createTempSync();

    addDownload(displayName, uri, tempFolder, modInfo: modInfo).then((
      value,
    ) async {
      if (value == null) return;
      final status = await value.task.whenDownloadComplete();
      if (status == DownloadStatus.completed) {
        Fimber.d(
          "Downloaded ${value.task.request.url} to ${tempFolder.path}. Installing...",
        );
        try {
          final downloadedFile = (await tempFolder.list().first).toFile();
          final installedVariants = await ref
              .read(modManager.notifier)
              .installModFromSourceWithDefaultUI(
                ArchiveModInstallSource(downloadedFile),
                installationDownload: value,
              );

          // todo add a setting for this.
          if (tempFolder.existsSync() &&
              !installedVariants.any((it) => it.err != null)) {
            tempFolder.deleteSync(recursive: true);
            Fimber.i(
              "Cleaned up downloaded file ${tempFolder.name} at ${tempFolder.path}",
            );
          }

          if (activateVariantOnComplete) {
            // final variants =
            //     ref.read(AppState.modVariants).value ?? [];

            // for (final installed in installedVariants) {
            // Find the variant post-install so we can activate it.
            // final actualVariant = variants.firstWhereOrNull(
            //     (variant) => variant.smolId == installed.modInfo.smolId);
            // try {
            // If the mod existed and was enabled, switch to the newly downloaded version.
            // Edit: changed my mind, see https://github.com/wispborne/TriOS/issues/28

            // if (actualVariant != null &&
            //     actualVariant.mod(mods)?.isEnabledInGame == true) {
            //   changeActiveModVariant(
            //       actualVariant.mod(mods)!, actualVariant, ref);
            // }
            // } catch (ex) {
            //   Fimber.w(
            //       "Failed to activate mod ${installed.modInfo.smolId} after updating: $ex");
            // }
            // }
          }
        } catch (e) {
          Fimber.e("Error installing mod from archive", ex: e);
          value.task.error = Exception(
            "Failed to install '$displayName'.\n"
            "Download URL: $uri\n\n$e",
          );
        } finally {
          // Ensure installComplete is always set so the toast can react.
          // (installModFromSourceWithDefaultUI sets it in its own finally,
          // but errors before that call — or if it's never reached — need this.)
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

class Download {
  final String id;
  final String displayName;
  final DownloadTask task;

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

  Download(this.id, this.displayName, this.task);

  /// Whether installation completed with an error.
  bool get hasInstallError => installComplete.value && task.error != null;
}

class ModDownload extends Download {
  final ModInfo modInfo;

  ModDownload(super.id, super.displayName, super.task, this.modInfo);
}

extension DownloadVariantResolution on Download {
  /// Resolves the installed [ModVariant] for this download, gated on download
  /// completion. Returns `null` while the download is still in progress to
  /// prevent matching an already-installed old version during an update.
  ModVariant? resolveInstalledVariant(WidgetRef ref) {
    if (!task.status.value.isCompleted) return null;
    if (this is ModDownload) {
      final modDownload = this as ModDownload;
      // Prefer installedVariant.value (set by installModFromSourceWithDefaultUI
      // to the newly installed variant) over the smolId search, which may match
      // an older version that still exists on disk during an update.
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
      // Prefer installedVariant.value (set by installModFromSourceWithDefaultUI
      // to the newly installed variant) over the smolId search, which may match
      // an older version that still exists on disk during an update.
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
