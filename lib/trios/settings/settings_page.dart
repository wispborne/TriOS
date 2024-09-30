import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/thirdparty/dartx/comparable.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/settings_group.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/text_with_icon.dart';

import '../../models/version.dart';
import '../../themes/theme.dart';
import '../../themes/theme_manager.dart';
import '../../widgets/restartable_app.dart';
import '../../widgets/self_update_toast.dart';
import '../../widgets/trios_expansion_tile.dart';
import '../app_state.dart';
import '../constants.dart';
import 'debug_section.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final gamePathTextController = TextEditingController();
  bool gamePathExists = false;
  final _scrollController = ScrollController();

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
    const leftTextOptionPadding = 4.0;

    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: false,
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SettingsGroup(name: "Game Location", children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: gamePathTextController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  errorText: gamePathExists
                                      ? null
                                      : "Path does not exist",
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
                                var newGameDir = await FilePicker.platform
                                    .getDirectoryPath();
                                if (newGameDir == null) return;
                                tryUpdateGamePath(newGameDir, settings);
                                gamePathTextController.text = newGameDir;
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: leftTextOptionPadding, top: 8.0),
                        child: SelectableText(
                          "Mods Folder: ${ref.read(appSettings).modsDir?.path}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontFeatures: [
                                const FontFeature.tabularFigures()
                              ]),
                        ),
                      ),
                    ]),
                    SettingsGroup(
                      name: "${Constants.appName} Updates",
                      children: [
                        CheckboxWithLabel(
                          value: ref.watch(appSettings.select(
                              (value) => value.shouldAutoUpdateOnLaunch)),
                          onChanged: (value) {
                            ref.read(appSettings.notifier).update((state) =>
                                state.copyWith(
                                    shouldAutoUpdateOnLaunch: value ?? false));
                          },
                          label: "Auto-update ${Constants.appName} on launch",
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Tooltip(
                            message: "Play with fire.",
                            child: CheckboxWithLabel(
                              value: ref.watch(appSettings.select(
                                  (value) => value.updateToPrereleases)),
                              onChanged: (value) {
                                ref.read(appSettings.notifier).update((state) =>
                                    state.copyWith(
                                        updateToPrereleases: value ?? false));
                              },
                              labelWidget: const TextWithIcon(
                                  text:
                                      "Update to ${Constants.appName} pre-releases",
                                  trailing: Icon(Icons.warning_rounded)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckForUpdatesButton(ref: ref),
                      ],
                    ),
                    SettingsGroup(name: "Theme", children: [
                      Row(
                        children: [
                          DropdownMenu(
                            dropdownMenuEntries: ThemeManager.allThemes.entries
                                .map((theme) => (
                                      theme.key,
                                      theme,
                                      ThemeManager.convertToThemeData(
                                          theme.value)
                                    ))
                                .map((obj) {
                                  var (key, triosTheme, themeData) = obj;
                                  return DropdownMenuEntry(
                                    value: triosTheme.value,
                                    style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(themeData
                                                .scaffoldBackgroundColor)),
                                    labelWidget: Row(
                                      children: [
                                        SizedBox(
                                            width: 40,
                                            height: 20,
                                            child: Container(
                                                color: themeData
                                                    .colorScheme.primary,
                                                child:
                                                    const SizedBox.shrink())),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Container(
                                                color: themeData
                                                    .colorScheme.secondary,
                                                child:
                                                    const SizedBox.shrink())),
                                        const SizedBox(width: 16),
                                        Text(triosTheme.key,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurface,
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
                                context,
                                ThemeManager.allThemes.values.random()),
                            icon: SvgImageIcon(
                              "assets/images/icon-dice.svg",
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ]),
                    Builder(builder: (context) {
                      final lastNVersionsSetting = ref.watch(
                          appSettings.select((s) => s.keepLastNVersions));
                      return SettingsGroup(name: "Mod Organization", children: [
                        Tooltip(
                          message:
                              "If enabled, TriOS will always add the version number to the folder name when installing a mod."
                              "\nFor example; LazyLib-1.8b, LazyLib-1.8, LazyLib-1.7."
                              "\n\nIf disabled, the latest mod won't change folder name, even when you update the mod."
                              "\nOlder versions of a mod will still include the version number in order to tell them apart."
                              "\nFor example; LazyLib, LazyLib-1.8, LazyLib-1.7.",
                          child: CheckboxWithLabel(
                              value: ref.watch(appSettings
                                      .select((s) => s.folderNamingSetting)) ==
                                  FolderNamingSetting.allFoldersVersioned,
                              onChanged: (value) {
                                ref.read(appSettings.notifier).update((state) =>
                                    state.copyWith(
                                        folderNamingSetting: value == true
                                            ? FolderNamingSetting
                                                .allFoldersVersioned
                                            : FolderNamingSetting
                                                .doNotChangeNameForHighestVersion));
                              },
                              label: "Rename all mod folders"),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Tooltip(
                            message:
                                "Manual mode. TriOS will not rename folders."
                                "\nThis may result in TriOS overwriting mods when updating or installing new versions, if the folder already exists."
                                "\nFor example, if you have folder `LazyLib` and install a new version where the folder name is also `LazyLib`, the older one will be overwritten."
                                "\n\nTODO: clean up this UI and use a dropdown or something :)",
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(
                                  ThemeManager.cornerRadius),
                            ),
                            child: CheckboxWithLabel(
                                value: ref.watch(appSettings.select(
                                        (s) => s.folderNamingSetting)) ==
                                    FolderNamingSetting.doNotChangeNamesEver,
                                onChanged: (value) {
                                  ref.read(appSettings.notifier).update(
                                      (state) => state.copyWith(
                                          folderNamingSetting: value == true
                                              ? FolderNamingSetting
                                                  .doNotChangeNamesEver
                                              : FolderNamingSetting
                                                  .doNotChangeNameForHighestVersion));
                                },
                                label: "Manual folder naming"),
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: leftTextOptionPadding, top: 8),
                          child: Row(
                            children: [
                              Tooltip(
                                message:
                                    "If you have multiple versions of a mod, this will keep the last N versions of each mod."
                                    "\n\nOlder versions will be automatically deleted when a new one is installed.",
                                child: Row(
                                  children: [
                                    const Text("Keep last "),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: DropdownButton<int>(
                                        value: lastNVersionsSetting,
                                        items: [
                                          const DropdownMenuItem(
                                              value: null, child: Text(" ∞")),
                                          for (int i = 1; i <= 10; i++)
                                            DropdownMenuItem(
                                                value: i, child: Text(" $i")),
                                        ],
                                        onChanged: (value) {
                                          ref.read(appSettings.notifier).update(
                                                (state) => state.copyWith(
                                                    keepLastNVersions:
                                                        value == -1
                                                            ? null
                                                            : value),
                                              );
                                        },
                                        isDense: true,
                                        // decoration: const InputDecoration(
                                        //   border: OutlineInputBorder(),
                                        // ),
                                      ),
                                    ),
                                    Text(
                                        " version${lastNVersionsSetting == 1 ? "" : "s"} of each mod"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Disable(
                          isEnabled: lastNVersionsSetting != null,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Tooltip(
                              message: switch (lastNVersionsSetting) {
                                null => "",
                                1 =>
                                  "Remove all but the newest version of each mod.",
                                _ =>
                                  "Remove all but the newest $lastNVersionsSetting versions of each mod."
                              },
                              child: ElevatedButton.icon(
                                  icon: const SvgImageIcon(
                                    "assets/images/icon-shredder.svg",
                                  ),
                                  onPressed: () async {
                                    final modsThatWouldBeRemoved = await ref
                                        .read(modManager.notifier)
                                        .cleanUpAllModVariantsBasedOnRetainSetting(
                                          dryRun: true,
                                        );

                                    if (!mounted) return;
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text("Delete mods"),
                                            content: Column(
                                              children: [
                                                Text(
                                                    "Are you sure you want to delete ${modsThatWouldBeRemoved.length} mods?"),
                                                const SizedBox(height: 8),
                                                if (modsThatWouldBeRemoved
                                                    .isNotEmpty)
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: modsThatWouldBeRemoved
                                                        .map((mod) => Text(
                                                            "- ${mod.nameOrId} ${mod.version}"))
                                                        .toList(),
                                                  ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text("Cancel")),
                                              TextButton(
                                                  onPressed: () async {
                                                    Navigator.of(context).pop();
                                                    await ref
                                                        .read(
                                                            modManager.notifier)
                                                        .cleanUpAllModVariantsBasedOnRetainSetting(
                                                          dryRun: false,
                                                        );
                                                    ref.invalidate(
                                                        AppState.modVariants);
                                                  },
                                                  child: const Text("Delete")),
                                            ],
                                          );
                                        });
                                  },
                                  label: const Text("Clean up...")),
                            ),
                          ),
                        ),
                      ]);
                    }),
                    SettingsGroup(name: "Misc", children: [
                      // Slider for number of seconds between mod info update checks (secondsBetweenModFolderChecks in mod_manager_logic.dart).
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tooltip(
                              message:
                                  "This sets how often we check if there are new or changed mods in your folder.\nA shorter time means more frequent checks.\nDoes not scan when ${Constants.appName} is in the background.",
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: leftTextOptionPadding),
                                child: Text(
                                    "Rescan mod folder every: ${ref.watch(appSettings.select((value) => value.secondsBetweenModFolderChecks))} seconds",
                                    style: theme.textTheme.bodyLarge),
                              ),
                            ),
                            Slider(
                              value: ref
                                  .watch(appSettings.select((value) =>
                                      value.secondsBetweenModFolderChecks))
                                  .toDouble()
                                  .clamp(1, 30),
                              min: 1,
                              max: 30,
                              divisions: 29,
                              label:
                                  "${ref.watch(appSettings.select((value) => value.secondsBetweenModFolderChecks))}",
                              onChanged: (value) {
                                ref.read(appSettings.notifier).update((state) =>
                                    state.copyWith(
                                        secondsBetweenModFolderChecks:
                                            value.toInt()));
                              },
                              inactiveColor:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: leftTextOptionPadding, top: 16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Toast duration: ${ref.watch(appSettings.select((value) => value.toastDurationSeconds))} seconds",
                                  style: theme.textTheme.bodyLarge),
                              Slider(
                                value: ref
                                    .watch(appSettings.select(
                                        (value) => value.toastDurationSeconds))
                                    .toDouble()
                                    .clamp(1, 45),
                                min: 1,
                                max: 45,
                                divisions: 45,
                                label:
                                    "${ref.watch(appSettings.select((value) => value.toastDurationSeconds))}",
                                onChanged: (value) {
                                  ref.read(appSettings.notifier).update(
                                      (state) => state.copyWith(
                                          toastDurationSeconds: value.toInt()));
                                },
                                inactiveColor: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: leftTextOptionPadding, top: 16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Tooltip(
                            message: "Affects how quickly Version Checker searches. If version checker is showing timeout errors, reduce this number.",
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Max HTTP requests at once: ${ref.watch(appSettings.select((value) => value.maxHttpRequestsAtOnce))}",
                                    style: theme.textTheme.bodyLarge),
                                Slider(
                                  value: ref
                                      .watch(appSettings.select(
                                          (value) => value.maxHttpRequestsAtOnce))
                                      .toDouble()
                                      .clamp(1, 100),
                                  min: 1,
                                  max: 100,
                                  divisions: 10,
                                  label:
                                      "${ref.watch(appSettings.select((value) => value.maxHttpRequestsAtOnce))}",
                                  onChanged: (value) {
                                    ref.read(appSettings.notifier).update(
                                        (state) => state.copyWith(
                                            maxHttpRequestsAtOnce:
                                                value.toInt()));
                                  },
                                  inactiveColor: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Checkbox for enabling crash reporting
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Tooltip(
                          message:
                              "This allows ${Constants.appName} to send crash/error reports to get fixed.\nNo personal/identifiable data is sent.\nWill soft-restart ${Constants.appName}.",
                          child: CheckboxWithLabel(
                            value: ref.watch(appSettings.select(
                                (value) => value.allowCrashReporting ?? false)),
                            onChanged: (value) {
                              ref.read(appSettings.notifier).update((state) =>
                                  state.copyWith(
                                      allowCrashReporting: value ?? false));
                              RestartableApp.restartApp(context);
                            },
                            label: "Allow crash reporting",
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Tooltip(
                          message:
                              "Whether to check for mod dependencies and prevent launching if they aren't met."
                              "\nDisable if TriOS is getting them wrong, or you'd just like to use vanilla dependency check behavior.",
                          child: CheckboxWithLabel(
                            value: ref.watch(appSettings.select((value) =>
                                value.enableLauncherPrecheck ?? false)),
                            onChanged: (value) {
                              ref.read(appSettings.notifier).update((state) =>
                                  state.copyWith(
                                      enableLauncherPrecheck: value ?? false));
                            },
                            label: "Enable Launch Precheck",
                          ),
                        ),
                      ),
                    ]),
                    // Debugging line here
                    SizedBox.fromSize(size: const Size.fromHeight(20)),
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: TriOSExpansionTile(
                        title: const Text("Debugging Stuff"),
                        leading: Icon(Icons.bug_report,
                            color: Theme.of(context)
                                .iconTheme
                                .color
                                ?.withOpacity(0.7)),
                        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: SettingsDebugSection(),
                          ),
                        ],
                      ),
                    ),
                  ]),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Opacity(
              opacity: 0.7,
              child: Text("All settings are applied immediately.",
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontStyle: FontStyle.italic))),
        ),
      ],
    );
  }

  void tryUpdateGamePath(String newGameDir, Settings settings) {
    newGameDir = newGameDir.isNullOrEmpty ? defaultGamePath().path : newGameDir;

    var dirExists = validateGameFolderPath(newGameDir);

    if (dirExists) {
      ref.read(appSettings.notifier).update((state) {
        var newModDirPath = settings.hasCustomModsDir
            ? settings.modsDir?.toDirectory()
            : generateModsFolderPath(newGameDir.toDirectory());

        return state.copyWith(
            gameDir: Directory(newGameDir).normalize, modsDir: newModDirPath);
      });
    }

    setState(() {
      gamePathExists = dirExists;
    });
  }

  bool validateGameFolderPath(String newGameDir) {
    try {
      if (newGameDir.isEmpty) return false;
      return Directory(newGameDir).existsSync();
    } catch (e) {
      Fimber.w("Error validating game folder path", ex: e);
      return false;
    }
  }
}

class CheckForUpdatesButton extends StatelessWidget {
  const CheckForUpdatesButton({
    super.key,
    required this.ref,
  });

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        ref
            .watch(AppState.selfUpdate.notifier)
            .getLatestRelease()
            .then((release) {
          if (release == null) {
            showSnackBar(
                context: context, content: const Text("No new release found"));
            return;
          } else if (Version.parse(release.tagName, sanitizeInput: true) <=
              Version.parse(Constants.version, sanitizeInput: true)) {
            showSnackBar(
              context: context,
              content: Text(
                  "You are already on the latest version (current: ${Constants.version}, found: ${release.tagName}${release.prerelease ? " (prerelease)" : ""})"),
              action: SnackBarAction(
                label: "I don't believe you",
                backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                onPressed: () {
                  ref
                      .watch(AppState.selfUpdate.notifier)
                      .getLatestRelease()
                      .then((release) {
                    if (release == null) {
                      Fimber.d("No release found");
                      return;
                    }

                    toastification.showCustom(
                      context: context,
                      builder: (context, item) =>
                          SelfUpdateToast(release, item),
                    );
                  });
                },
              ),
            );
            return;
          } else {
            toastification.showCustom(
              context: context,
              builder: (context, item) => SelfUpdateToast(release, item),
            );
          }
        });
      },
      child: const Text('Check for update'),
    );
  }
}
