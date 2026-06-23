import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation_notifier.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/activity_panel/activity_entry.dart';
import 'package:trios/trios/activity_panel/activity_item_tile.dart';
import 'package:trios/trios/activity_panel/activity_panel_controller.dart';
import 'package:trios/trios/activity_panel/batch_activity_tile.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants_theme.dart' show TriOSThemeConstants;
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/download_status.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';
import 'package:trios/widgets/tooltip_frame.dart';

({
  List<BatchEntry> activeBatchEntries,
  List<ActivityEntry> unseenEntries,
  List<Download> inProgress,
}) _computeActivityData({
  required BatchInstallation? batch,
  required ActivityHistory? history,
  required int unseenCount,
  required List<Download> downloads,
}) {
  final activeBatchEntries =
      batch?.entries
          .where(
            (e) =>
                e.status == BatchEntryStatus.queued ||
                e.status == BatchEntryStatus.scanning ||
                e.status == BatchEntryStatus.scanned ||
                e.status == BatchEntryStatus.extracting,
          )
          .toList() ??
      const [];

  final unseenEntries = (history != null && unseenCount > 0)
      ? history.entries.take(unseenCount).toList()
      : const <ActivityEntry>[];

  final inProgress = downloads.where((d) {
    final status = d.task.status.value;
    if (status == DownloadStatus.failed ||
        status == DownloadStatus.canceled) {
      return false;
    }
    return !status.isCompleted ||
        (!d.installComplete.value && !d.installCancelled.value);
  }).toList();

  return (
    activeBatchEntries: activeBatchEntries,
    unseenEntries: unseenEntries,
    inProgress: inProgress,
  );
}

/// Toolbar icon that toggles the Activity Panel.
///
/// Shows a circular progress ring when downloads/installs are in progress,
/// and an Edge-style badge count of unseen completions. When a mod finishes
/// installing while the panel is closed, shows a transient popup anchored below
/// the button so the user can Enable the mod(s) without opening the panel.
class ActivityIconButton extends ConsumerStatefulWidget {
  const ActivityIconButton({super.key});

  @override
  ConsumerState<ActivityIconButton> createState() => _ActivityIconButtonState();
}

class _ActivityIconButtonState extends ConsumerState<ActivityIconButton> {
  final LayerLink _popupLink = LayerLink();
  final OverlayPortalController _popupController = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    // Show/hide the install popup anchored below the button.
    ref.listen<List<ActivityEntry>>(recentInstallPopupProvider, (_, next) {
      if (next.isNotEmpty) {
        if (!_popupController.isShowing) _popupController.show();
      } else {
        if (_popupController.isShowing) _popupController.hide();
      }
    });

    final downloads = ref.watch(downloadManager).value ?? [];
    final unseenCount = ref.watch(activityUnseenCount);
    final isOpen = ref.watch(appSettings.select((s) => s.isActivityPanelOpen));

    final batch = ref.watch(batchInstallationProvider);
    final history = ref.watch(activityHistoryStore).value;

    final data = _computeActivityData(
      batch: batch,
      history: history,
      unseenCount: unseenCount,
      downloads: downloads,
    );

    final hasActivity =
        data.activeBatchEntries.isNotEmpty ||
        data.inProgress.isNotEmpty ||
        data.unseenEntries.isNotEmpty;

