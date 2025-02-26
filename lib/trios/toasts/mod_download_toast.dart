import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/download_progress_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../utils/logging.dart';
import '../download_manager/download_manager.dart';
import '../download_manager/download_status.dart';

class ModDownloadToast extends ConsumerStatefulWidget {
  /// toastDurationMillis Starts ticking after download is completed or failed.
  const ModDownloadToast(
    this.download,
    this.item,
    this.toastDurationMillis, {
    super.key,
  });

  final ToastificationItem item;
  final Download download;

  final int toastDurationMillis;

  @override
  ConsumerState<ModDownloadToast> createState() => _ModDownloadToastState();
}

class _ModDownloadToastState extends ConsumerState<ModDownloadToast> {
  PaletteGenerator? palette;

  Future<void> _generatePalette(ModVariant variant) async {
    if (variant.iconFilePath.isNotNullOrEmpty()) {
      final icon = Image.file((variant.iconFilePath ?? "").toFile());
      palette = await PaletteGenerator.fromImageProvider(icon.image);
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    widget.item.pause();
    // loop to update the time remaining every 5ms
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 5));
      if (mounted) {
        setState(() {});
      }
      return mounted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final download = widget.download;
    final item = widget.item;
    final modString = download.displayName;
    final downloadTask = download.task;
    var installedMod =
        download is ModDownload
            ? ref
                .watch(AppState.modVariants)
                .value
                .orEmpty()
                .firstWhereOrNull(
                  (ModVariant element) =>
                      element.smolId == (download).modInfo.smolId,
                )
            : null;
    if (palette == null && installedMod != null) {
      _generatePalette(installedMod);
    }
    final timeElapsed = (widget.item.elapsedDuration?.inMilliseconds ?? 0);
    final timeTotal = (widget.item.originalDuration?.inMilliseconds ?? 1000);

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 32),
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: palette.createPaletteTheme(context),
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Card(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      ThemeManager.cornerRadius,
                    ),
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
                      // Fimber.i(item.isRunning.toString());
                      final isStopped = (!item.isRunning || !item.isStarted);
                      final isFinished = status.isCompleted;
                      if (isStopped && isFinished) {
                        Fimber.i(
                          "Debug: isStopped: $isStopped, isFinished: $isFinished",
                        );
                        item.start();
                      }

                      return Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Tooltip(
                              message: status.displayString,
                              child: Icon(
                                size: 40,
                                switch (status) {
                                  DownloadStatus.queued => Icons.schedule,
                                  DownloadStatus.retrievingFileInfo =>
                                    Icons.downloading,
                                  DownloadStatus.downloading =>
                                    Icons.downloading,
                                  DownloadStatus.completed =>
                                    Icons.check_circle,
                                  DownloadStatus.failed => Icons.error,
                                  DownloadStatus.canceled => Icons.circle,
                                  _ => Icons.downloading,
                                },
                                color: switch (status) {
                                  DownloadStatus.queued =>
                                    theme.iconTheme.color,
                                  DownloadStatus.retrievingFileInfo =>
                                    theme.iconTheme.color,
                                  DownloadStatus.downloading =>
                                    theme.iconTheme.color,
                                  DownloadStatus.completed =>
                                    theme.colorScheme.secondary,
                                  DownloadStatus.failed =>
                                    ThemeManager.vanillaErrorColor,
                                  DownloadStatus.canceled =>
                                    ThemeManager.vanillaErrorColor,
                                  _ => theme.iconTheme.color,
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: SelectionArea(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    modString,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Opacity(
                                    opacity: 0.9,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        downloadTask.request.url,
                                        style: theme.textTheme.labelMedium,
                                        maxLines: 3,
                                      ),
                                    ),
                                  ),
                                  if (status == DownloadStatus.failed &&
                                      downloadTask.error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        downloadTask.error.toString(),
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color:
                                                  ThemeManager
                                                      .vanillaErrorColor,
                                            ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: ValueListenableBuilder(
                                      valueListenable: downloadTask.downloaded,
                                      builder: (context, downloaded, child) {
                                        final isIndeterminate =
                                            status == DownloadStatus.queued ||
                                            status ==
                                                DownloadStatus
                                                    .retrievingFileInfo;
                                        return TriOSDownloadProgressIndicator(
                                          color:
                                              status == DownloadStatus.failed
                                                  ? ThemeManager
                                                      .vanillaErrorColor
                                                  : null,
                                          value: TriOSDownloadProgress(
                                            downloaded.bytesReceived,
                                            downloaded.totalBytes,
                                            isIndeterminate: isIndeterminate,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (installedMod != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        "Currently enabled: ${installedMod.modInfo.version}",
                                        style: theme.textTheme.labelMedium,
                                      ),
                                    ),
                                  if (installedMod != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              // open folder in file explorer
                                              launchUrlString(
                                                installedMod.modFolder.path,
                                              );
                                            },
                                            icon: Icon(
                                              Icons.folder_open,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                            label: Text(
                                              "Open",
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onSurface,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Builder(
                                            builder: (context) {
                                              final mods = ref.read(
                                                AppState.mods,
                                              );
                                              final mod = installedMod.mod(
                                                mods,
                                              );

                                              return ElevatedButton.icon(
                                                onPressed: () async {
                                                  if (mod == null) {
                                                    Fimber.w(
                                                      "Cannot enable, mod not found for variant ${installedMod.smolId}",
                                                    );
                                                    return;
                                                  }
                                                  await ref
                                                      .read(
                                                        AppState
                                                            .modVariants
                                                            .notifier,
                                                      )
                                                      .changeActiveModVariant(
                                                        mod,
                                                        installedMod,
                                                      );
                                                  toastification.dismiss(item);
                                                },
                                                icon: const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: Icon(
                                                    Icons.power_settings_new,
                                                  ),
                                                ),
                                                label: const Text("Enable"),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    value:
                                        (timeTotal - timeElapsed) / timeTotal,
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      () => toastification.dismiss(widget.item),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
