import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/dashboard/mod_summary_widget.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/activity_panel/activity_entry.dart';
import 'package:trios/trios/activity_panel/activity_panel_controller.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/download_status.dart';
import 'package:trios/utils/relative_timestamp.dart';
import 'package:trios/widgets/download_progress_indicator.dart';
import 'package:trios/mod_manager/mod_context_menu.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Padding for a flush, dense activity row (no card chrome).
const _activityRowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 6);

/// Displays a single completed/failed activity entry as a dense row.
class CompletedActivityTile extends ConsumerWidget {
  final ActivityEntry entry;
  final bool showActions;

  /// Overrides what the "Clear" action does. Defaults to removing the entry
  /// from the persisted history.
  final VoidCallback? onClear;

  const CompletedActivityTile({
    super.key,
    required this.entry,
    this.showActions = true,
    this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFailed = entry.status == ActivityStatus.failed;
    final isCancelled = entry.status == ActivityStatus.cancelled;

    final mods = ref.watch(AppState.mods);
    final mod = entry.modId != null
        ? mods.firstWhereOrNull((m) => m.id == entry.modId)
        : mods.firstWhereOrNull(
            (m) => m.findHighestVersion?.modInfo.nameOrId == entry.modName,
          );
    final variant = mod?.findHighestVersion;
    final isEnabled = mod?.isEnabledInGame == true;

    final gameVersion = ref.watch(AppState.starsectorVersion).value;
    final compatWithGame = variant != null
        ? compareGameVersions(variant.modInfo.gameVersion, gameVersion)
        : null;
    final compatTextColor = compatWithGame?.getGameCompatibilityColor();

    final hasIcon = variant?.iconFilePath != null;
    // Inset the tap highlight without shifting content: the inset lives on an
    // outer Padding and is subtracted back out of the inner content Padding.
    const highlightInset = EdgeInsets.symmetric(horizontal: 8);
    Widget tile = Padding(
      padding: highlightInset,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: (!isFailed && !isCancelled && variant != null)
              ? () => launchUrlString(variant.modFolder.path)
              : null,
          borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
          child: Padding(
            padding: _activityRowPadding - highlightInset,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Center(
                  child: Padding(
                    padding: .only(top: hasIcon ? 4 : 8),
                    child: hasIcon
                        ? ModIcon(variant!.iconFilePath, size: 32)
                        : SizedBox(
                            width: 32,
                            child: Icon(
                              isFailed
                                  ? Icons.error
                                  : isCancelled
                                  ? Icons.cancel
                                  : Icons.check,
                              size: 20,
                              color: isFailed
                                  ? theme.colorScheme.error
                                  : isCancelled
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: Row(
                              spacing: 8,
                              children: [
                                Flexible(
                                  child: Text(
                                    entry.modName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (entry.modVersion != null)
                                  Text(
                                    entry.modVersion!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (showActions && !isFailed && !isCancelled && variant != null)
                            MovingTooltipWidget.text(
                              message: 'Open mod folder',
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 14,
                                  icon: Icon(
                                    Icons.folder_open,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    launchUrlString(variant.modFolder.path);
                                  },
                                ),
                              ),
                            ),
                          if (showActions)
                            MovingTooltipWidget.text(
                              message: 'Clear',
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 14,
                                  icon: Icon(
                                    Icons.close,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed:
                                      onClear ??
                                      () => ref
                                          .read(activityHistoryStore.notifier)
                                          .removeEntry(entry.id),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isFailed && entry.errorMessage != null)
                        MovingTooltipWidget.text(
                          message: entry.errorMessage!,
                          child: Text(
                            entry.errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Padding(
                        padding: .only(top: 2),
                        child: Row(
                          spacing: 4,
                          children: [
                            MovingTooltipWidget.text(
                              message: isCancelled
                                  ? "Canceled"
                                  : entry.sourceType ==
                                        ActivitySourceType.download
                                  ? "Downloaded from\n${entry.sourceDetail}"
                                  : "Installed from archive",
                              child: Icon(
                                isCancelled
                                    ? Icons.cancel
                                    : entry.sourceType ==
                                          ActivitySourceType.download
                                    ? Icons.download
                                    : Icons.archive,
                                size: 12,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.timestamp.relativeTimestamp(
                                  minUnit: TimeUnit.minutes,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showActions && !isFailed && !isCancelled && variant != null)
                              if (!isEnabled && mod != null)
                                MovingTooltipWidget.text(
                                  message: 'Enable this mod',
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await ref
                                          .read(modManager.notifier)
                                          .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                                            mod,
                                            variant,
                                          );
                                    },
                                    icon: const Icon(
                                      Icons.power_settings_new,
                                      size: 14,
                                    ),
                                    label: Text(
                                      'Enable',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 11),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: .symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      iconColor: theme.iconTheme.color,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (variant != null) {
      tile = MovingTooltipWidget.framed(
        position: TooltipPosition.topLeft,
        padding: .zero,
        tooltipWidgetBuilder: (context) => SizedBox(
          width: 400,
          child: ModSummaryWidget(
            modVariant: variant,
            compatWithGame: compatWithGame,
            compatTextColor: compatTextColor,
            showIconTip: false,
          ),
        ),
        child: tile,
      );
    }

    if (mod != null) {
      tile = ContextMenuRegion(
        contextMenu: buildModContextMenu(mod, ref, context),
        child: tile,
      );
    }

    return tile;
  }
}

/// Displays a single in-progress download/install as a card.
/// Listens to the download's ValueNotifiers for live progress updates.
class InProgressActivityTile extends StatelessWidget {
  final Download download;
  final VoidCallback? onCancel;

  const InProgressActivityTile({
    super.key,
    required this.download,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        download.task.status,
        download.task.downloaded,
        download.installProgress,
        download.installComplete,
        download.installedVariant,
      ]),
      builder: (context, _) => _buildContent(context),
    );
  }

  String? _resolveIconPath() {
    final installed = download.installedVariant.value;
    if (installed != null) return installed.iconFilePath;
    if (download is ModDownload) {
      return ModVariant.iconCache[(download as ModDownload).modInfo.id];
    }
    return null;
  }

  Widget _buildIcon(
    IconData statusIcon,
    bool isInstalling,
    DownloadStatus status,
    ThemeData theme,
  ) {
    final iconPath = _resolveIconPath();
    return MovingTooltipWidget.text(
      message: isInstalling ? 'Installing...' : status.displayString,
      child: iconPath != null
          ? ModIcon(iconPath, size: 24)
          : Icon(statusIcon, size: 20, color: theme.iconTheme.color),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final status = download.task.status.value;
    final dlAmount = download.task.downloaded.value;

    final isInstalling =
        status == DownloadStatus.completed && !download.installComplete.value;
    final installProgress = download.installProgress.value;

    String statusText;
    TriOSDownloadProgress? progressValue;

    if (isInstalling) {
      statusText = installProgress?.customStatus ?? 'Installing...';
      progressValue =
          installProgress ?? TriOSDownloadProgress(0, 0, isIndeterminate: true);
    } else if (status == DownloadStatus.downloading) {
      statusText = 'Downloading...';
      progressValue = TriOSDownloadProgress(
        dlAmount.bytesReceived,
        dlAmount.totalBytes,
        isIndeterminate: dlAmount.totalBytes == 0,
      );
    } else if (status == DownloadStatus.queued ||
        status == DownloadStatus.retrievingFileInfo) {
      statusText = status.displayString;
      progressValue = TriOSDownloadProgress(0, 0, isIndeterminate: true);
    } else {
      statusText = status.displayString;
      progressValue = null;
    }

    final IconData statusIcon = isInstalling
        ? Icons.install_desktop
        : switch (status) {
            DownloadStatus.queued => Icons.schedule,
            DownloadStatus.retrievingFileInfo => Icons.downloading,
            DownloadStatus.downloading => Icons.downloading,
            DownloadStatus.completed => Icons.check_circle,
            DownloadStatus.failed => Icons.error,
            DownloadStatus.canceled => Icons.cancel,
            _ => Icons.downloading,
          };

    return Padding(
      padding: _activityRowPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: 8,
            children: [
              _buildIcon(statusIcon, isInstalling, status, theme),
              Expanded(
                child: Text(
                  download.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onCancel != null)
                MovingTooltipWidget.text(
                  message: 'Cancel',
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: .zero,
                      iconSize: 16,
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: onCancel,
                    ),
                  ),
                ),
            ],
          ),
          if (progressValue != null)
            Padding(
              padding: .only(top: 6),
              child: TriOSDownloadProgressIndicator(value: progressValue),
            ),
          if (progressValue == null)
            Padding(
              padding: .only(top: 4),
              child: Text(
                statusText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
