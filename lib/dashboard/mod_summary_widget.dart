import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/utils.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/extensions.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../themes/theme_manager.dart';
import '../trios/app_state.dart';

class ModSummaryWidget extends ConsumerStatefulWidget {
  final ModVariant modVariant;
  final Color? compatTextColor;
  final GameCompatibility? compatWithGame;

  const ModSummaryWidget(
      {super.key,
      required this.modVariant,
      this.compatTextColor,
      this.compatWithGame});

  @override
  ConsumerState createState() => _ModSummaryWidgetState();
}

class _ModSummaryWidgetState extends ConsumerState<ModSummaryWidget> {
  @override
  Widget build(BuildContext context) {
    final enabledMods = ref.watch(AppState.enabledModsFile).valueOrNull;
    final modVariants = ref.watch(AppState.modVariants).valueOrNull;
    final gameVersion = ref.watch(AppState.starsectorVersion).valueOrNull;
    if (modVariants == null || enabledMods == null) return const SizedBox();

    final modVariant = widget.modVariant;
    final modInfo = modVariant.modInfo;
    var remoteVersionCheck =
        ref.watch(AppState.versionCheckResults).valueOrNull?[modVariant.smolId];
    final localVersionCheck = modVariant.versionCheckerInfo;
    // final remoteVersionCheck = versionCheck?[modVariant.smolId];
    final versionCheckComparison =
        compareLocalAndRemoteVersions(localVersionCheck, remoteVersionCheck);
    final theme = Theme.of(context);

    var versionTextStyle = theme.textTheme.labelLarge?.copyWith(
        fontFeatures: [const FontFeature.tabularFigures()],
        color: theme.colorScheme.primary);
    const spacing = 4.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (versionCheckComparison == -1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "New version:      ${remoteVersionCheck?.remoteVersion?.modVersion}",
                  style: versionTextStyle),
              Text("Current version: ${localVersionCheck?.modVersion}",
                  style: versionTextStyle),
              const Divider()
            ],
          ),
        Row(
          children: [
            SizedBox(
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
                child: Text(modInfo.author!,
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
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: vanillaWarningColor.withOpacity(0.8))),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(modInfo.originalGameVersion ?? "",
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: vanillaWarningColor)),
              ),
            ],
          ),
        Text("Game version",
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.disabledColor)),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(gameVersion ?? "", style: theme.textTheme.labelMedium),
        ),
        if (widget.compatWithGame == GameCompatibility.incompatible)
          Text("Error: this mod requires a different version of the game.",
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: widget.compatTextColor)),
        const SizedBox(height: spacing),
        if (modInfo.dependencies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("Required Mods:", style: theme.textTheme.labelMedium),
          ),
        for (var dep in modInfo.dependencies)
          Builder(builder: (context) {
            var dependencyState =
                dep.isSatisfiedByAny(modVariants, enabledMods, gameVersion);
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                  "${dep.name ?? dep.id} ${dep.version?.toString().append(" ") ?? ""}${dependencyState.getDependencyStateText()}",
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: getStateColorForDependencyText(dependencyState))),
            );
          }),
        const SizedBox(height: spacing),
        if (modInfo.dependencies.any((dep) => dep.isSatisfiedByAny(
            modVariants, enabledMods, gameVersion) is VersionWarning))
          Text(
              "Warning: this mod requires a different version of a mod that you have installed, but might run with this one.",
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: vanillaErrorColor)),
      ],
    );
  }
}
