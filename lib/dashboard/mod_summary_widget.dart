import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/utils.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/models/enabled_mods.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/extensions.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../themes/theme_manager.dart';
import '../trios/app_state.dart';
import '../widgets/fancy_mod_tooltip_header.dart';

class ModSummaryWidget extends ConsumerStatefulWidget {
  final ModVariant modVariant;
  final Color? compatTextColor;
  final GameCompatibility? compatWithGame;
  final bool showIconTip;

  const ModSummaryWidget({
    super.key,
    required this.modVariant,
    this.compatTextColor,
    this.compatWithGame,
    required this.showIconTip,
  });

  @override
  ConsumerState createState() => _ModSummaryWidgetState();
}

class _ModSummaryWidgetState extends ConsumerState<ModSummaryWidget> {
  @override
  Widget build(BuildContext context) {
    final modVariants = ref.watch(AppState.modVariants).valueOrNull;
    final mods = ref.watch(AppState.mods);
    final gameVersion = ref.watch(AppState.starsectorVersion).valueOrNull;
    final enabledMods = ref
        .watch(AppState.enabledModsFile)
        .valueOrNull
        ?.filterOutMissingMods(mods)
        .enabledMods
        .toList();
    if (modVariants == null || enabledMods == null) return const SizedBox();

    final modVariant = widget.modVariant;
    final modInfo = modVariant.modInfo;
    var cachedVersionChecks =
        ref.watch(AppState.versionCheckResults).valueOrNull;
    final versionCheckComparisonResult =
        modVariant.updateCheck(cachedVersionChecks ?? {});
    final versionCheckComparison = versionCheckComparisonResult?.comparisonInt;
    final localVersionCheck =
        versionCheckComparisonResult?.variant.versionCheckerInfo;
    final remoteVersionCheck = versionCheckComparisonResult?.remoteVersionCheck;
    final theme = Theme.of(context);

    var versionTextStyle = theme.textTheme.labelLarge?.copyWith(
        fontFeatures: [const FontFeature.tabularFigures()],
        color: theme.colorScheme.primary);
    const spacing = 4.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: ModTooltipFancyTitleHeader(
            iconPath: modVariant.iconFilePath,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: modVariant.iconFilePath != null ? 40 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(modInfo.name ?? "(no name)",
                        style: theme.textTheme.titleMedium),
                    Text("${modInfo.id} • ${modInfo.version ?? ""}",
                        style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: spacing),
              if (versionCheckComparison == -1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "New version:      ${remoteVersionCheck?.remoteVersion?.modVersion}",
                        style: versionTextStyle),
                    Text("Current version: ${localVersionCheck?.modVersion}",
                        style: versionTextStyle),
                  ],
                ),
              const SizedBox(height: spacing),
              if (modInfo.author != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Author",
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: theme.disabledColor)),
                    Padding(
                      padding: const EdgeInsets.only(left: 0.0),
                      child: Text(modInfo.author ?? "(none)",
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium),
                    ),
                  ],
                ),
              const SizedBox(height: spacing),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Description",
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.disabledColor)),
                  Text("${modInfo.description}",
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: spacing),
              Text("Required game version",
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.disabledColor)),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(modInfo.gameVersion ?? "",
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: widget.compatTextColor)),
              ),
              if (modInfo.originalGameVersion != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Original game version",
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: ThemeManager.vanillaWarningColor
                                .withOpacity(0.8))),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(modInfo.originalGameVersion ?? "",
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: ThemeManager.vanillaWarningColor)),
                    ),
                  ],
                ),
              Text("Game version",
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.disabledColor)),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child:
                    Text(gameVersion ?? "", style: theme.textTheme.labelMedium),
              ),
              if (widget.compatWithGame == GameCompatibility.incompatible)
                Text(
                    "Error: this mod requires a different version of the game.",
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: widget.compatTextColor)),
              const SizedBox(height: spacing),
              if (modInfo.dependencies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Required Mods:",
                      style: theme.textTheme.labelMedium),
                ),
              for (var dep in modInfo.dependencies)
                Builder(builder: (context) {
                  var dependencyState = dep.isSatisfiedByAny(
                      modVariants, enabledMods, gameVersion);
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                        "${dep.name ?? dep.id} ${dep.version?.toString().append(" ") ?? ""}${dependencyState.getDependencyStateText()}",
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: getStateColorForDependencyText(
                                dependencyState))),
                  );
                }),
              const SizedBox(height: spacing),
              if (modInfo.dependencies.any((dep) => dep.isSatisfiedByAny(
                  modVariants, enabledMods, gameVersion) is VersionWarning))
                Text(
                  "Warning: this mod requires a different version of a mod that you have installed, but might run with this one.",
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: ThemeManager.vanillaErrorColor),
                ),
              if (widget.showIconTip)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Opacity(
                    opacity: 0.6,
                    child: Text(
                        "Tip: Add a LunaSettings icon or add an icon.png file to the mod folder to get an icon like this!",
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontStyle: FontStyle.italic)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