    Widget iconStack = Stack(
      clipBehavior: Clip.none,
      children: [
        if (data.activeBatchEntries.isNotEmpty ||
            data.inProgress.isNotEmpty ||
            unseenCount > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _AggregateProgressRing(
              downloads: data.inProgress,
              allComplete:
                  data.activeBatchEntries.isEmpty &&
                  data.inProgress.isEmpty &&
                  unseenCount > 0,
            ),
          ),
        IconButton(
          icon: Icon(Icons.file_download, size: 18),
          onPressed: () => toggleActivityPanel(ref),
          style: IconButton.styleFrom(
            minimumSize: const Size(20, 20),
            shape: RoundedRectangleBorder(
              borderRadius: .circular(TriOSThemeConstants.cornerRadius),
            ),
            padding: .all(4),
            backgroundColor: isOpen
                ? Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08)
                : null,
          ),
        ),
        // Badge count (unseen completions).
        if (unseenCount > 0)
          Positioned(right: -2, top: -1, child: _Badge(count: unseenCount)),
      ],
    );

    // Anchor for the install popup so it can position itself below the button.
    iconStack = CompositedTransformTarget(link: _popupLink, child: iconStack);

    Widget result;
    if (hasActivity) {
      result = MovingTooltipWidget.framed(
        padding: .zero,
        tooltipWidgetBuilder: (_) => _ActivityTooltipContent(),
        child: iconStack,
      );
    } else {
      result = MovingTooltipWidget.text(
        message: 'Installation Activity',
        child: iconStack,
      );
    }

    // Only offer dismissing the badge when there's an unseen notification
    // (one or more mods finished while the panel was closed).
    if (unseenCount > 0) {
      result = ContextMenuRegion(
        contextMenu: ContextMenu(
          entries: [
            MenuItem(
              label: 'Dismiss notification',
              value: 'dismiss',
              onSelected: () {
                ref.read(activityUnseenCount.notifier).clearUnseen();
              },
            ),
          ],
        ),
        child: result,
      );
    }

    return OverlayPortal(
      controller: _popupController,
      overlayChildBuilder: (_) => _RecentInstallPopup(link: _popupLink),
      child: result,
    );
  }
}

class _ActivityTooltipContent extends ConsumerWidget {
  const _ActivityTooltipContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadManager).value ?? [];
    final unseenCount = ref.watch(activityUnseenCount);
    final batch = ref.watch(batchInstallationProvider);
    final history = ref.watch(activityHistoryStore).value;

    final data = _computeActivityData(
      batch: batch,
      history: history,
      unseenCount: unseenCount,
      downloads: downloads,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const .only(bottom: 4),
              child: Text('Installation Activity'),
            ),
            for (final entry in data.activeBatchEntries) BatchEntryTile(entry: entry),
            for (final d in data.inProgress)
              InProgressActivityTile(
                download: d,
                onCancel: () =>
                    ref.read(downloadManager.notifier).cancelDownload(d),
              ),
            for (final e in data.unseenEntries)
              CompletedActivityTile(entry: e, showActions: false),
          ],
        ),
      ),
    );
  }
}

/// Transient popup anchored below the activity button, shown when mods finish
/// installing while the panel is closed. Lets the user Enable the new mod(s)
/// (or Enable All) without opening the panel. Auto-dismisses after the standard
/// toast time; hovering pauses the countdown.
class _RecentInstallPopup extends ConsumerStatefulWidget {
  final LayerLink link;

  const _RecentInstallPopup({required this.link});

  @override
  ConsumerState<_RecentInstallPopup> createState() =>
      _RecentInstallPopupState();
}

