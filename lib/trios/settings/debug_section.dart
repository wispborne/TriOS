import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/download_progress_indicator.dart';

import '../../widgets/self_update_toast.dart';
import '../app_state.dart';
import '../download_manager/download_manager.dart';
import '../toasts/mod_added_toast.dart';

class DebugSection extends ConsumerWidget {
  const DebugSection({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Padding(
        //   padding: const EdgeInsets.only(top: 16),
        //   child: ElevatedButton(
        //     onPressed: () async {
        //       final scriptPath = File(
        //           "F:\\Code\\Starsector\\TriOS\\update-test\\TriOS_self_updater.bat");
        //       Fimber.v("${scriptPath.path} ${scriptPath.existsSync()}");
        //
        //       Process.start("start", ["", scriptPath.path],
        //           runInShell: true,
        //           includeParentEnvironment: true,
        //           mode: ProcessStartMode.detached);
        //     },
        //     child: const Text('Run self-update script'),
        //   ),
        // ),
        // Padding(
        //   padding: const EdgeInsets.only(top: 16),
        //   child: ElevatedButton(
        //     onPressed: () async {
        //       var release = await SelfUpdater.getLatestRelease();
        //       if (release == null) {
        //         Fimber.e("No release found");
        //         return;
        //       }
        //
        //       if (SelfUpdater.hasNewVersion(release)) {
        //         Fimber.i("New version found: ${release.tagName}");
        //       } else {
        //         Fimber.i(
        //             "No new version found. Force updating anyway.");
        //       }
        //
        //       SelfUpdater.update(release);
        //     },
        //     child: const Text('Force Self-Update'),
        //   ),
        // ),
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
                onPressed: () async {
                  SelfUpdater.getLatestRelease().then((release) {
                    if (release == null) {
                      Fimber.d("No release found");
                      return;
                    }

                    toastification.showCustom(
                        context: context,
                        builder: (context, item) =>
                            SelfUpdateToast(release, item));
                  });
                },
                child: const Text('Show self-update toast'))),
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
                onPressed: () {
                  final testMod = ref
                      .read(AppState.modVariants)
                      .valueOrNull
                      .orEmpty()
                      .firstWhere((variant) =>
                          variant.modInfo.id.equalsIgnoreCase("magiclib"));
                  ref.read(downloadManager.notifier).addDownload(
                        "${testMod.modInfo.nameOrId} ${testMod.bestVersion}",
                        testMod.versionCheckerInfo!.directDownloadURL!,
                        Directory.systemTemp,
                        modInfo: testMod.modInfo,
                      );
                },
                child: const Text('Redownload MagicLib (shows toast)'))),
        // Show mod added toast
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
              onPressed: () {
                final testMod = ref
                    .read(AppState.modVariants)
                    .valueOrNull
                    .orEmpty()
                    .firstWhere((variant) =>
                        variant.modInfo.id.equalsIgnoreCase("magiclib"));
                toastification.showCustom(
                    context: context,
                    builder: (context, item) => ModAddedToast(
                        testMod,
                        item,
                        ref.watch(appSettings.select((value) =>
                                value.secondsBetweenModFolderChecks)) *
                            1000));
              },
              child: const Text('Show Mod Added Toast for MagicLib')),
        ),
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
                onPressed: () {
                  // confirmation prompt
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Are you sure?"),
                          content:
                              const Text("This will wipe TriOS's settings."),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () {
                                  sharedPrefs.clear();
                                  ref
                                      .read(appSettings.notifier)
                                      .update((state) => Settings());
                                },
                                child: const Text('Wipe Settings')),
                          ],
                        );
                      });
                },
                child: const Text('Wipe Settings'))),
        SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                    onPressed: () async {
                      final latestRelease =
                          await SelfUpdater.getLatestRelease();
                      ref
                          .read(AppState.selfUpdate.notifier)
                          .updateSelf(latestRelease!);
                    },
                    child: const Text("Force Update")),
              ),
              const SizedBox(height: 4),
              DownloadProgressIndicator(
                value: ref.watch(AppState.selfUpdate).valueOrNull ??
                    const DownloadProgress(0, 0, isIndeterminate: true),
              ),
            ],
          ),
        ),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: SelectionArea(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                              "Note: the below information is not collected by TriOS.\nThis is here in case TriOS is misbehaving, to hopefully see if anything looks wrong.",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                        ),
                        Text(
                          "Current directory (env variable): ${Directory.current.path}",
                        ),
                        Text(
                          "Current directory based on executable: ${Platform.resolvedExecutable}",
                        ),
                        Text(
                          "Current executable: ${Platform.resolvedExecutable}",
                        ),
                        Text("Temp folder: ${Directory.systemTemp.path}"),
                        Text("Locale: ${Platform.localeName}"),
                        Text(
                            "RAM usage: ${ProcessInfo.currentRss.bytesAsReadableMB()}"),
                        Text(
                            "Max RAM usage: ${ProcessInfo.maxRss.bytesAsReadableMB()}"),
                        SizedBox(
                          height: 150,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                ThemeManager.cornerRadius),
                            child: Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                              padding: const EdgeInsets.all(4),
                              child: SingleChildScrollView(
                                child: Text(
                                  "Environment variables\n${Platform.environment}",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                )))
      ],
    );
  }
}
