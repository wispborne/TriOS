import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../mod_manager/mod_manager_logic.dart';
import '../../models/mod_info.dart';
import '../app_state.dart';
import '../constants.dart';
import 'download_status.dart';
import 'download_task.dart';
import 'downloader.dart';

final downloadManager =
    AsyncNotifierProvider<TriOSDownloadManager, List<Download>>(
        TriOSDownloadManager.new);

class TriOSDownloadManager extends AsyncNotifier<List<Download>> {
  static final _downloadManager = DownloadManager();
  final _downloads = List<Download>.empty(growable: true);

  Future<Download?> addDownload(
    String displayName,
    String uri,
    Directory destination, {
    ModInfo? modInfo,
  }) async {
    return _downloadManager.addDownload(uri, destination.path).then((value) {
      if (value == null) {
        return null;
      }
      // generate guid for id
      final id = const Uuid().v4();
      var download = modInfo == null
          ? Download(id, displayName, value)
          : ModDownload(id, displayName, value, modInfo);
      _downloads.add(download);
      state = AsyncValue.data(_downloads);

      // Just for debugging.
      value.status.addListener(() async {
        switch (value.status.value) {
          case DownloadStatus.completed:
            Fimber.d("Download complete: $uri");
            break;
          case DownloadStatus.failed:
            Fimber.e("Download failed: $uri");
            break;
          case DownloadStatus.paused:
            Fimber.d("Download paused: $uri");
            break;
          case DownloadStatus.queued:
            Fimber.d("Download queued: $uri");
            break;
          case DownloadStatus.downloading:
            Fimber.d("Downloading: $uri");
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

  @override
  FutureOr<List<Download>> build() {
    return _downloads;
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

downloadUpdateViaBrowser(
    VersionCheckerInfo remoteVersion, WidgetRef ref, BuildContext context,
    {required bool activateVariantOnComplete, ModInfo? modInfo}) {
  if (remoteVersion.directDownloadURL != null) {
    // ref
    //     .read(downloadManager.notifier)
    //     .addDownload(remoteVersion!.directDownloadURL!, Directory.systemTemp);
    // launchUrl(Uri.parse(remoteVersion.directDownloadURL!));
    var tempFolder = Directory.systemTemp.createTempSync();
    ref
        .read(downloadManager.notifier)
        .addDownload(
          "${remoteVersion.modName ?? "(no name"} ${remoteVersion.modVersion}",
          remoteVersion.directDownloadURL!.fixModDownloadUrl(),
          tempFolder,
          modInfo: modInfo,
        )
        .then((value) {
      value?.task.whenDownloadComplete().then((status) {
        if (status == DownloadStatus.completed) {
          Fimber.d(
              "Downloaded ${value.task.request.url} to ${tempFolder.path}. Installing...");
          try {
            installModFromArchiveWithDefaultUI(
              tempFolder.listSync().first.toFile(),
              ref,
              context,
            ).then((installedVariants) {
              if (activateVariantOnComplete) {
                final variants =
                    ref.read(AppState.modVariants).valueOrNull ?? [];
                final mods = ref.read(AppState.mods);
                for (var installed in installedVariants) {
                  try {
                    final actualVariant = variants.firstWhere((variant) =>
                        variant.smolId == installed.modInfo.smolId);
                    changeActiveModVariant(
                        actualVariant.mod(mods)!, actualVariant, ref);
                  } catch (ex) {
                    Fimber.w(
                        "Failed to activate mod ${installed.modInfo.smolId} after updating: $ex");
                  }
                }
              }
            });
          } catch (e) {
            Fimber.e("Error installing mod from archive", ex: e);
          }
        } else {
          Fimber.e("Download failed: $status");
        }
      });
    });
  } else if (remoteVersion.modThreadId != null) {
    launchUrl(
        Uri.parse("${Constants.forumModPageUrl}${remoteVersion.modThreadId}"));
  } else if (remoteVersion.modNexusId != null) {
    launchUrl(
        Uri.parse("${Constants.nexusModsPageUrl}${remoteVersion.modNexusId}"));
  }
}
