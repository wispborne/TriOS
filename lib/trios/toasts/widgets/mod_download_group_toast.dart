import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/download_progress_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../download_manager/download_manager.dart';
import '../../download_manager/download_status.dart';
import '../notification_group_manager.dart';

/// Grouped toast notification for multiple mod downloads.
///
/// Groups multiple download notifications into a single expandable toast to prevent UI spam.
/// Shows aggregate progress and allows expanding to see individual download status.
/// Individual items can be dismissed from the group using the X button.
///
/// UI Structure (Collapsed):
/// ┌────────────────────────────────────┐
/// │ 📦 Downloading 5 mods  [▼] [⏱] [X] │
/// │ 3 of 5 complete                    │
/// │ [===============>      ] 62%       │
/// └────────────────────────────────────┘
///
/// UI Structure (Expanded - more compact):
/// ┌────────────────────────────────────┐
/// │ 📦 Downloading 5 mods  [▲] [⏱] [X] │
/// │ 3 of 5 complete                    │
/// │ [===============>      ] 62%       │
/// ├────────────────────────────────────┤
/// │ ✓ LazyLib v2.7              [X]    │
/// │   [===================] Complete   │
/// │   [Open] [Enable]                  │
/// │                                    │
/// │ ⬇ GraphicsLib v1.6.0        [X]    │
/// │   [========>     ] Downloading     │
/// │                                    │
/// │ ⏱ MagicLib v1.0.0           [X]    │
/// │   [           ] Queued             │
/// │                                    │
/// │ +2 more                            │
/// └────────────────────────────────────┘
class ModDownloadGroupToast extends ConsumerStatefulWidget {
  const ModDownloadGroupToast(
    this.group,
    this.item,
    this.toastDurationMillis, {
    super.key,
  });

  final ToastificationItem item;
  final NotificationGroup<Download> group;
  final int toastDurationMillis;

  @override
  ConsumerState<ModDownloadGroupToast> createState() =>
      _ModDownloadGroupToastState();
}

