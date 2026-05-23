import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/activity_panel/activity_entry.dart';
import 'package:trios/trios/activity_panel/activity_panel_controller.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/toasts/widgets/companion_mod_update_toast.dart';
import 'package:trios/utils/extensions.dart';
import 'package:uuid/uuid.dart';

import '../app_state.dart';
import '../download_manager/download_manager.dart';
import '../download_manager/download_status.dart';

/// Manages toasts that are NOT handled by the Activity Panel.
///
/// After the Activity Panel migration, this only handles:
/// - Companion mod update toast
///
/// Download/install progress and "mod added" toasts are now
/// shown in the Activity Panel instead.
class ToastDisplayer extends ConsumerStatefulWidget {
  const ToastDisplayer({super.key});

  @override
  ConsumerState createState() => _ToastDisplayerState();
}

class _ToastDisplayerState extends ConsumerState<ToastDisplayer> {
  bool _companionModToastShown = false;

  /// Download IDs for which we've already recorded a completion entry.
  final _recordedCompletionIds = <String>{};

  @override
  Widget build(BuildContext context) {
    // Companion mod version check toast.
    ref.listen(AppState.mods, (_, mods) {
      if (_companionModToastShown) return;
      if (mods.isEmpty) return;
      final companionMod = mods.firstWhereOrNull(
        (m) => m.id == Constants.companionModId,
      );
      if (companionMod == null || !companionMod.isEnabledOnUi) return;
      final installedVersion = companionMod.findFirstEnabled?.modInfo.version;
      final requiredVersion = Version.parse(Constants.companionModVersion);
      if (installedVersion != null && installedVersion < requiredVersion) {
        _companionModToastShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          toastification.showCustom(
            context: context,
            builder: (context, item) =>
                CompanionModUpdateToast(installedVersion, item),
          );
        });
      }
    });

    // Route download/install completions to the Activity Panel history.
    final downloads = ref.watch(downloadManager).value.orEmpty().toList();
    for (final download in downloads) {
      if (_recordedCompletionIds.contains(download.id)) continue;
      final status = download.task.status.value;
      final downloadFailed =
          status == DownloadStatus.failed || status == DownloadStatus.canceled;
      if (!downloadFailed &&
          !download.installComplete.value &&
          !download.installCancelled.value) {
        continue;
      }
      // Don't record user-cancelled installs.
      if (!downloadFailed && download.installCancelled.value) {
        _recordedCompletionIds.add(download.id);
        continue;
      }

      _recordedCompletionIds.add(download.id);
      final wasCancelled =
          status == DownloadStatus.canceled && !download.hasInstallError;
      final hasFailed =
          !wasCancelled && (downloadFailed || download.hasInstallError);
      final variant = download.installedVariant.value;
      final modInfo = (download is ModDownload) ? download.modInfo : null;
      // Archive installs have an empty directory field (addInstallation puts the
      // source path in the url field and leaves directory empty).
      final isArchive = download.task.request.directory.isEmpty;

      final entry = ActivityEntry(
        id: const Uuid().v4(),
        modName:
            variant?.modInfo.nameOrId ??
            modInfo?.nameOrId ??
            download.displayName,
        modId: variant?.modInfo.id ?? modInfo?.id,
        modVersion:
            variant?.modInfo.version?.toString() ??
            modInfo?.version?.toString(),
        sourceType: isArchive
            ? ActivitySourceType.archive
            : ActivitySourceType.download,
        sourceDetail: download.task.request.url.isNotEmpty
            ? download.task.request.url
            : null,
        timestamp: DateTime.now(),
        status: wasCancelled
            ? ActivityStatus.cancelled
            : hasFailed
                ? ActivityStatus.failed
                : ActivityStatus.completed,
        errorMessage: hasFailed ? download.task.error?.toString() : null,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activityHistoryStore.notifier).recordCompletion(entry);
        // Increment unseen count if panel is closed.
        final isOpen = ref.read(
          appSettings.select((s) => s.isActivityPanelOpen),
        );
        if (!isOpen) {
          ref.read(activityUnseenCount.notifier).increment();
        }
      });
    }

    return const SizedBox.shrink();
  }
}
