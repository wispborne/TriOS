import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/dashboard/mod_summary_widget.dart';
import 'package:trios/dashboard/version_check_icon.dart';
import 'package:trios/dashboard/version_check_text_readout.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/tooltip_frame.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../mod_manager/version_checker.dart';
import '../models/mod.dart';
import '../trios/app_state.dart';
import '../trios/download_manager/download_manager.dart';
import 'changelogs.dart';

/// Displays just the mods specified.
class ModListBasicEntry extends ConsumerStatefulWidget {
  final Mod mod;
  final bool isDisabled;

  const ModListBasicEntry({
    super.key,
    required this.mod,
    this.isDisabled = false,
  });

  @override
  ConsumerState createState() => _ModListBasicEntryState();

  static Widget buildVersionCheckTextReadoutForTooltip(
    Mod mod,
    String? changelogUrl,
    int? versionCheckComparison,
    VersionCheckerInfo? localVersionCheck,
    RemoteVersionCheckResult? remoteVersionCheck,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (changelogUrl.isNotNullOrEmpty())
              SizedBox(
                width: 400,
                height: 400,
                child: TooltipFrame(
                  child: Builder(
                    builder: (context) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Changelogs(
                              mod,
                              localVersionCheck,
                              remoteVersionCheck,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              "Right-click for more.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            TooltipFrame(
              child: SizedBox(
                width: 400,
                child: VersionCheckTextReadout(
                  versionCheckComparison,
                  localVersionCheck,
                  remoteVersionCheck,
                  true,
                  true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static IntrinsicHeight changeAndVersionCheckAlertDialogContent(
    Mod mod,
    String? changelogUrl,
    VersionCheckerInfo? localVersionCheck,
    RemoteVersionCheckResult? remoteVersionCheck,
    int? versionCheckComparison,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (changelogUrl.isNotNullOrEmpty())
            SingleChildScrollView(
              child: SizedBox(
                width: 500,
                height: 500,
                child: Changelogs(mod, localVersionCheck, remoteVersionCheck),
              ),
            ),
          if (changelogUrl.isNotNullOrEmpty())
            const Padding(padding: EdgeInsets.all(8), child: VerticalDivider()),
          Expanded(
            child: SelectionArea(
              child: VersionCheckTextReadout(
                versionCheckComparison,
                localVersionCheck,
                remoteVersionCheck,
                true,
                false,
              ),
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
    var cachedVersionChecks = ref
        .watch(AppState.versionCheckResults)
        .value;
    final mod = widget.mod;
    final modVariant =
        mod.findFirstEnabledOrHighestVersion ?? mod.modVariants.first;

    final gameVersion = ref.watch(AppState.starsectorVersion).value;
    final modInfo = modVariant.modInfo;
    final versionCheckComparisonResult = mod.updateCheck(cachedVersionChecks);
    final versionCheckComparison = versionCheckComparisonResult?.comparisonInt;
    final localVersionCheck =
        versionCheckComparisonResult?.variant.versionCheckerInfo;
    final remoteVersionCheck = versionCheckComparisonResult?.remoteVersionCheck;
    final compatWithGame = compareGameVersions(
      modInfo.gameVersion,
      gameVersion,
    );
    final theme = Theme.of(context);
    final compatTextColor = compatWithGame.getGameCompatibilityColor();
    final changelogUrl = ref
        .read(AppState.changelogsProvider.notifier)
        .getChangelogUrl(localVersionCheck, remoteVersionCheck);
    final isEnabled = modVariant.isEnabled(ref.read(AppState.mods));
    final modTextOpacity = compatWithGame == GameCompatibility.incompatible
        ? 0.55
        : 1.0;

    const rowHeight = 25.0;

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: InkWell(
            child: SizedBox(
              height: rowHeight,
              child: MovingTooltipWidget.framed(
                position: TooltipPosition.topLeft,
                padding: const EdgeInsets.all(0),
                tooltipWidget: SizedBox(
                  width: 400,
                  child: ModSummaryWidget(
                    modVariant: modVariant,
                    compatWithGame: compatWithGame,
                    compatTextColor: compatTextColor,
                    showIconTip: true,
                  ),
                ),
                child: CheckboxWithLabel(
                  labelWidget: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
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
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                modInfo.nameOrId,
                                style: GoogleFonts.roboto(
                                  textStyle: theme.textTheme.labelLarge
                                      ?.copyWith(
                                        color: compatTextColor?.withOpacity(
                                          modTextOpacity,
                                        ),
                                        fontWeight: FontWeight.normal,
                                      ),
                                ),
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 75),
                              child: Text(
                                modInfo.version.toString(),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      MovingTooltipWidget(
                        position: TooltipPosition.topLeft,
                        tooltipWidget:
                            ModListBasicEntry.buildVersionCheckTextReadoutForTooltip(
                              mod,
                              changelogUrl,
                              versionCheckComparison,
                              localVersionCheck,
                              remoteVersionCheck,
                            ),
                        child: Disable(
                          isEnabled: !widget.isDisabled,
                          child: InkWell(
                            onTap: () {
                              if (remoteVersionCheck?.remoteVersion != null &&
                                  versionCheckComparison == -1) {
                                ref
                                    .read(downloadManager.notifier)
                                    .downloadUpdateViaBrowser(
                                      remoteVersionCheck!.remoteVersion!,
                                      activateVariantOnComplete: false,
                                      modInfo: modInfo,
                                    );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    content:
                                        ModListBasicEntry.changeAndVersionCheckAlertDialogContent(
                                          mod,
                                          changelogUrl,
                                          localVersionCheck,
                                          remoteVersionCheck,
                                          versionCheckComparison,
                                        ),
                                  ),
                                );
                              }
                            },
                            onSecondaryTap: () => showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                content:
                                    ModListBasicEntry.changeAndVersionCheckAlertDialogContent(
                                      mod,
                                      changelogUrl,
                                      localVersionCheck,
                                      remoteVersionCheck,
                                      versionCheckComparison,
                                    ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5.0,
                              ),
                              child: VersionCheckIcon.fromComparison(
                                comparison: versionCheckComparisonResult,
                                modId: modInfo.id,
                                theme: theme,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  checkWrapper: (child) =>
                      Disable(isEnabled: !widget.isDisabled, child: child),
                  textPadding: const EdgeInsets.only(left: 0, bottom: 2),
                  value: isEnabled,
                  expand: true,
                  onChanged: (_) async {
                    if (widget.isDisabled) {
                      return;
                    }
                    final isCurrentlyEnabled = isEnabled;

                    if (!isCurrentlyEnabled) {
                      final allMods =
                          ref.read(AppState.modVariants).value ?? [];
                      final enabledMods = ref
                          .read(AppState.enabledModIds)
                          .value!;
                      // Check dependencies
                      final dependencyCheck = modInfo.checkDependencies(
                        allMods,
                        enabledMods,
                        gameVersion,
                      );

                      // Check if any dependencies are completely missing
                      final missingDependencies = dependencyCheck.where(
                        (element) => element.satisfiedAmount is Missing,
                      );
                      if (missingDependencies.isNotEmpty) {
                        showSnackBar(
                          context: context,
                          type: SnackBarType.error,
                          content: Text(
                            "'${modInfo.name}' is missing '${missingDependencies.joinToString(transform: (it) => it.dependency.name ?? it.dependency.id ?? "<unknown>")}'.",
                          ),
                        );
                        return;
                      }
                    }

                    final modsFolder = ref
                        .read(AppState.modsFolder)
                        .value;
                    if (modsFolder == null) return;

                    try {
                      if (isCurrentlyEnabled) {
                        // Disable
                        ref
                            .read(modManager.notifier)
                            .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                              mod,
                              null,
                            );
                      } else {
                        // Enable highest version
                        ref
                            .read(modManager.notifier)
                            .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                              mod,
                              mod.findHighestVersion,
                            );
                      }
                    } catch (e) {
                      showSnackBar(
                        context: context,
                        type: SnackBarType.error,
                        content: Text(e.toString()),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
