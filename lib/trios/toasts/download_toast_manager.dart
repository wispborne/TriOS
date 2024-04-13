import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import '../download_manager/download_manager.dart';
import 'mod_download_toast.dart';

class DownloadToastDisplayer extends ConsumerStatefulWidget {
  const DownloadToastDisplayer({super.key});

  @override
  ConsumerState createState() => _DownloadToastDisplayerState();
}

class _DownloadToastDisplayerState
    extends ConsumerState<DownloadToastDisplayer> {
  final _downloadIdToToastIdMap = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadManager).value;
    if (downloads == null) {
      // TODO: need to clear toasts when download removed?
      return Container();
    }

    downloads
        // .filter((download) => download.status.value != DownloadStatus.completed)
        .map((item) => (
              download: item,
              toast: toastification.findToastificationItem(
                  _downloadIdToToastIdMap[item.id] ?? "")
            ))
        .forEach((element) {
      final download = element.download;
      final toast = element.toast;

      // If the toast doesn't exist and has NEVER existed (don't re-show previously dismissed toasts)
      // do on next frame
      if (toast == null && !_downloadIdToToastIdMap.containsKey(download.id)) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          toastification.showCustom(
              context: context,
              builder: (context, item) {
                _downloadIdToToastIdMap[download.id] = item.id;
                return ModDownloadToast(download, item);
              });
        });
      }
    });

    return Container();
  }
}
