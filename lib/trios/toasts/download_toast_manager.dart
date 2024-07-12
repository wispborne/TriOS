import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/trios/toasts/mod_added_toast.dart';
import 'package:trios/utils/extensions.dart';

import '../app_state.dart';
import '../download_manager/download_manager.dart';
import 'mod_download_toast.dart';

class ToastDisplayer extends ConsumerStatefulWidget {
  const ToastDisplayer({super.key});

  @override
  ConsumerState createState() => _ToastDisplayerState();
}

class _ToastDisplayerState extends ConsumerState<ToastDisplayer> {
  final _downloadIdToToastIdMap = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final modVariants = ref.listen(AppState.modVariants, (prevMods, currMods) {
      if (prevMods == null || currMods == null) return;
      if (prevMods.valueOrNull == null || currMods.valueOrNull == null) return;
      if (prevMods.valueOrNull?.length == currMods.valueOrNull?.length) return;

      final prevModsList = prevMods.valueOrNull.orEmpty().toList();
      final currModsList = currMods.valueOrNull.orEmpty().toList();
      final addedVariants = currModsList
          .where(
              (element) => prevModsList.none((e) => e.smolId == element.smolId))
          .toList();
      final removedVariants = prevModsList
          .where(
              (element) => currModsList.none((e) => e.smolId == element.smolId))
          .toList();

      for (final newlyAddedVariant in addedVariants) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          toastification.showCustom(
              context: context,
              builder: (context, item) {
                return ModAddedToast(newlyAddedVariant, item);
              });
        });
      }
    });
    final downloads = ref.watch(downloadManager).value.orEmpty().toList();

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
