import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/self_updater/script_generator.dart';
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
            padding: const EdgeInsets.only(top: 32, bottom: 8.0),
            child: ElevatedButton(
              onPressed: () async {
                var release = await SelfUpdater.getLatestRelease();
                if (release == null) {
                  Fimber.e("No release found");
                  return;
                }

                final zipDest = Directory.systemTemp.createTempSync("trios_update");
                // final zipFile = File("$zipDest/trios_update.zip");
                final downloadedFile =
                    await SelfUpdater.downloadRelease(release, zipDest, onProgress: (received, total) {
                  Fimber.v(
                      "Bytes received: ${received.bytesAsReadableMB()}, Total bytes: ${total.bytesAsReadableMB()}");
                });

                if (downloadedFile == null) {
                  return;
                }

                Fimber.i("Downloaded release to: ${downloadedFile.path}");

                await LibArchive().extractEntriesInArchive(downloadedFile, zipDest.absolute.path);
                Fimber.i("Extracted release to: ${zipDest.path}");
                downloadedFile.deleteSync();

                Fimber.i(
                    "Current version: $version. Latest version: ${release.tagName}. Newer? ${SelfUpdater.hasNewVersion(version, release!)}");
              },
              child: const Text('Test Update Checker'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Fimber.i(ScriptGenerator.generateFileUpdateScript([
                Tuple2(File("F:/Code/Starsector/TriOS/VRAM_usage_of_mods.txt2"),
                    File("F:/Code/Starsector/TriOS/VRAM_usage_of_mods.txt")),
                Tuple2(File("F:/Code/Starsector/TriOS/VRAM_usage_of_mods.txt"),
                    File("F:/Code/Starsector/TriOS/VRAM_usage_of_mods.txt2"))
              ], "windows", 2));
            },
            child: const Text('Print Update Script'),
          ),
          ElevatedButton(
            onPressed: () async {
              // LibArchive().getEntriesInArchive();
            },
            child: const Text('Load libarchive'),
          ),
        ],
      ),
    );
  }
}
