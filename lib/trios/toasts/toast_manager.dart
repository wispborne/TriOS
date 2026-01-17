import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/toasts/mod_added_toast.dart';
import 'package:trios/trios/toasts/notification_group_config.dart';
import 'package:trios/trios/toasts/notification_group_manager.dart';
import 'package:trios/trios/toasts/widgets/mod_download_group_toast.dart';
import 'package:trios/utils/debouncer.dart';
import 'package:trios/utils/extensions.dart';

import '../app_state.dart';
import '../download_manager/download_manager.dart';
import 'mod_download_toast.dart';

class ToastDisplayer extends ConsumerStatefulWidget {
  const ToastDisplayer({super.key});

  @override
  ConsumerState createState() => _ToastDisplayerState();
}

final _downloadToastIdsCreated = <String>{};

class _ToastDisplayerState extends ConsumerState<ToastDisplayer> {
  final modAddedDebouncer = Debouncer(duration: Duration(milliseconds: 750));
  List<ModVariant>? modsAtTimeOfLastRefresh;
  final _groupManager = NotificationGroupManager();
  final _groupToastIdsCreated = <String>{};
  Timer? _groupCheckTimer;

  @override
  Widget build(BuildContext context) {
    final toastDurationMillis =
        ref.watch(appSettings.select((value) => value.toastDurationSeconds)) *
        1000;

    ref.listen(AppState.modVariants, (prevMods, currMods) {
      if (prevMods == null) return;
      if (prevMods.value == null || currMods.value == null) return;
      if (prevMods.value?.length == currMods.value?.length) return;
      final downloads = ref.watch(downloadManager).value.orEmpty().toList();

      // modAddedDebouncer.debounce(() async {
      showModAddedToasts(
        modsAtTimeOfLastRefresh ?? prevMods.value,
        currMods.value,
        downloads,
        context,
        toastDurationMillis,
      );
      // modsAtTimeOfLastRefresh = currMods.value?.toList();
      // });
    });
    final downloads = ref.watch(downloadManager).value.orEmpty().toList();

    // Handle download toast grouping
    _handleDownloadGrouping(downloads, context, toastDurationMillis);

    // Fimber.i("Clear all id: $clearAllId");
    //
    // if (clearAllId == null &&
    //     (_downloadIdToToastIdMap.isNotEmpty ||
    //         _smolIdToModAddedToastIdMap.isNotEmpty)) {
    //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //     clearAllId = toastification
    //         .showCustom(
    //             context: context,
    //             builder: (context, item) => FloatingActionButton(
    //                   onPressed: () {
    //                     clearAllId = null;
    //                     _downloadIdToToastIdMap.clear();
    //                     _smolIdToModAddedToastIdMap.clear();
    //                     toastification.dismissAll(delayForAnimation: true);
    //                   },
    //                   child: const Icon(Icons.clear_all),
    //                 ))
    //         .id;
    //   });
    // }

    return Container();
  }

  void _handleDownloadGrouping(
    List<Download> downloads,
    BuildContext context,
    int toastDurationMillis,
  ) {
    final config = NotificationGroupConfigs.modDownloads;
    final ungroupedDownloads = downloads
        .whereNot((item) => _downloadToastIdsCreated.contains(item.id))
        .whereNot((item) => _groupManager.isItemGrouped(item.id))
        .toList();

    // Try to group new downloads
    for (final download in ungroupedDownloads) {
      final groupId = _groupManager.tryGroupItem(
        NotificationGroupType.modDownloads,
        config,
        download,
        download.id,
      );

      if (groupId != null) {
        // Item was added to existing active group
        _downloadToastIdsCreated.add(download.id);

        // If group toast already exists, it will update automatically via listeners
        // If not, we'll show it after the initial window
      } else {
        // Item started a new group, mark as grouped
        _downloadToastIdsCreated.add(download.id);
      }
    }

    // Schedule check to show group toast after initial grouping window
    if (ungroupedDownloads.isNotEmpty) {
      _scheduleGroupCheck(config.initialGroupingWindow, context, toastDurationMillis);
    }

    // Check if we should show the group toast now
    _checkAndShowGroupToast(context, toastDurationMillis);
  }

  void _scheduleGroupCheck(Duration delay, BuildContext context, int toastDurationMillis) {
    _groupCheckTimer?.cancel();
    _groupCheckTimer = Timer(delay, () {
      if (mounted) {
        setState(() {
          _checkAndShowGroupToast(context, toastDurationMillis);
        });
      }
    });
  }

  void _checkAndShowGroupToast(BuildContext context, int toastDurationMillis) {
    final group = _groupManager.getGroup(NotificationGroupType.modDownloads);

    if (group != null &&
        group.shouldGroup() &&
        !_groupToastIdsCreated.contains(group.id)) {
      // Show the grouped toast
      WidgetsBinding.instance.addPostFrameCallback((_) {
        toastification.showCustom(
          context: context,
          autoCloseDuration: Duration(milliseconds: toastDurationMillis),
          builder: (context, item) {
            _groupToastIdsCreated.add(group.id);
            return ModDownloadGroupToast(
              group as NotificationGroup<Download>,
              item,
              toastDurationMillis,
            );
          },
        );
      });
    } else if (group != null &&
               !group.shouldGroup() &&
               !_groupToastIdsCreated.contains(group.id)) {
      // Only one item in group after waiting - show individual toast
      final download = group.items.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        toastification.showCustom(
          context: context,
          autoCloseDuration: Duration(milliseconds: toastDurationMillis),
          builder: (context, item) {
            return ModDownloadToast(download, item, toastDurationMillis);
          },
        );
      });
      // Mark group as shown so we don't try again
      _groupToastIdsCreated.add(group.id);
    }
  }

  @override
  void dispose() {
    _groupCheckTimer?.cancel();
    super.dispose();
  }

  void showModAddedToasts(
    List<ModVariant>? prevMods,
    List<ModVariant>? currMods,
    List<Download> downloads,
    BuildContext context,
    int toastDurationMillis,
  ) {
    final prevModsList = prevMods.orEmpty().toList();
    final currModsList = currMods.orEmpty().toList();
    final addedVariants = currModsList
        .where(
          (element) => prevModsList.none((e) => e.smolId == element.smolId),
        )
        .toList();
    // final removedVariants = prevModsList
    //     .where(
    //         (element) => currModsList.none((e) => e.smolId == element.smolId))
    //     .toList();

    for (final newlyAddedVariant in addedVariants) {
      // If a download toast is already showing for this mod, don't show the mod added toast
      if (downloads.whereType<ModDownload>().any(
        (element) => element.modInfo.smolId == newlyAddedVariant.smolId,
      )) {
        continue;
      }

      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        toastification.showCustom(
          context: context,
          autoCloseDuration: Duration(milliseconds: toastDurationMillis),
          builder: (context, item) {
            return ModAddedToast(newlyAddedVariant, item);
          },
        );
      });
    }
  }
}
