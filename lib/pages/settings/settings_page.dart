import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';

import '../../main.dart';
import '../../self_updater/self_updater.dart';

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
            onChanged: (value) {
              var dirExists = Directory(value).normalize.existsSync();

              if (dirExists) {
                ref.read(appSettings.notifier).update((state) => state.copyWith(
                    gameDir: Directory(value).normalize.path,
                    modsDir: modFolderPath(Directory(value))?.normalize.path));
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
            padding: const EdgeInsets.only(top: 32),
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

                Process.start("start", ["",  scriptPath.path],
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
        ],
      ),
    );
  }
}
