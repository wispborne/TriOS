import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/download_progress_indicator.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../../themes/theme.dart';
import '../../themes/theme_manager.dart';
import '../../widgets/self_update_toast.dart';
import '../app_state.dart';
import '../constants.dart';

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
    gamePathTextController.text = ref.read(appSettings).gameDir?.path ?? "";
    gamePathExists = Directory(gamePathTextController.text).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettings);

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: gamePathTextController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    errorText: gamePathExists ? null : "Path does not exist",
                    labelText: 'Starsector Folder',
                  ),
                  onChanged: (newGameDir) {
                    tryUpdateGamePath(newGameDir, settings);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.folder),
                onPressed: () async {
                  var newGameDir = await FilePicker.platform.getDirectoryPath();
                  if (newGameDir == null) return;
                  tryUpdateGamePath(newGameDir, settings);
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 8.0),
          child: Text("Mods Folder: ${ref.read(appSettings).modsDir?.path}",
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontFeatures: [const FontFeature.tabularFigures()])),
        ),
        SizedBox.fromSize(size: const Size.fromHeight(8)),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CheckboxWithLabel(
            value: ref.watch(
                appSettings.select((value) => value.shouldAutoUpdateOnLaunch)),
            onChanged: (value) {
              ref.read(appSettings.notifier).update((state) =>
                  state.copyWith(shouldAutoUpdateOnLaunch: value ?? false));
            },
            label: "Auto-update ${Constants.appName} on launch",
          ),
        ),
        // Tooltip(
        //     message:
        //         "Switches between versions 2 and 3 of Google's 'Material Design' UI style.",
        //     child: Padding(
        //       padding: const EdgeInsets.only(top: 8.0),
        //       child: CheckboxWithLabel(
        //           label: "Use Material Design 3",
        //           onChanged: (_) => AppState.theme.switchMaterial(),
        //           value: AppState.theme.isMaterial3()),
        //     )),
        SizedBox.fromSize(size: const Size.fromHeight(20)),
        Text("Theme", style: theme.textTheme.bodyLarge),
        Row(
          children: [
            DropdownMenu(
              dropdownMenuEntries: ThemeManager.allThemes.entries
                  .map((theme) => (
                        theme.key,
                        theme,
                        ThemeManager.convertToThemeData(theme.value)
                      ))
                  .map((obj) {
                    var (key, triosTheme, themeData) = obj;
                    return DropdownMenuEntry(
                      value: triosTheme.value,
                      style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                              themeData.scaffoldBackgroundColor)),
                      labelWidget: Row(
                        children: [
                          SizedBox(
                              width: 40,
                              height: 20,
                              child: Container(
                                  color: themeData.colorScheme.primary,
                                  child: const SizedBox.shrink())),
                          const SizedBox(width: 8),
                          SizedBox(
                              width: 20,
                              height: 20,
                              child: Container(
                                  color: themeData.colorScheme.secondary,
                                  child: const SizedBox.shrink())),
                          const SizedBox(width: 16),
                          Text(triosTheme.key,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: themeData.colorScheme.onSurface,
                              )),
                        ],
                      ),
                      label: triosTheme.key,
                    );
                  })
                  .distinctBy((e) => e.value)
                  .toList(),
              onSelected: (TriOSTheme? theme) =>
                  AppState.theme.switchThemes(context, theme!),
              initialSelection: AppState.theme.currentTheme(),
              // borderRadius: BorderRadius.all(
              //     Radius.circular(ThemeManager.cornerRadius)),
              // padding: const EdgeInsets.symmetric(horizontal: 0),
            ),
            IconButton(
              tooltip: "I'm feeling lucky",
              onPressed: () => AppState.theme.switchThemes(
                  context, ThemeManager.allThemes.values.random()),
              icon: SvgImageIcon(
                "assets/images/icon-dice.svg",
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        // Slider for number of seconds between mod info update checks (secondsBetweenModFolderChecks in mod_manager_logic.dart).
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message:
                      "This sets how often we check if there are new or changed mods in your folder.\nA shorter time means more frequent checks.\nDoes not scan when ${Constants.appName} is in the background.",
                  child: Text(
                      "Rescan mod folder every: ${ref.watch(appSettings.select((value) => value.secondsBetweenModFolderChecks))} seconds",
                      style: theme.textTheme.bodyLarge),
                ),
                Slider(
                  value: ref
                      .watch(appSettings.select(
                          (value) => value.secondsBetweenModFolderChecks))
                      .toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  label:
                      "${ref.watch(appSettings.select((value) => value.secondsBetweenModFolderChecks))}",
                  onChanged: (value) {
                    ref.read(appSettings.notifier).update((state) =>
                        state.copyWith(
                            secondsBetweenModFolderChecks: value.toInt()));
                  },
                  inactiveColor: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        // Debugging line here
        SizedBox.fromSize(size: const Size.fromHeight(20)),
        ExpansionTile(
          title: const Text("Debugging"),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                          "Current version: ${Constants.version}. Latest version: ${release.tagName}. Newer? ${SelfUpdater.hasNewVersion(release)}");
                    },
                    child: const Text('Has new release?'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: () async {
                      final scriptPath = File(
                          "F:\\Code\\Starsector\\TriOS\\update-test\\TriOS_self_updater.bat");
                      Fimber.v("${scriptPath.path} ${scriptPath.existsSync()}");

                      Process.start("start", ["", scriptPath.path],
                          runInShell: true,
                          includeParentEnvironment: true,
                          mode: ProcessStartMode.detached);
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
                        Fimber.i(
                            "No new version found. Force updating anyway.");
                      }

                      SelfUpdater.update(release);
                    },
                    child: const Text('Force Self-Update'),
                  ),
                ),
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
                        child: const Text('Show toast'))),
                Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                        onPressed: () {
                          sharedPrefs.clear();
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
                              SelfUpdater.update(latestRelease!,
                                  downloadProgress:
                                      (bytesReceived, contentLength) {
                                Fimber.i(
                                    "Downloaded: ${bytesReceived.bytesAsReadableMB()} / ${contentLength.bytesAsReadableMB()}");
                                ref
                                    .read(AppState
                                        .selfUpdateDownloadProgress.notifier)
                                    .update((_) => DownloadProgress(
                                        bytesReceived, contentLength));
                              });
                            },
                            child: const Text("Force Update")),
                      ),
                      DownloadProgressIndicator(
                        value: ref.watch(AppState.selfUpdateDownloadProgress) ??
                            const DownloadProgress(0, 0, isIndeterminate: true),
                      ),
                    ],
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                        onPressed: () {
                          FilePicker.platform
                              .pickFiles(allowMultiple: true)
                              .then((value) {
                            if (value == null) return;

                            final file = File(value.files.single.path!);
                            Fimber.i("Installing mod: ${file.path}");
                            installModFromArchiveWithDefaultUI(
                                file, ref, context);
                          });
                        },
                        child: const Text('Install mod'))),
              ],
            ),
          ],
        ),
      ]),
    );
  }

  void tryUpdateGamePath(String newGameDir, Settings settings) {
    var dirExists = validateGameFolderPath(newGameDir);

    if (dirExists) {
      ref.read(appSettings.notifier).update((state) {
        var newModDirPath = settings.hasCustomModsDir
            ? settings.modsDir?.toDirectory()
            : generateModFolderPath(newGameDir.toDirectory());

        return state.copyWith(
            gameDir: Directory(newGameDir).normalize, modsDir: newModDirPath);
      });
    }

    setState(() {
      gamePathExists = dirExists;
    });
  }

  bool validateGameFolderPath(String newGameDir) =>
      Directory(newGameDir).normalize.existsSync();
}
