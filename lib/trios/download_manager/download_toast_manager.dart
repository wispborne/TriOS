import 'package:flutter/material.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import 'download_manager.dart';

// Hacky but what can you do
class DownloadToastDisplayer extends ConsumerStatefulWidget {
  const DownloadToastDisplayer({super.key});

  @override
  ConsumerState createState() => _DownloadToastDisplayerState();
}

class _DownloadToastDisplayerState extends ConsumerState<DownloadToastDisplayer> {
  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadManager).value;
    if (downloads == null) {
      // TODO: need to clear toasts when download removed?
      return Container();
    }

    downloads.map((item) => (item, toastification.findToastificationItem(item.request.url))).forEach((element) {
      final download = element.$1;
      final toast = element.$2;

      if (download.status.value.isCompleted && toast != null) {
        toastification.dismiss(toast);
      } else {
        if (toast == null) {
          // do on next frame
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            toastification.showCustom(
              context: context,
              builder: (context, item) =>
                  SimpleToastWidget(type: ToastificationType.info, title: Text('Downloading ${download.request.url}')),
            );
          });
        } else {
          // toast.update(
          //   title: 'Downloading ${download.request.url}',
          //   message: 'Downloading ${download.request.url}',
          //   duration: Duration(seconds: 10),
          //   onTap: () {
          //     download.cancel();
          //   },
          // );
        }
      }
    });

    return Container();
  }
}
