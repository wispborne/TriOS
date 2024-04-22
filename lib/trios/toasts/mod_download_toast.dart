import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/themes/trios_manager.dart';
import 'package:trios/utils/extensions.dart';
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
          borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ValueListenableBuilder(
          valueListenable: downloadTask.status,
          builder: (context, status, child) {
            var installedMod = download is ModDownload
                ? ref
                    .watch(AppState.modVariants)
                    .value
                    .orEmpty()
                    .firstWhereOrNull((ModVariant element) =>
                        element.smolId ==
                        (download as ModDownload).modInfo.smolId)
                : null;
            return Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Tooltip(
                    message: download.id,
                    child: Icon(
                      switch (status) {
                        DownloadStatus.queued => Icons.schedule,
                        DownloadStatus.downloading => Icons.downloading,
                        DownloadStatus.completed => Icons.check_circle,
                        DownloadStatus.failed => Icons.error,
                        DownloadStatus.canceled => Icons.circle,
                        _ => Icons.downloading
                      },
                      color: switch (status) {
                        DownloadStatus.queued => null,
                        DownloadStatus.downloading => null,
                        DownloadStatus.completed =>
                          Theme.of(context).colorScheme.primary,
                        DownloadStatus.failed => vanillaErrorColor,
                        DownloadStatus.canceled => vanillaErrorColor,
                        _ => null
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: SelectionArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(
                        //   switch (status) {
                        //     DownloadStatus.queued => "Queued",
                        //     DownloadStatus.downloading => "Downloading",
                        //     DownloadStatus.completed => "Downloaded",
                        //     DownloadStatus.failed => "Download failed",
                        //     _ => "Download\n${status.name}"
                        //   },
                        //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
                        // ),
                        Text(
                          modString ?? "",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 18),
                        ),
                        // installedMod != null
                        //     ? Padding(
                        //         padding: const EdgeInsets.all(8.0),
                        //         child: ElevatedButton(
                        //             // TODO change to Open or something if already enabled
                        //             onPressed: () {
                        //               // open folder in file explorer
                        //               launchUrlString(
                        //                   installedMod.modsFolder.path);
                        //             },
                        //             child: const Text("Open")),
                        //       )
                        //     : const SizedBox.shrink(),
                        Opacity(
                          opacity: 0.9,
                          child: Text(
                            downloadTask.request.url,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        if (status == DownloadStatus.failed && downloadTask.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              downloadTask.error.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: vanillaErrorColor),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ValueListenableBuilder(
                            valueListenable: downloadTask.downloaded,
                            builder: (context, downloaded, child) =>
                                DownloadProgressIndicator(
                              color: status == DownloadStatus.failed
                                  ? vanillaErrorColor
                                  : null,
                              value: DownloadProgress(downloaded.bytesReceived,
                                  downloaded.totalBytes),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () => toastification.dismiss(item),
                    icon: const Icon(Icons.close))
              ],
            );
          },
        ),
      ),
    );
  }
}
