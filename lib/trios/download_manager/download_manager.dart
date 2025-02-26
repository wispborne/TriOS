import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../mod_manager/mod_install_source.dart';
import '../../mod_manager/mod_manager_logic.dart';
import '../../models/mod_info.dart';
import '../constants.dart';
import 'download_status.dart';
import 'download_task.dart';
import 'downloader.dart';

final downloadManager =
    AsyncNotifierProvider<TriOSDownloadManager, List<Download>>(
      TriOSDownloadManager.new,
    );

class TriOSDownloadManager extends AsyncNotifier<List<Download>> {
  static late DownloadManager _downloadManager;
  final _downloads = List<Download>.empty(growable: true);

  @override
  FutureOr<List<Download>> build() {
    _downloadManager = DownloadManager(ref: ref);
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
    return _downloadManager.addDownload(uri, destination.path, null).then((
      value,
    ) {
      if (value == null) {
        return null;
      }
      // generate guid for id
      final id = const Uuid().v4();
      final download =
          modInfo == null
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

  downloadUpdateViaBrowser(
    VersionCheckerInfo remoteVersion, {
    required bool activateVariantOnComplete,
    ModInfo? modInfo,
  }) {
    if (remoteVersion.directDownloadURL != null) {
      downloadAndInstallMod(
        "${remoteVersion.modName ?? "(no name"} ${remoteVersion.modVersion}",
        remoteVersion.directDownloadURL!.fixModDownloadUrl(),
        activateVariantOnComplete: activateVariantOnComplete,
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

    addDownload(displayName, uri, tempFolder, modInfo: modInfo).then((value) {
      value?.task.whenDownloadComplete().then((status) {
        if (status == DownloadStatus.completed) {
          Fimber.d(
            "Downloaded ${value.task.request.url} to ${tempFolder.path}. Installing...",
          );
          try {
            ref
                .read(modManager.notifier)
                .installModFromSourceWithDefaultUI(
                  ArchiveModInstallSource(tempFolder.listSync().first.toFile()),
                )
                .then((installedVariants) {
                  if (activateVariantOnComplete) {
                    // final variants =
                    //     ref.read(AppState.modVariants).valueOrNull ?? [];

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
                });
          } catch (e) {
            Fimber.e("Error installing mod from archive", ex: e);
          }
        } else {
          Fimber.w("Download failed: $status");
        }
      });
    });
  }
}

class Download {
  final String id;
  final String displayName;
  final DownloadTask task;

  Download(this.id, this.displayName, this.task);
}

class ModDownload extends Download {
  final ModInfo modInfo;

  ModDownload(super.id, super.displayName, super.task, this.modInfo);
}
