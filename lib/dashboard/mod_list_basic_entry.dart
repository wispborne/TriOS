import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/dashboard/mod_summary_widget.dart';
import 'package:trios/dashboard/version_check_icon.dart';
import 'package:trios/dashboard/version_check_text_readout.dart';
import 'package:trios/trios/trios_theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
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

  const ModListBasicEntry({super.key, required this.mod, required this.isEnabled});

  @override
  ConsumerState createState() => _ModListBasicEntryState();
}

class _ModListBasicEntryState extends ConsumerState<ModListBasicEntry> {
  @override
  Widget build(BuildContext context) {
    var versionCheck = ref.watch(versionCheckResults).valueOrNull;
    final modVariant = widget.mod;

    final modInfo = modVariant.modInfo;
    final localVersionCheck = modVariant.versionCheckerInfo;
    final remoteVersionCheck = versionCheck?[modVariant.smolId];
    final versionCheckComparison = compareLocalAndRemoteVersions(localVersionCheck, remoteVersionCheck);
    final compatWithGame = compareGameVersions(modInfo.gameVersion, ref.read(AppState.starsectorVersion).value);
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

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: InkWell(
            child: SizedBox(
              height: 26,
              child: CheckboxWithLabel(
                labelWidget: Row(
                  children: [
                    Expanded(
                      child: infoTooltip(
                          child: Text("${modInfo.name} ${modInfo.version}",
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              maxLines: 1,
                              style: theme.textTheme.labelLarge?.copyWith(color: compatTextColor))),
                    ),
                    MovingTooltipWidget(
                      tooltipWidget: SizedBox(
                        width: 500,
                        child: TooltipFrame(
                            child: VersionCheckTextReadout(
                                versionCheckComparison, localVersionCheck, remoteVersionCheck, true)),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (remoteVersionCheck?.remoteVersion != null) {
                            downloadUpdateViaBrowser(remoteVersionCheck!.remoteVersion!);
                          }
                        },
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
                onChanged: (_) {
                  if (false) {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: const Text("Nope"),
                              content: const Text("This feature is not yet implemented."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Close"),
                                ),
                              ],
                            ));
                    return;
                  }
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
                                  ref.read(AppState.modVariants).value ?? [], ref.read(AppState.enabledMods).value!)
                            ))
                        .toList();

                    // Check if any dependencies are completely missing
                    final missingDependencies = dependencyCheck.where((element) => element.satisfication is Missing);
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
                    final disabledDependencies = dependencyCheck.where((element) => element.satisfication is Disabled);
                    if (disabledDependencies.isNotEmpty) {
                      showSnackBar(
                          context: context,
                          type: SnackBarType.error,
                          content: Text(
                              "'${modInfo.name}' has disabled dependency/s '${disabledDependencies.joinToString(transform: (it) => it.dependency.name ?? it.dependency.id ?? "<unknown>")}'."));
                      return;
                    }
                  }

                  var modsFolder = ref.read(appSettings.select((value) => value.modsDir));
                  if (modsFolder == null) return;

                  if (isCurrentlyEnabled) {
                    disableMod(modInfo.id, modsFolder, ref);
                  } else {
                    enableMod(modInfo.id, modsFolder, ref);
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