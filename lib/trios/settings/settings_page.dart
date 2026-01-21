import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/companion_mod/companion_mod_manager.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/onboarding/onboarding_page.dart';
import 'package:trios/thirdparty/dartx/comparable.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/changelog_viewer.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/game_paths_widget/game_paths_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';
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
  final double pagePadding;

  const SettingsPage({super.key, required this.pagePadding});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _windowScaleTextController = TextEditingController();
  final _scrollController = ScrollController();

  // 1.0 is 100%, 1.25 is 125%
  double newWindowScaleDouble = 1.0;
  bool isInstallingCompanionMod = false;

  @override
  void initState() {
    super.initState();

    newWindowScaleDouble = ref.read(appSettings).windowScaleFactor;
    _windowScaleTextController.text = (newWindowScaleDouble * 100.0)
        .toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const leftTextOptionPadding = 4.0;
    final iconColor = Theme.of(context).iconTheme.color?.withValues(alpha: 0.8);
    return Padding(
      padding: EdgeInsets.only(
        left: widget.pagePadding,
        top: widget.pagePadding,
        right: widget.pagePadding,
      ),
      child: Scrollbar(
        thumbVisibility: true,
        trackVisibility: false,
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: EdgeInsets.only(bottom: widget.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SettingsGroup(
                  name: "Starsector",
                  children: [GamePathsWidget()],
                ),
                SettingsGroup(
                  name: "${Constants.appName} Updates",
                  children: [
                    // CheckboxWithLabel(
                    //   value: ref.watch(appSettings.select(
                    //       (value) => value.shouldAutoUpdateOnLaunch)),
                    //   onChanged: (value) {
                    //     ref.read(appSettings.notifier).update((state) =>
                    //         state.copyWith(
                    //             shouldAutoUpdateOnLaunch: value ?? false));
                    //   },
                    //   label: "Auto-update ${Constants.appName} on launch",
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: MovingTooltipWidget.text(
                        message:
                            "Play with fire."
                            "\n"
                            "\nEnabling this will include Previews when checking for updates."
                            "\nPreviews are *usually* stable, but no guarantees. They contain bugfixes and often add a feature or two that may not be totally finished.",
                        child: CheckboxWithLabel(
                          value: ref.watch(
                            appSettings.select(
                              (value) => value.updateToPrereleases,
                            ),
                          ),
                          onChanged: (value) {
                            ref
                                .read(appSettings.notifier)
                                .update(
                                  (state) => state.copyWith(
                                    updateToPrereleases: value ?? false,
                                  ),
                                );
                          },
                          labelWidget: TextWithIcon(
                            text:
                                "Enable ${Constants.appName} preview releases",
                            trailing: Transform.rotate(
                              angle: 0.8,
                              child: SvgImageIcon(
                                "assets/images/icon-experimental.svg",
                                width: 20,
                                color: iconColor,
                              ),
                            ),
                            // Stack(
                            //   children: [
                            //     Transform.rotate(
                            //       angle: 1.2,
                            //       child: SvgImageIcon(
                            //         "assets/images/icon-experimental.svg",
                            //         width: 24,
                            //         color: iconColor,
                            //       ),
                            //     ),
                            //     Padding(
                            //       padding: const EdgeInsets.only(
                            //         left: 12,
                            //         top: 12,
                            //       ),
                            //       child: Transform.scale(
                            //         scaleX: 0.8,
                            //         scaleY: 1.2,
                            //         child: TriOSAppIcon(
                            //           height: 24,
                            //           color: iconColor,
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CheckForUpdatesButton(ref: ref),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          child: const Text("Show Changelog"),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  content: SizedBox(
                                    width: 600,
                                    height: 1200,
                                    child: TriOSChangelogViewer(
                                      url: Constants.changelogUrl,
                                      lastestVersionToShow:
                                          ref.read(
                                                appSettings.select(
                                                  (value) =>
                                                      value.updateToPrereleases,
                                                ),
                                              ) ==
                                              true
                                          ? null
                                          : Constants.currentVersion,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("Close"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SettingsGroup(
                  name: "Interface",
                  children: [
                    Row(
                      children: [
                        MovingTooltipWidget.text(
                          message:
                              "Change up the colors."
                              "\nNote: only the default theme (StarsectorTriOSTheme) is regularly tested.",
                          child: DropdownMenu(
                            requestFocusOnTap: false,
                            dropdownMenuEntries:
                                (ref
                                            .watch(AppState.themeData)
                                            .value
                                            ?.availableThemes
                                            .entries ??
                                        [])
                                    .map(
                                      (theme) => (
                                        theme.key,
                                        theme,
                                        ref
                                            .read(AppState.themeData.notifier)
                                            .convertToThemeData(theme.value),
                                      ),
                                    )
                                    .map((obj) {
                                      var (key, triosTheme, themeData) = obj;
                                      return DropdownMenuEntry(
                                        value: triosTheme.value,
                                        style: ButtonStyle(
                                          backgroundColor:
                                              WidgetStateProperty.all(
                                                themeData
                                                    .scaffoldBackgroundColor,
                                              ),
                                        ),
                                        labelWidget: Row(
                                          children: [
                                            SizedBox(
                                              width: 40,
                                              height: 20,
                                              child: Container(
                                                color: themeData
                                                    .colorScheme
                                                    .primary,
                                                child: const SizedBox.shrink(),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Container(
                                                color: themeData
                                                    .colorScheme
                                                    .secondary,
                                                child: const SizedBox.shrink(),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              triosTheme.key,
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    color: themeData
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        label: triosTheme.key,
                                      );
                                    })
                                    .distinctBy((e) => e.value)
                                    .toList(),
                            onSelected: (TriOSTheme? theme) => ref
                                .read(AppState.themeData.notifier)
                                .switchThemes(theme!),
                            initialSelection: ref
                                .watch(AppState.themeData.notifier)
                                .currentTheme,
                            // borderRadius: BorderRadius.all(
                            //     Radius.circular(ThemeManager.cornerRadius)),
                            // padding: const EdgeInsets.symmetric(horizontal: 0),
                          ),
                        ),
                        MovingTooltipWidget.text(
                          message: "I'm feeling lucky",
                          child: IconButton(
                            onPressed: () => ref
                                .read(AppState.themeData.notifier)
                                .switchThemes(
                                  ref
                                      .read(AppState.themeData.notifier)
                                      .allThemes
                                      .values
                                      .random(),
                                ),
                            icon: SvgImageIcon(
                              "assets/images/icon-dice.svg",
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final showForceUpdateWarning = ref.watch(
                          appSettings.select((s) => s.showForceUpdateWarning),
                        );
                        return MovingTooltipWidget.text(
                          message:
                              "Whether to show the warning when forcing a mod to run on the current game version.",
                          child: CheckboxWithLabel(
                            value: showForceUpdateWarning,
                            onChanged: (bool? value) => ref
                                .read(appSettings.notifier)
                                .update(
                                  (state) => state.copyWith(
                                    showForceUpdateWarning: value ?? true,
                                  ),
                                ),
                            label: "Show 'Force Update' Warning",
                          ),
                        );
                      },
                    ),
                    Builder(
                      builder: (context) {
                        final showDonationButton = ref.watch(
                          appSettings.select((s) => s.showDonationButton),
                        );
                        return MovingTooltipWidget.text(
                          message: "No solicitors!",
                          child: CheckboxWithLabel(
                            value: showDonationButton,
                            onChanged: (bool? value) => ref
                                .read(appSettings.notifier)
                                .update(
                                  (state) => state.copyWith(
                                    showDonationButton: value ?? true,
                                  ),
                                ),
                            label: "Show Donation Button",
                          ),
                        );
                      },
                    ),
                    Builder(
                      builder: (context) {
                        final showReportBugButton = ref.watch(
                          appSettings.select((s) => s.showReportBugButton),
                        );
                        return MovingTooltipWidget.text(
                          message: "All right then, keep your secrets.",
                          child: CheckboxWithLabel(
                            value: showReportBugButton,
                            onChanged: (bool? value) => ref
                                .read(appSettings.notifier)
                                .update(
                                  (state) => state.copyWith(
                                    showReportBugButton: value ?? true,
                                  ),
                                ),
                            label: "Show Report Bug Button",
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Builder(
                  builder: (context) {
                    final lastNVersionsSetting = ref.watch(
                      appSettings.select((s) => s.keepLastNVersions),
                    );
                    final enableMultipleVersions = lastNVersionsSetting != 1;
                    return SettingsGroup(
                      name: "Mod Organization",
                      children: [
                        MovingTooltipWidget.text(
                          message:
                              "If enabled, TriOS will always add the version number to the folder name when installing a mod."
                              "\nFor example; LazyLib-1.8b, LazyLib-1.8, LazyLib-1.7."
                              "\n\nIf disabled, the latest mod won't change folder name, even when you update the mod."
                              "\nOlder versions of a mod will still include the version number in order to tell them apart."
                              "\nFor example; LazyLib, LazyLib-1.8, LazyLib-1.7.",
                          child: CheckboxWithLabel(
                            value:
                                ref.watch(
                                  appSettings.select(
                                    (s) => s.folderNamingSetting,
                                  ),
                                ) ==
                                FolderNamingSetting.allFoldersVersioned,
                            onChanged: (value) {
                              ref
                                  .read(appSettings.notifier)
                                  .update(
                                    (state) => state.copyWith(
                                      folderNamingSetting: value == true
                                          ? FolderNamingSetting
                                                .allFoldersVersioned
                                          : FolderNamingSetting
                                                .doNotChangeNameForHighestVersion,
                                    ),
                                  );
                            },
                            label: "Rename all mod folders",
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: MovingTooltipWidget.text(
                            message:
                                "Manual mode. TriOS will not rename folders."
                                "\nThis may result in TriOS overwriting mods when updating or installing new versions, if the folder already exists."
                                "\nFor example, if you have folder `LazyLib` and install a new version where the folder name is also `LazyLib`, the older one will be overwritten."
                                "\n\nTODO: clean up this UI and use a dropdown or something :)",
                            warningLevel: TooltipWarningLevel.error,
                            child: CheckboxWithLabel(
                              value:
                                  ref.watch(
                                    appSettings.select(
                                      (s) => s.folderNamingSetting,
                                    ),
                                  ) ==
                                  FolderNamingSetting.doNotChangeNamesEver,
                              onChanged: (value) {
                                ref
                                    .read(appSettings.notifier)
                                    .update(
                                      (state) => state.copyWith(
                                        folderNamingSetting: value == true
                                            ? FolderNamingSetting
                                                  .doNotChangeNamesEver
                                            : FolderNamingSetting
                                                  .doNotChangeNameForHighestVersion,
                                      ),
                                    );
                              },
                              labelWidget: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Manual folder naming"),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.warning),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        MovingTooltipWidget.text(
                          message:
                              "When checked, updating an enabled mod switches to the new version.",
                          child: CheckboxWithLabel(
                            value:
                                ref.watch(
                                  appSettings.select(
                                    (s) => s.modUpdateBehavior,
                                  ),
                                ) ==
                                ModUpdateBehavior
                                    .switchToNewVersionIfWasEnabled,
                            onChanged: (newValue) {
                              setState(() {
                                ref
                                    .read(appSettings.notifier)
                                    .update(
                                      (s) => s.copyWith(
                                        modUpdateBehavior: newValue == true
                                            ? ModUpdateBehavior
                                                  .switchToNewVersionIfWasEnabled
                                            : ModUpdateBehavior.doNotChange,
                                      ),
                                    );
                              });
                            },
                            labelWidget: const Text("Auto-swap on mod update"),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SettingsGroup.subsection(
                          name: "Old mod versions",
                          children: [
                            MovingTooltipWidget.text(
                              message:
                                  "Installing or updating a mod will replace the previous version of it.",
                              child: IntrinsicWidth(
                                child: RadioListTile(
                                  title: const Text(
                                    "Keep only one mod version",
                                  ),
                                  value: false,
                                  contentPadding: const EdgeInsets.all(0),
                                  groupValue: enableMultipleVersions,
                                  onChanged: (value) => ref
                                      .read(appSettings.notifier)
                                      .update(
                                        (state) => state.copyWith(
                                          keepLastNVersions: 1,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IntrinsicWidth(
                                  child: MovingTooltipWidget.text(
                                    message: lastNVersionsSetting == null
                                        ? "TriOS will never automatically remove mod versions."
                                        : "Installing or updating a mod will remove all but the last $lastNVersionsSetting highest versions.",
                                    child: RadioListTile(
                                      title: const Text(
                                        "Keep all mod versions",
                                      ),
                                      value: true,
                                      contentPadding: const EdgeInsets.all(0),
                                      groupValue: enableMultipleVersions,
                                      onChanged: (value) => ref
                                          .read(appSettings.notifier)
                                          .update(
                                            (state) => state.copyWith(
                                              keepLastNVersions:
                                                  (value ?? false) ? null : 1,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                Disable(
                                  isEnabled: enableMultipleVersions,
                                  child: Row(
                                    children: [
                                      const Text(" (up to "),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: DropdownButton<int>(
                                          value: lastNVersionsSetting,
                                          items: [
                                            for (int i = 1; i <= 10; i++)
                                              DropdownMenuItem(
                                                value: i,
                                                child: Text(" $i"),
                                              ),
                                            const DropdownMenuItem(
                                              value: null,
                                              child: Text(" ∞"),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            ref
                                                .read(appSettings.notifier)
                                                .update(
                                                  (state) => state.copyWith(
                                                    keepLastNVersions: value,
                                                  ),
                                                );
                                          },
                                          isDense: true,
                                        ),
                                      ),
                                      const Text(")"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Padding(
                            //   padding: const EdgeInsets.only(
                            //       left: leftTextOptionPadding, top: 8),
                            //   child: Row(
                            //     children: [
                            //       MovingTooltipWidget.text(
                            //         message:
                            //             "If you have multiple versions of a mod, this will keep the last N versions of each mod."
                            //             "\n\nOlder versions will be automatically deleted when a new one is installed.",
                            //         child: Row(
                            //           children: [
                            //             const Text("Keep last "),
                            //             Padding(
                            //               padding: const EdgeInsets.symmetric(
                            //                   horizontal: 8),
                            //               child: DropdownButton<int>(
                            //                 value: lastNVersionsSetting,
                            //                 items: [
                            //                   for (int i = 1; i <= 10; i++)
                            //                     DropdownMenuItem(
                            //                         value: i, child: Text(" $i")),
                            //                   const DropdownMenuItem(
                            //                       value: null, child: Text(" ∞")),
                            //                 ],
                            //                 onChanged: (value) {
                            //                   ref.read(appSettings.notifier).update(
                            //                         (state) => state.copyWith(
                            //                             keepLastNVersions:
                            //                                 value == -1
                            //                                     ? null
                            //                                     : value),
                            //                       );
                            //                 },
                            //                 isDense: true,
                            //                 // decoration: const InputDecoration(
                            //                 //   border: OutlineInputBorder(),
                            //                 // ),
                            //               ),
                            //             ),
                            //             Text(
                            //                 " version${lastNVersionsSetting == 1 ? "" : "s"} of each mod"),
                            //           ],
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            Disable(
                              isEnabled: lastNVersionsSetting != null,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: MovingTooltipWidget.text(
                                  message:
                                      "${switch (lastNVersionsSetting) {
                                        null => "",
                                        1 => "Remove all but the newest version of each mod.",
                                        _ => "Remove all but the newest $lastNVersionsSetting versions of each mod.",
                                      }}\nPrompts for confirmation before deleting anything.",
                                  child: ElevatedButton.icon(
                                    icon: const SvgImageIcon(
                                      "assets/images/icon-shredder.svg",
                                    ),
                                    onPressed: () async {
                                      final modsThatWouldBeRemoved = await ref
                                          .read(modManager.notifier)
                                          .cleanUpAllModVariantsBasedOnRetainSetting(
                                            // dryRun: true,
                                          );

                                      if (!mounted) return;
                                      showDeleteModFoldersConfirmationDialog(
                                        modsThatWouldBeRemoved,
                                        // .map((mod) => mod)
                                        // .toList(),
                                        context,
                                        ref,
                                      );
                                      return;
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text("Delete mods"),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                children: [
                                                  Text(
                                                    "Are you sure you want to delete ${modsThatWouldBeRemoved.length} mods?",
                                                  ),
                                                  const SizedBox(height: 8),
                                                  if (modsThatWouldBeRemoved
                                                      .isNotEmpty)
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [],
                                                      // modsThatWouldBeRemoved
                                                      //     .map(
                                                      //       (mod) => Text(
                                                      //         "- ${mod.nameOrId} ${mod.version}",
                                                      //       ),
                                                      //     )
                                                      //     .toList(),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text(
                                                  "Cancel",
                                                  style: theme
                                                      .textTheme
                                                      .labelLarge,
                                                ),
                                              ),
                                              TextButton.icon(
                                                onPressed: () async {
                                                  Navigator.of(context).pop();
                                                  await ref
                                                      .read(modManager.notifier)
                                                      .cleanUpAllModVariantsBasedOnRetainSetting(
                                                        dryRun: false,
                                                      );
                                                  ref.read(AppState.modVariants.notifier).reloadModVariants();
                                                },
                                                icon: Icon(Icons.delete),
                                                label: const Text("Delete"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    label: const Text("Clean up..."),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                SettingsGroup(
                  name: "Companion Mod",
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: leftTextOptionPadding,
                      ),
                      child: Builder(
                        builder: (BuildContext context) {
                          final mods = ref.watch(AppState.mods);
                          final companionMod = mods.firstOrNullWhere(
                            (m) => m.id == Constants.companionModId,
                          );
                          final isCompanionModEnabled = mods.any(
                            (m) =>
                                m.id == Constants.companionModId &&
                                m.hasEnabledVariant,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "The ${Constants.appName} Companion Mod is required to replace portraits without touching the actual mods (see Portraits tab)."
                                "\nIt does nothing else and has effectively no impact on loading or performance.",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.textTheme.labelLarge?.color
                                      ?.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextWithIcon(
                                text: companionMod == null
                                    ? "The Companion Mod is not installed."
                                    : isCompanionModEnabled
                                    ? "The Companion Mod is set up correctly."
                                    : "The Companion Mod is installed but not enabled.",
                                trailing: companionMod == null
                                    ? const Icon(Icons.error)
                                    : isCompanionModEnabled
                                    ? const Icon(Icons.check)
                                    : const Icon(Icons.warning),
                                style: theme.textTheme.labelLarge,
                              ),

                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  MovingTooltipWidget.text(
                                    message:
                                        "If the Companion Mod already exists, it'll be replaced with a fresh version."
                                        "\nPortrait replacements that show in ${Constants.appName} will NOT be lost.",
                                    child: ElevatedButton.icon(
                                      icon: Icon(Icons.install_desktop),
                                      label: Text(
                                        companionMod != null
                                            ? "Reinstall Companion Mod"
                                            : "Install Companion Mod",
                                      ),
                                      onPressed: () async {
                                        setState(() {
                                          isInstallingCompanionMod = true;
                                        });

                                        try {
                                          final companionModManager = ref.read(
                                            companionModManagerProvider,
                                          );
                                          await companionModManager
                                              .fullySetUpCompanionMod();
                                        } catch (e) {
                                          showSnackBar(
                                            context: ref.read(
                                              AppState.appContext,
                                            )!,
                                            content: Text(e.toString()),
                                          );
                                        } finally {
                                          setState(() {
                                            isInstallingCompanionMod = false;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  if (isInstallingCompanionMod)
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: const CircularProgressIndicator(),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Disable(
                                isEnabled: companionMod != null,
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.folder_open),
                                  label: const Text(
                                    "Open Companion Mod Folder",
                                  ),
                                  onPressed: () async {
                                    try {
                                      companionMod
                                          ?.findFirstEnabledOrHighestVersion
                                          ?.modFolder
                                          .openInExplorer();
                                    } catch (e) {
                                      showSnackBar(
                                        context: ref.read(AppState.appContext)!,
                                        content: Text(e.toString()),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SettingsGroup(
                  name: "Misc",
                  children: [
                    // Slider for number of seconds between mod info update checks (secondsBetweenModFolderChecks in mod_manager_logic.dart).
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: MovingTooltipWidget.text(
                        message:
                            "This sets how often we check if there are new or changed mods in your folder.\nA shorter time means more frequent checks.\nDoes not scan when ${Constants.appName} is in the background.",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: leftTextOptionPadding,
                              ),
                              child: Text(
                                "Rescan mod folder every: ${ref.watch(appSettings.select((value) => value.secondsBetweenModFolderChecks))} seconds",
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            Slider(
                              value: ref
                                  .watch(
                                    appSettings.select(
                                      (value) =>
                                          value.secondsBetweenModFolderChecks,
                                    ),
                                  )
                                  .toDouble()
                                  .clamp(1, 30),
                              min: 1,
                              max: 30,
                              divisions: 29,
                              label:
                                  "${ref.watch(appSettings.select((value) => value.secondsBetweenModFolderChecks))}",
                              onChanged: (value) {
                                ref
                                    .read(appSettings.notifier)
                                    .update(
                                      (state) => state.copyWith(
                                        secondsBetweenModFolderChecks: value
                                            .toInt(),
                                      ),
                                    );
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
                        left: leftTextOptionPadding,
                        top: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: MovingTooltipWidget.text(
                          message:
                              "How long notifications (e.g. 'Downloading') should appear for.",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Notification duration: ${ref.watch(appSettings.select((value) => value.toastDurationSeconds))} seconds",
                                style: theme.textTheme.bodyLarge,
                              ),
                              Slider(
                                value: ref
                                    .watch(
                                      appSettings.select(
                                        (value) => value.toastDurationSeconds,
                                      ),
                                    )
                                    .toDouble()
                                    .clamp(1, 45),
                                min: 1,
                                max: 45,
                                divisions: 45,
                                label:
                                    "${ref.watch(appSettings.select((value) => value.toastDurationSeconds))}",
                                onChanged: (value) {
                                  ref
                                      .read(appSettings.notifier)
                                      .update(
                                        (state) => state.copyWith(
                                          toastDurationSeconds: value.toInt(),
                                        ),
                                      );
                                },
                                inactiveColor: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: leftTextOptionPadding,
                        top: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: MovingTooltipWidget.text(
                          message:
                              "Affects how quickly Version Checker searches. If version checker is showing timeout errors, reduce this number.",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Max HTTP requests at once: ${ref.watch(appSettings.select((value) => value.maxHttpRequestsAtOnce))}",
                                style: theme.textTheme.bodyLarge,
                              ),
                              Slider(
                                value: ref
                                    .watch(
                                      appSettings.select(
                                        (value) => value.maxHttpRequestsAtOnce,
                                      ),
                                    )
                                    .toDouble()
                                    .clamp(1, 100),
                                min: 1,
                                max: 100,
                                divisions: 10,
                                label:
                                    "${ref.watch(appSettings.select((value) => value.maxHttpRequestsAtOnce))}",
                                onChanged: (value) {
                                  ref
                                      .read(appSettings.notifier)
                                      .update(
                                        (state) => state.copyWith(
                                          maxHttpRequestsAtOnce: value.toInt(),
                                        ),
                                      );
                                },
                                inactiveColor: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: MovingTooltipWidget.text(
                        message: "Opens the onboarding page again.",
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const OnboardingCarousel(),
                              barrierDismissible: false,
                            );
                          },
                          child: const Text('Open Onboarding'),
                        ),
                      ),
                    ),
                    // Checkbox for enabling crash reporting
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MovingTooltipWidget.text(
                            message:
                                "This allows ${Constants.appName} to send crash/error reports to get fixed.\nNo personal/identifiable data is sent.\nWill soft-restart ${Constants.appName} to apply.",
                            child: CheckboxWithLabel(
                              value: ref.watch(
                                appSettings.select(
                                  (value) => value.allowCrashReporting ?? false,
                                ),
                              ),
                              onChanged: (value) async {
                                if (!context.mounted) return;
                                showAlertDialog(
                                  context,
                                  title: "Restart Required",
                                  content:
                                      "${Constants.appName} must be restarted to apply this change.",
                                  actions: [
                                    TextButton(
                                      child: const Text('Restart Now'),
                                      onPressed: () async {
                                        await ref
                                            .read(appSettings.notifier)
                                            .update(
                                              (state) => state.copyWith(
                                                allowCrashReporting:
                                                    value ?? false,
                                              ),
                                            );
                                        // Must restart TriOS to toggle. Soft restart doesn't properly initialize SentryWidget and Report Bug button doesn't work.
                                        restartApplication();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('Nevermind'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                              label: "Allow error reporting",
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info),
                            onPressed: () {
                              showAlertDialog(
                                context,
                                title: "Error Reporting",
                                content:
                                    "If allowed, ${Constants.appName} uses Sentry.io to collect error reports."
                                    "\nIf not allowed, the Sentry SDK will be completely disabled; it will not be initialized on startup, "
                                    "which is why the soft restart is required to toggle this setting and why 'Report A Bug' is not available if it is disabled."
                                    "\n"
                                    "\nIf error reporting is enabled, care is taken to avoid sending any personal/identifiable data such as IP addresses, usernames (even in file paths), device names, location, etc."
                                    "\nMod names, device info (OS, CPU count, RAM, etc) is sent.",
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: MovingTooltipWidget.text(
                        message:
                            "Whether to check for mod dependencies and prevent launching if they aren't met."
                            "\nDisable if ${Constants.appName} is getting them wrong, or you'd just like to use vanilla dependency check behavior.",
                        child: CheckboxWithLabel(
                          value: ref.watch(
                            appSettings.select(
                              (value) => value.enableLauncherPrecheck,
                            ),
                          ),
                          onChanged: (value) {
                            ref
                                .read(appSettings.notifier)
                                .update(
                                  (state) => state.copyWith(
                                    enableLauncherPrecheck: value ?? false,
                                  ),
                                );
                          },
                          label: "Enable Launch Precheck",
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          MovingTooltipWidget.text(
                            message:
                                "Whether to check if the game is running and lock parts of ${Constants.appName}."
                                "\nDisable if ${Constants.appName} is detecting incorrectly.",
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CheckboxWithLabel(
                                  value: ref.watch(
                                    appSettings.select(
                                      (value) => value.checkIfGameIsRunning,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    ref
                                        .read(appSettings.notifier)
                                        .update(
                                          (state) => state.copyWith(
                                            checkIfGameIsRunning:
                                                value ?? false,
                                          ),
                                        );
                                  },
                                  label: "Check if game is running",
                                ),
                                if (ref
                                        .watch(AppState.gameRunningCheckError)
                                        .value
                                        ?.isNotEmpty ==
                                    true)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 48),
                                    child: Text(
                                      "Error checking if game is running!"
                                      "\n${ref.watch(AppState.gameRunningCheckError).value?.join("\n")}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // IconButton(
                          //   icon: const Icon(Icons.info),
                          //   onPressed: () {
                          //     showAlertDialog(
                          //       context,
                          //       title: "Check if game is running",
                          //       content:
                          //       "",
                          //     );
                          //   },
                          // ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MovingTooltipWidget.text(
                            message:
                                "Makes the UI larger or smaller."
                                "\nMin 25%, max 300%.",
                            child: SizedBox(
                              width: 90,
                              child: TextField(
                                controller: _windowScaleTextController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  labelText: "${Constants.appName} scale",
                                  hintStyle: Theme.of(
                                    context,
                                  ).textTheme.labelLarge,
                                  labelStyle: Theme.of(
                                    context,
                                  ).textTheme.labelLarge,
                                ),
                                onChanged: (newPath) {
                                  final newScale =
                                      double.parse(newPath) / 100.0;
                                  newWindowScaleDouble = newScale;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text("%"),
                          const SizedBox(width: 8),
                          MovingTooltipWidget.text(
                            warningLevel: TooltipWarningLevel.warning,
                            message:
                                "Make small changes at a time."
                                "\nTri-Tachyon is not responsible if you set it to 300% and it's so big you can't get to the setting to fix it.",
                            child: ElevatedButton(
                              onPressed: () {
                                if (newWindowScaleDouble >= 0.50 &&
                                    newWindowScaleDouble <= 3.0) {
                                  Fimber.i(
                                    "Setting window scale to $newWindowScaleDouble",
                                  );
                                  ref.read(appSettings.notifier).update((
                                    state,
                                  ) {
                                    return state.copyWith(
                                      windowScaleFactor: newWindowScaleDouble,
                                    );
                                  });
                                }
                                // RestartableApp.restartApp(context);
                              },
                              child: const Text("Apply UI Scaling"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (Platform.isLinux)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: MovingTooltipWidget.text(
                          message:
                              "The Flutter framework (what ${Constants.appName} uses) has a bug that causes freezes related to text fields on some Linux distros."
                              "\nDisabling accessibility semantics fixes those freezes."
                              "\nYou may need to fully restart ${Constants.appName} to apply the changes.",
                          child: CheckboxWithLabel(
                            value: ref.watch(
                              appSettings.select(
                                (value) =>
                                    value.enableAccessibilitySemanticsOnLinux ==
                                    true,
                              ),
                            ),
                            onChanged: (value) {
                              ref
                                  .read(appSettings.notifier)
                                  .update(
                                    (state) => state.copyWith(
                                      enableAccessibilitySemanticsOnLinux:
                                          value,
                                    ),
                                  );
                              RestartableApp.softRestartApp(context);
                            },
                            label:
                                "Enable Accessibility Semantics (may cause freezes)",
                          ),
                        ),
                      ),
                  ],
                ),
                // Debugging line here
                SizedBox.fromSize(size: const Size.fromHeight(20)),
                Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: TriOSExpansionTile(
                    title: const Text("Debugging"),
                    subtitle: const Text(
                      "Junk drawer of developer actions and info",
                    ),
                    leading: Icon(
                      Icons.bug_report,
                      color: Theme.of(
                        context,
                      ).iconTheme.color?.withOpacity(0.7),
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: SettingsDebugSection(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CheckForUpdatesButton extends StatelessWidget {
  const CheckForUpdatesButton({super.key, required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        ref.watch(AppState.selfUpdate.notifier).getLatestRelease().then((
          release,
        ) {
          if (release == null) {
            showSnackBar(
              context: context,
              content: const Text("No new release found"),
            );
            return;
          } else if (Version.parse(release.tagName, sanitizeInput: true) <=
              Version.parse(Constants.version, sanitizeInput: true)) {
            showSnackBar(
              context: context,
              content: Text(
                "You are already on the latest version (current: ${Constants.version}, found: ${release.tagName}${release.prerelease ? " (prerelease)" : ""})",
              ),
              action: SnackBarAction(
                label: "I don't believe you (show update prompt)",
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
