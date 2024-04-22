import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/dashboard/mod_summary_widget.dart';
import 'package:trios/dashboard/version_check_icon.dart';
import 'package:trios/dashboard/version_check_text_readout.dart';
import 'package:trios/themes/trios_manager.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/disable_if_cannot_write_mods.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/tooltip_frame.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../mod_manager/version_checker.dart';
import '../models/mod_variant.dart';
import '../trios/app_state.dart';
import '../trios/download_manager/download_manager.dart';
import '../trios/settings/settings.dart';

/// Displays just the mods specified.
class ModListBasicEntry extends ConsumerStatefulWidget {
  final ModVariant mod;
  final bool isEnabled;

  const ModListBasicEntry(
      {super.key, required this.mod, required this.isEnabled});

  @override
  ConsumerState createState() => _ModListBasicEntryState();
}

class _ModListBasicEntryState extends ConsumerState<ModListBasicEntry> {
  @override
  Widget build(BuildContext context) {
    var versionCheck = ref.watch(AppState.versionCheckResults).valueOrNull;
    final modVariant = widget.mod;

    final modInfo = modVariant.modInfo;
    final localVersionCheck = modVariant.versionCheckerInfo;
    final remoteVersionCheck = versionCheck?[modVariant.smolId];
    final versionCheckComparison =
        compareLocalAndRemoteVersions(localVersionCheck, remoteVersionCheck);
    final compatWithGame = compareGameVersions(
        modInfo.gameVersion, ref.read(AppState.starsectorVersion).value);
    final compatTextColor = switch (compatWithGame) {
      GameCompatibility.incompatible => vanillaErrorColor,
      GameCompatibility.warning => vanillaWarningColor,
      GameCompatibility.compatible => null,
    };
    final theme = Theme.of(context);
    infoTooltip({required Widget child}) => MovingTooltipWidget(
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
                      tooltipWidget: SizedBox(
                        width: 500,
                        child: TooltipFrame(
                            child: VersionCheckTextReadout(
                                versionCheckComparison,
                                localVersionCheck,
                                remoteVersionCheck,
                                true)),
                      ),
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
                                modInfo: modInfo);
                          } else {
                            showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                        content: SelectionArea(
                                      child: VersionCheckTextReadout(
                                          versionCheckComparison,
                                          localVersionCheck,
                                          remoteVersionCheck,
                                          true),
                                    )));
                          }
                        },
                        onSecondaryTap: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                    content: SelectionArea(
                                  child: VersionCheckTextReadout(
                                      versionCheckComparison,
                                      localVersionCheck,
                                      remoteVersionCheck,
                                      true),
                                ))),
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
                padding: 0,
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
                            "'${modInfo.name}' requires game version ${modInfo.gameVersion} but you have ${ref.read(AppState.starsectorVersion).value}"),
                      );
                      return;
                    }

                    // Check dependencies
                    final dependencyCheck = modInfo.dependencies
                        .map((dep) => (
                              dependency: dep,
                              satisfication: dep.isSatisfiedByAny(
                                  ref.read(AppState.modVariants).value ?? [],
                                  ref.read(AppState.enabledMods).value!)
                            ))
                        .toList();

                    // Check if any dependencies are completely missing
                    final missingDependencies = dependencyCheck
                        .where((element) => element.satisfication is Missing);
                    if (missingDependencies.isNotEmpty) {
                      showSnackBar(
                          context: context,
                          type: SnackBarType.error,
                          content: Text(
                            "'${modInfo.name}' is missing '${missingDependencies.joinToString(transform: (it) => it.dependency.name ?? it.dependency.id ?? "<unknown>")}'.",
                          ));
                      return;
                    }

                    // Check if any dependencies are disabled but present and can be enabled
                    final disabledDependencies = dependencyCheck
                        .where((element) => element.satisfication is Disabled);
                    if (disabledDependencies.isNotEmpty) {
                      showSnackBar(
                          context: context,
                          type: SnackBarType.error,
                          content: Text(
                              "'${modInfo.name}' has disabled dependency/s '${disabledDependencies.joinToString(transform: (it) => it.dependency.name ?? it.dependency.id ?? "<unknown>")}'."));
                      return;
                    }
                  }

                  var modsFolder =
                      ref.read(appSettings.select((value) => value.modsDir));
                  if (modsFolder == null) return;

                  try {
                    if (isCurrentlyEnabled) {
                      disableMod(modInfo.id, modsFolder, ref);
                    } else {
                      enableMod(modInfo.id, modsFolder, ref);
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
