import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/app_state.dart';
import 'package:trios/main.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/checkbox_with_label.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final gamePathTextController = TextEditingController();
  bool gamePathExists = false;

  @override
  void initState() {
    super.initState();
    gamePathTextController.text = ref.read(appSettings).gameDir ?? "";
    gamePathExists = Directory(gamePathTextController.text).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: gamePathTextController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: gamePathExists ? null : "Path does not exist",
              labelText: 'Starsector Folder',
            ),
            onChanged: (newGameDir) {
              var dirExists = Directory(newGameDir).normalize.existsSync();
              final settings = ref.read(appSettings);

              if (dirExists) {
                ref.read(appSettings.notifier).update((state) {
                  var newModDirPath = settings.hasCustomModsDir
                      ? settings.modsDir?.toDirectory()
                      : generateModFolderPath(newGameDir.toDirectory());

                  return state.copyWith(gameDir: Directory(newGameDir).normalize.path, modsDir: newModDirPath?.path);
                });
              }

              setState(() {
                gamePathExists = dirExists;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8.0),
            child: Text("Mods Folder: ${ref.read(appSettings).modsDir}"),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: CheckboxWithLabel(
              value: ref.watch(appSettings.select((value) => value.shouldAutoUpdateOnLaunch)),
              onChanged: (value) {
                ref
                    .read(appSettings.notifier)
                    .update((state) => state.copyWith(shouldAutoUpdateOnLaunch: value ?? false));
              },
              label: "Auto-update on launch",
            ),
          ),
          // Debugging line here
          SizedBox.fromSize(size: const Size.fromHeight(20)),
          Text("Debugging stuff below here, please ignore.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed: () async {
                var release = await SelfUpdater.getLatestRelease();
                if (release == null) {
                  Fimber.e("No release found");
                  return;
                }

                Fimber.i(
                    "Current version: $version. Latest version: ${release.tagName}. Newer? ${SelfUpdater.hasNewVersion(release)}");
              },
              child: const Text('Has new release?'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed: () async {
                final scriptPath = File("F:\\Code\\Starsector\\TriOS\\update-test\\TriOS_self_updater.bat");
                Fimber.v("${scriptPath.path} ${scriptPath.existsSync()}");

                Process.start("start", ["", scriptPath.path],
                    runInShell: true, includeParentEnvironment: true, mode: ProcessStartMode.detached);
              },
              child: const Text('Run self-update script'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed: () async {
                var release = await SelfUpdater.getLatestRelease();
                if (release == null) {
                  Fimber.e("No release found");
                  return;
                }

                if (SelfUpdater.hasNewVersion(release)) {
                  Fimber.i("New version found: ${release.tagName}");
                } else {
                  Fimber.i("No new version found. Force updating anyway.");
                }

                SelfUpdater.update(release);
              },
              child: const Text('Force Self-Update'),
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                  onPressed: () {
                    toastification.show(context: context, title: const Text("Test toast"));
                  },
                  child: const Text('Show toast'))),
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                      onPressed: () async {
                        final latestRelease = await SelfUpdater.getLatestRelease();
                        SelfUpdater.update(latestRelease!, downloadProgress: (bytesReceived, contentLength) {
                          Fimber.i(
                              "Downloaded: ${bytesReceived.bytesAsReadableMB()} / ${contentLength.bytesAsReadableMB()}");
                          ref.read(selfUpdateDownloadProgress.notifier).update((_) => bytesReceived / contentLength);
                        });
                      },
                      child: const Text("Force Update")),
                ),
                LinearProgressIndicator(
                  value: ref.watch(selfUpdateDownloadProgress) ?? 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
