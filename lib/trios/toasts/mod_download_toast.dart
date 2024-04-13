import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/trios/trios_theme.dart';
import 'package:trios/widgets/download_progress_indicator.dart';

import '../download_manager/download_manager.dart';
import '../download_manager/download_status.dart';

class ModDownloadToast extends ConsumerWidget {
  const ModDownloadToast(this.download, this.item, {super.key});

  final ToastificationItem item;
  final Download download;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modString = download.displayName;
    final downloadTask = download.task;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 32),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(TriOSTheme.cornerRadius),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: download.id,
                child: Icon(switch (downloadTask.status.value) {
                  DownloadStatus.queued => Icons.schedule,
                  DownloadStatus.downloading => Icons.download,
                  DownloadStatus.completed => Icons.check,
                  DownloadStatus.failed => Icons.error,
                  _ => Icons.download
                }),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      switch (downloadTask.status.value) {
                        DownloadStatus.queued => "Queued\n$modString",
                        DownloadStatus.downloading => "Downloading\n$modString",
                        DownloadStatus.completed => "Downloaded\n$modString",
                        DownloadStatus.failed => "Download failed\n$modString",
                        _ => "Download\n${downloadTask.status.value.name}"
                      },
                      style: Theme.of(context).textTheme.bodyMedium),
                  // Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: downloadTask.status.value != DownloadStatus.completed
                  //       ? ElevatedButton(
                  //           onPressed: () {}, child: const Text("Cancel"))
                  //       : ElevatedButton(
                  //           // TODO change to Open or something if already enabled
                  //           onPressed: () {},
                  //           child: const Text("Enable")),
                  // ),
                  Text(
                    downloadTask.request.url,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: DownloadProgressIndicator(
                      value: DownloadProgress(
                          downloadTask.bytesReceived.value.toInt(),
                          downloadTask.totalBytes.value.toInt()),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
                onPressed: () => toastification.dismiss(item),
                icon: const Icon(Icons.close))
          ],
        ),
      ),
    );
  }
}
