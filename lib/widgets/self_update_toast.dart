import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/download_progress_indicator.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/trios_app_icon.dart';

import '../trios/app_state.dart';
import '../trios/constants.dart';
import '../utils/network_util.dart';
import 'changelog_viewer.dart';

class SelfUpdateToast extends ConsumerWidget {
  const SelfUpdateToast(this.latestRelease, this.item, {super.key});

  final Release latestRelease;
  final ToastificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: Card(
        surfaceTintColor: Theme.of(context).colorScheme.secondary,
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
            border: Border.all(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                width: 1),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  const TriOSAppIcon(),
                  Expanded(
                    child: Column(
                      children: [
                        const Text("New ${Constants.appName} version"),
                        Text("${latestRelease.tagName} is now available!",
                            style: Theme.of(context).textTheme.labelLarge),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton.icon(
                                  onPressed: () => showTriOSChangelogDialog(
                                      context,
                                      showUnreleasedVersions: true),
                                  icon: const SvgImageIcon(
                                    "assets/images/icon-log.svg",
                                  ),
                                  label: const Text("View Changelog")),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Disable(
                                isEnabled:
                                    ref.watch(AppState.selfUpdate).valueOrNull == null,
                                child: ElevatedButton.icon(
                                    onPressed: () {
                                      ref
                                          .read(AppState.selfUpdate.notifier)
                                          .updateSelf(latestRelease);
                                    },
                                    icon: const Icon(Icons.download),
                                    label: const Text("Update")),
                              ),
                            ),
                          ],
                        ),
                        DownloadProgressIndicator(
                          value: ref.watch(AppState.selfUpdate).valueOrNull ??
                              const DownloadProgress(0, 0,
                                  isIndeterminate: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  onPressed: () => toastification.dismiss(item),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
