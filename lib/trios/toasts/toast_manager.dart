import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/toasts/mod_added_toast.dart';
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

  @override
  Widget build(BuildContext context) {
    final toastDurationMillis =
        ref.watch(appSettings.select((value) => value.toastDurationSeconds)) *
        1000;

    ref.listen(AppState.modVariants, (prevMods, currMods) {
      if (prevMods == null) return;
      if (prevMods.valueOrNull == null || currMods.valueOrNull == null) return;
      if (prevMods.valueOrNull?.length == currMods.valueOrNull?.length) return;
      final downloads = ref.watch(downloadManager).value.orEmpty().toList();

      // modAddedDebouncer.debounce(() async {
      showModAddedToasts(
        modsAtTimeOfLastRefresh ?? prevMods.valueOrNull,
        currMods.valueOrNull,
        downloads,
        context,
        toastDurationMillis,
      );
      // modsAtTimeOfLastRefresh = currMods.valueOrNull?.toList();
      // });
    });
    final downloads = ref.watch(downloadManager).value.orEmpty().toList();

    downloads
        // .filter((download) => download.status.value != DownloadStatus.completed)
        .whereNot((item) => _downloadToastIdsCreated.contains(item.id))
        .forEach((download) {
          // If the toast doesn't exist and has NEVER existed (don't re-show previously dismissed toasts)
          // do on next frame
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            toastification.showCustom(
              context: context,
              autoCloseDuration: Duration(milliseconds: toastDurationMillis),
              builder: (context, item) {
                _downloadToastIdsCreated.add(download.id);
                return ModDownloadToast(download, item, toastDurationMillis);
              },
            );
          });
        });

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