class _RecentInstallPopupState extends ConsumerState<_RecentInstallPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countdown = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        ref.read(recentInstallPopupProvider.notifier).clear();
      }
    });

  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    // Match the user's notification duration setting (the same value toasts use).
    _countdown.duration = Duration(
      seconds: ref.read(appSettings.select((s) => s.toastDurationSeconds)),
    );
    _countdown.forward();
  }

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = ref.watch(recentInstallPopupProvider);

    // Restart the countdown when another install lands while the popup is up.
    ref.listen<List<ActivityEntry>>(recentInstallPopupProvider, (prev, next) {
      if (next.length > (prev?.length ?? 0) && !_hovering) {
        _countdown.forward(from: 0);
      }
    });

    if (entries.isEmpty) return const SizedBox.shrink();

    final mods = ref.watch(AppState.mods);
    final enableable = <Mod>[];
    for (final entry in entries) {
      final mod = entry.modId != null
          ? mods.firstWhereOrNull((m) => m.id == entry.modId)
          : mods.firstWhereOrNull(
              (m) => m.findHighestVersion?.modInfo.nameOrId == entry.modName,
            );
      if (mod != null &&
          mod.isEnabledInGame != true &&
          !enableable.contains(mod)) {
        enableable.add(mod);
      }
    }

    return CompositedTransformFollower(
      link: widget.link,
      showWhenUnlinked: false,
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.topRight,
      offset: const Offset(0, 4),
      child: Align(
        alignment: Alignment.topRight,
        child: MouseRegion(
          onEnter: (_) {
            _hovering = true;
            _countdown.stop();
          },
          onExit: (_) {
            _hovering = false;
            _countdown.forward();
          },
          child: TooltipFrame(
            padding: .zero,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const .only(
                      left: 16,
                      right: 8,
                      top: 8,
                      bottom: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entries.length == 1
                                ? 'Mod installed'
                                : 'Mods installed',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (enableable.length >= 2)
                          MovingTooltipWidget.text(
                            message: 'Enable all newly installed mods',
                            child: TextButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(modManager.notifier)
                                    .enableMultiple(enableable);
                              },
                              icon: const Icon(
                                Icons.power_settings_new,
                                size: 14,
                              ),
                              label: const Text('Enable All'),
                              style: TextButton.styleFrom(
                                padding: .symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (final entry in entries)
                    CompletedActivityTile(entry: entry, showActions: true),
                  // Shrinking bar showing time until the popup auto-dismisses.
                  Padding(
                    padding: const .only(top: 4),
                    child: AnimatedBuilder(
                      animation: _countdown,
                      builder: (_, _) => ThemedLinearProgressIndicator(
                        value: 1.0 - _countdown.value,
                        minHeight: 3,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AggregateProgressRing extends StatefulWidget {
  final List<Download> downloads;
  final bool allComplete;

  const _AggregateProgressRing({
    required this.downloads,
    this.allComplete = false,
  });

  @override
  State<_AggregateProgressRing> createState() => _AggregateProgressRingState();
}

class _AggregateProgressRingState extends State<_AggregateProgressRing> {
  @override
  void initState() {
    super.initState();
    _addListeners(widget.downloads);
  }

  @override
  void didUpdateWidget(_AggregateProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _removeListeners(oldWidget.downloads);
    _addListeners(widget.downloads);
  }

  @override
  void dispose() {
    _removeListeners(widget.downloads);
    super.dispose();
  }

  void _addListeners(List<Download> downloads) {
    for (final d in downloads) {
      d.task.downloaded.addListener(_onProgress);
      d.installProgress.addListener(_onProgress);
    }
  }

  void _removeListeners(List<Download> downloads) {
    for (final d in downloads) {
      d.task.downloaded.removeListener(_onProgress);
      d.installProgress.removeListener(_onProgress);
    }
  }

  void _onProgress() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final double? value;

    if (widget.allComplete) {
      value = 1.0;
    } else {
      int totalReceived = 0;
      int totalBytes = 0;

      for (final d in widget.downloads) {
        final status = d.task.status.value;
        if (!status.isCompleted) {
          final dl = d.task.downloaded.value;
          totalReceived += dl.bytesReceived;
          totalBytes += dl.totalBytes;
        } else {
          final ip = d.installProgress.value;
          if (ip != null && !ip.isIndeterminate) {
            totalReceived += ip.bytesReceived;
            totalBytes += ip.bytesTotal;
          }
        }
      }

      value = totalBytes > 0 ? totalReceived / totalBytes : null;
    }

    return SizedBox(
      height: 2,
      child: ThemedLinearProgressIndicator(value: value, alpha: 175),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: .symmetric(horizontal: 3, vertical: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
