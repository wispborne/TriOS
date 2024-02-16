import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vram_estimator_flutter/self_updater/script_generator.dart';
import 'package:vram_estimator_flutter/settings/settings.dart';
import 'package:vram_estimator_flutter/utils/extensions.dart';
import 'package:vram_estimator_flutter/utils/util.dart';

import '../../self_updater/checker.dart';

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
                await SelfUpdater.checkForUpdate();
              },
              child: const Text('Test Update Checker'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Fimber.i(ScriptGenerator.generateFileUpdateScript(
                  [Tuple2(null, File("test.txt"))], "windows", 5));
            },
            child: const Text('Print Update Script'),
          )
        ],
      ),
    );
  }
}
