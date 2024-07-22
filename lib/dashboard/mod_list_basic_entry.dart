import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/dashboard/mod_summary_widget.dart';
import 'package:trios/dashboard/version_check_icon.dart';
import 'package:trios/dashboard/version_check_text_readout.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/tooltip_frame.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../mod_manager/version_checker.dart';
import '../models/mod.dart';
import '../trios/app_state.dart';
import '../trios/download_manager/download_manager.dart';
import '../trios/settings/settings.dart';
import 'changelogs.dart';

/// Displays just the mods specified.
class ModListBasicEntry extends ConsumerStatefulWidget {
  final Mod mod;
  final bool isEnabled;

  const ModListBasicEntry(
      {super.key, required this.mod, required this.isEnabled});

  @override
  ConsumerState createState() => _ModListBasicEntryState();

  static Widget buildVersionCheckTextReadout(
      String? changelogUrl,
      int? versionCheckComparison,
      VersionCheckerInfo? localVersionCheck,
      VersionCheckResult? remoteVersionCheck) {
    return SizedBox(
        width: changelogUrl.isNotNullOrEmpty() ? 800 : 400,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (changelogUrl.isNotNullOrEmpty())
              SizedBox(
                width: 400,
                height: 400,
                child: TooltipFrame(
                  child: Changelogs(
                    localVersionCheck,
                    remoteVersionCheck,
                  ),
                ),
              ),
            Expanded(
              child: TooltipFrame(
                child: VersionCheckTextReadout(versionCheckComparison,
                    localVersionCheck, remoteVersionCheck, true),
              ),
            ),
          ],
        ));
  }

  static IntrinsicHeight changeAndVersionCheckAlertDialogContent(
      String? changelogUrl,
      VersionCheckerInfo? localVersionCheck,
      VersionCheckResult? remoteVersionCheck,
      int? versionCheckComparison) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (changelogUrl.isNotNullOrEmpty())
            SingleChildScrollView(
              child: SizedBox(
                width: 500,
                height: 500,
                child: Changelogs(
                  localVersionCheck,
                  remoteVersionCheck,
                ),
              ),
            ),
          if (changelogUrl.isNotNullOrEmpty())
            const Padding(
              padding: EdgeInsets.all(8),
              child: VerticalDivider(),
            ),
          Expanded(
            child: SelectionArea(
              child: VersionCheckTextReadout(versionCheckComparison,
                  localVersionCheck, remoteVersionCheck, true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModListBasicEntryState extends ConsumerState<ModListBasicEntry> {
  @override
  Widget build(BuildContext context) {
    var versionCheck = ref.watch(AppState.versionCheckResults).valueOrNull;
    final mod = widget.mod;
    final modVariant =
        mod.findFirstEnabledOrHighestVersion ?? mod.modVariants.first;
    final highestModVariant = mod.findHighestVersion ?? modVariant;

    final gameVersion = ref.watch(AppState.starsectorVersion).value;
    final modInfo = modVariant.modInfo;
    final localVersionCheck = highestModVariant.versionCheckerInfo;
    final remoteVersionCheck = versionCheck?[highestModVariant.smolId];
    final versionCheckComparison =
        compareLocalAndRemoteVersions(localVersionCheck, remoteVersionCheck);
    final compatWithGame =
        compareGameVersions(modInfo.gameVersion, gameVersion);
    final theme = Theme.of(context);
    final compatTextColor = compatWithGame.getGameCompatibilityColor();
    final changelogUrl =
        Changelogs.getChangelogUrl(localVersionCheck, remoteVersionCheck);

    infoTooltip({required Widget child}) => MovingTooltipWidget(
        position: TooltipPosition.topLeft,
        tooltipWidget: SizedBox(
          width: 400,
          child: TooltipFrame(
            child: ModSummaryWidget(
              modVariant: modVariant,
              compatWithGame: compatWithGame,
              compatTextColor: compatTextColor,
            ),
          ),
        ),
        child: child);

    const rowHeight = 25.0;

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: InkWell(
            child: SizedBox(
              height: rowHeight,
              child: CheckboxWithLabel(
                labelWidget: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: MovingTooltipWidget(
                        position: TooltipPosition.topLeft,
                        tooltipWidget: SizedBox(
                          width: 400,
                          child: TooltipFrame(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Text(
                                      "Tip: Add a LunaSettings icon or add an icon.png file to the mod folder to get an icon like this!",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                              fontStyle: FontStyle.italic)),
                                ),
                                const Divider(),
                                ModSummaryWidget(
                                  modVariant: modVariant,
                                  compatWithGame: compatWithGame,
                                  compatTextColor: compatTextColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        child: SizedBox(
                          height: rowHeight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: modVariant.iconFilePath != null
                                ? Image.file(
                                    (modVariant.iconFilePath ?? "").toFile(),
                                    isAntiAlias: true,
                                  )
                                : Container(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: infoTooltip(
                          child: Text(
                              "${modInfo.name} ${modInfo.version ?? ""}",
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              maxLines: 1,
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(color: compatTextColor))),
                    ),
                    MovingTooltipWidget(
                      position: TooltipPosition.topLeft,
                      tooltipWidget:
                          ModListBasicEntry.buildVersionCheckTextReadout(
                              changelogUrl,
                              versionCheckComparison,
                              localVersionCheck,
                              remoteVersionCheck),
                      child: InkWell(
                        onTap: () {
                          if (remoteVersionCheck?.remoteVersion != null &&
                              compareLocalAndRemoteVersions(
                                      localVersionCheck, remoteVersionCheck) ==
                                  -1) {
                            downloadUpdateViaBrowser(
                                remoteVersionCheck!.remoteVersion!,
                                ref,
                                context,
                                activateVariantOnComplete: true,
                                modInfo: modInfo);
                          } else {
                            showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                    content: ModListBasicEntry
                                        .changeAndVersionCheckAlertDialogContent(
                                            changelogUrl,
                                            localVersionCheck,
                                            remoteVersionCheck,
                                            versionCheckComparison)));
                          }
                        },
                        onSecondaryTap: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                content: ModListBasicEntry
                                    .changeAndVersionCheckAlertDialogContent(
                                        changelogUrl,
                                        localVersionCheck,
                                        remoteVersionCheck,
                                        versionCheckComparison))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: VersionCheckIcon(
                              localVersionCheck: localVersionCheck,
                              remoteVersionCheck: remoteVersionCheck,
                              versionCheckComparison: versionCheckComparison,
                              theme: theme),
                        ),
                      ),
                    ),
                  ],
                ),
                checkWrapper: (child) => infoTooltip(child: child),
                textPadding: const EdgeInsets.only(left: 0, bottom: 2),
                value: widget.isEnabled,
                expand: true,
                onChanged: (_) async {
                  // if (enabledModIds == null) return;
                  var isCurrentlyEnabled = widget.isEnabled;

                  // We can disable mods without checking compatibility, but we can't enable them without checking.
                  if (!isCurrentlyEnabled) {
                    // Check game version compatibility
                    final compatResult = compatWithGame;
                    if (compatResult == GameCompatibility.incompatible) {
                      showSnackBar(
                        context: context,
                        type: SnackBarType.error,
                        content: Text(
                            "'${modInfo.name}' requires game version ${modInfo.gameVersion} but you have $gameVersion"),
                      );
                      return;
                    }

                    final allMods = ref.read(AppState.modVariants).value ?? [];
                    final enabledMods =
                        ref.read(AppState.enabledModsFile).value!;
                    // Check dependencies
                    final dependencyCheck = modInfo.checkDependencies(
                        allMods, enabledMods, gameVersion);

                    // Check if any dependencies are completely missing
                    final missingDependencies = dependencyCheck
                        .where((element) => element.satisfiedAmount is Missing);
                    if (missingDependencies.isNotEmpty) {
                      showSnackBar(
                          context: context,
                          type: SnackBarType.error,
                          content: Text(
                            "'${modInfo.name}' is missing '${missingDependencies.joinToString(transform: (it) => it.dependency.name ?? it.dependency.id ?? "<unknown>")}'.",
                          ));
                      return;
                    }
                  }

                  var modsFolder =
                      ref.read(appSettings.select((value) => value.modsDir));
                  if (modsFolder == null) return;

                  try {
                    if (isCurrentlyEnabled) {
                      // Disable
                      ref
                          .read(AppState.modVariants.notifier)
                          .changeActiveModVariant(mod, null);
                    } else {
                      // Enable highest version
                      ref
                          .read(AppState.modVariants.notifier)
                          .changeActiveModVariant(mod, mod.findHighestVersion);
                    }
                  } catch (e) {
                    showSnackBar(
                        context: context,
                        type: SnackBarType.error,
                        content: Text(e.toString()));
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