class _ModDownloadGroupToastState
    extends ConsumerState<ModDownloadGroupToast> {
  PaletteGenerator? palette;
  final Map<String, VoidCallback> _statusListeners = {};

  Future<void> _generatePalette() async {
    // Try to get palette from first mod's icon
    final firstModDownload = widget.group.items
        .whereType<ModDownload>()
        .firstOrNull;

    if (firstModDownload != null) {
      final installedMod = ref
          .read(AppState.modVariants)
          .value
          .orEmpty()
          .firstWhereOrNull(
            (ModVariant element) =>
                element.smolId == firstModDownload.modInfo.smolId,
          );

      if (installedMod?.iconFilePath.isNotNullOrEmpty() == true) {
        final icon = Image.file((installedMod!.iconFilePath ?? "").toFile());
        palette = await PaletteGenerator.fromImageProvider(icon.image);
        if (!mounted) return;
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    widget.item.pause();

    // Generate palette
    _generatePalette();

    // Add status listeners for all downloads
    for (final download in widget.group.items) {
      void listener() {
        if (mounted) {
          setState(() {});

          // Check if all downloads are complete
          final allComplete = widget.group.allItemsCompleted();
          if (allComplete && !widget.item.isRunning) {
            widget.item.start();
          }
        }
      }

      download.task.status.addListener(listener);
      _statusListeners[download.id] = listener;
    }

    // Timer loop for countdown
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 5));
      if (mounted) {
        setState(() {});
      }
      return mounted;
    });
  }

  @override
  void dispose() {
    // Remove all listeners
    for (final entry in _statusListeners.entries) {
      final download = widget.group.items.firstWhereOrNull(
        (d) => d.id == entry.key,
      );
      download?.task.status.removeListener(entry.value);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final item = widget.item;
    final downloads = group.items;

    final completedCount = group.completedCount;
    final totalCount = downloads.length;
    final failedCount = group.failedCount;
    final allComplete = group.allItemsCompleted();

    final timeElapsed = (item.elapsedDuration?.inMilliseconds ?? 0);
    final timeTotal = (item.originalDuration?.inMilliseconds ?? 1000);

    // Calculate aggregate progress
    double aggregateProgress = 0.0;
    if (downloads.isNotEmpty) {
      int totalBytes = 0;
      int receivedBytes = 0;

      for (final download in downloads) {
        final downloaded = download.task.downloaded.value;
        totalBytes += downloaded.totalBytes;
        receivedBytes += downloaded.bytesReceived;
      }

      if (totalBytes > 0) {
        aggregateProgress = receivedBytes / totalBytes;
      }
    }

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
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Tooltip(
                              message: allComplete
                                  ? 'All downloads complete'
                                  : 'Downloading mods',
                              child: Icon(
                                size: 32,
                                allComplete
                                    ? Icons.check_circle
                                    : Icons.downloading,
                                color: allComplete
                                    ? theme.colorScheme.secondary
                                    : theme.iconTheme.color,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  allComplete
                                      ? 'Downloaded $totalCount ${totalCount == 1 ? 'mod' : 'mods'}'
                                      : 'Downloading $totalCount ${totalCount == 1 ? 'mod' : 'mods'}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Opacity(
                                  opacity: 0.9,
                                  child: Text(
                                    failedCount > 0
                                        ? '$completedCount complete, $failedCount failed'
                                        : '$completedCount of $totalCount complete',
                                    style: theme.textTheme.labelMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Expand/collapse button
                          IconButton(
                            onPressed: () {
                              setState(() {
                                group.isExpanded = !group.isExpanded;
                              });
                            },
                            icon: Icon(
                              group.isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            tooltip: group.isExpanded ? 'Collapse' : 'Expand',
                          ),
                          // Close button with timer
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    value: (timeTotal - timeElapsed) / timeTotal,
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => toastification.dismiss(item),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Aggregate progress bar
                      if (!allComplete)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TriOSDownloadProgressIndicator(
                            value: TriOSDownloadProgress(
                              (aggregateProgress * 1000000).toInt(),
                              1000000,
                              isIndeterminate: aggregateProgress == 0,
                            ),
                          ),
                        ),
                      // Expanded list of individual downloads
                      if (group.isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildExpandedList(theme),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedList(ThemeData theme) {
    final downloads = widget.group.items;
    final maxToShow = widget.group.config.maxItemsToShow;
    final hasMore = downloads.length > maxToShow;
    final downloadsToShow = hasMore
        ? downloads.take(maxToShow).toList()
        : downloads;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...downloadsToShow.map((download) => _buildDownloadItem(download, theme)),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+${downloads.length - maxToShow} more',
              style: theme.textTheme.labelMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDownloadItem(Download download, ThemeData theme) {
    final downloadTask = download.task;
    final status = downloadTask.status.value;
    final modString = download.displayName;

    var installedMod = download is ModDownload
        ? ref
              .watch(AppState.modVariants)
              .value
              .orEmpty()
              .firstWhereOrNull(
                (ModVariant element) =>
                    element.smolId == download.modInfo.smolId,
              )
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: status.displayString,
                    child: Icon(
                      size: 20,
                      switch (status) {
                        DownloadStatus.queued => Icons.schedule,
                        DownloadStatus.retrievingFileInfo => Icons.downloading,
                        DownloadStatus.downloading => Icons.downloading,
                        DownloadStatus.completed => Icons.check_circle,
                        DownloadStatus.failed => Icons.error,
                        DownloadStatus.canceled => Icons.cancel,
                        _ => Icons.downloading,
                      },
                      color: switch (status) {
                        DownloadStatus.completed => theme.colorScheme.secondary,
                        DownloadStatus.failed => ThemeManager.vanillaErrorColor,
                        DownloadStatus.canceled => ThemeManager.vanillaErrorColor,
                        _ => theme.iconTheme.color,
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        modString,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (status == DownloadStatus.failed &&
                          downloadTask.error != null)
                        Text(
                          downloadTask.error.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ThemeManager.vanillaErrorColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Individual dismiss button
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  tooltip: 'Remove from group',
                  onPressed: () {
                    setState(() {
                      widget.group.items.remove(download);
                    });
                  },
                ),
              ],
            ),
            if (status != DownloadStatus.completed &&
                status != DownloadStatus.failed &&
                status != DownloadStatus.canceled)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ValueListenableBuilder(
                  valueListenable: downloadTask.downloaded,
                  builder: (context, downloaded, child) {
                    final isIndeterminate = status == DownloadStatus.queued ||
                        status == DownloadStatus.retrievingFileInfo;
                    return TriOSDownloadProgressIndicator(
                      color: status == DownloadStatus.failed
                          ? ThemeManager.vanillaErrorColor
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
            if (installedMod != null &&
                (status == DownloadStatus.completed ||
                    status == DownloadStatus.failed))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        launchUrlString(installedMod.modFolder.path);
                      },
                      icon: Icon(
                        Icons.folder_open,
                        size: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      label: Text(
                        "Open",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontSize: 11,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Builder(
                      builder: (context) {
                        final mods = ref.read(AppState.mods);
                        final mod = installedMod.mod(mods);

                        return ElevatedButton.icon(
                          onPressed: () async {
                            if (mod == null) return;
                            await ref
                                .read(modManager.notifier)
                                .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                                  mod,
                                  installedMod,
                                );
                          },
                          icon: const Icon(
                            Icons.power_settings_new,
                            size: 14,
                          ),
                          label: Text(
                            "Enable",
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
