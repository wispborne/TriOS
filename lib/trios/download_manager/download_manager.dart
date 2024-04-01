import 'dart:async';
import 'dart:io';

import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';

final downloadManager = AsyncNotifierProvider<TriOSDownloadManager, List<DownloadTask>>(TriOSDownloadManager.new);

class TriOSDownloadManager extends AsyncNotifier<List<DownloadTask>> {
  static final _downloadManager = DownloadManager();

  Future<DownloadTask?> addDownload(String uri, Directory destination) async {
    return _downloadManager.addDownload(uri, destination.path).then((value) {
      ref.invalidateSelf(); // Refresh the download list after adding a new download
      return value;
    }).onError((error, stackTrace) {
      ref.invalidateSelf(); // Refresh the download list after adding a new download
      return null;
    }).whenComplete(() => ref.invalidateSelf());
  }

  @override
  FutureOr<List<DownloadTask>> build() {
    return _downloadManager.getAllDownloads();
  }
}

downloadUpdateViaBrowser(VersionCheckerInfo remoteVersion) {
  if (remoteVersion.directDownloadURL != null) {
    // ref
    //     .read(downloadManager.notifier)
    //     .addDownload(remoteVersion!.directDownloadURL!, Directory.systemTemp);
    launchUrl(Uri.parse(remoteVersion!.directDownloadURL!));
  } else if (remoteVersion.modThreadId != null) {
    launchUrl(Uri.parse(
        "${Constants.forumModPageUrl}${remoteVersion.modThreadId}"));
  } else if (remoteVersion.modNexusId != null) {
    launchUrl(Uri.parse(
        "${Constants.nexusModsPageUrl}${remoteVersion.modNexusId}"));
  }
}