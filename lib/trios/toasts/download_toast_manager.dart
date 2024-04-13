import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/trios/download_manager/download_status.dart';

import '../download_manager/download_manager.dart';
import 'mod_download_toast.dart';

// Hacky but what can you do
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

      if (download.task.status.value.isCompleted && toast != null) {
        toastification.dismiss(toast, showRemoveAnimation: false);
      } else if (toast == null) {
        // do on next frame
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
