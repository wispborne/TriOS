import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/utils.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod_variant.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../trios/app_state.dart';
import '../trios/trios_theme.dart';

class ModSummaryWidget extends ConsumerStatefulWidget {
  final ModVariant modVariant;
  final Color? compatTextColor;
  final GameCompatibility? compatWithGame;

  const ModSummaryWidget({super.key, required this.modVariant, this.compatTextColor, this.compatWithGame});

  @override
  ConsumerState createState() => _ModSummaryWidgetState();
}

class _ModSummaryWidgetState extends ConsumerState<ModSummaryWidget> {
  @override
  Widget build(BuildContext context) {
    final enabledMods = ref.watch(AppState.enabledMods).valueOrNull;
    final modVariants = ref.watch(AppState.modVariants).valueOrNull;
    if (modVariants == null || enabledMods == null) return const SizedBox();

    final modVariant = widget.modVariant;
    final modInfo = modVariant.modInfo;
    var remoteVersionCheck = ref.watch(versionCheckResults).valueOrNull?[modVariant.smolId];
    final localVersionCheck = modVariant.versionCheckerInfo;
    // final remoteVersionCheck = versionCheck?[modVariant.smolId];
    final versionCheckComparison = compareLocalAndRemoteVersions(localVersionCheck, remoteVersionCheck);
    final theme = Theme.of(context);

    var versionTextStyle = theme.textTheme.labelLarge
        ?.copyWith(fontFeatures: [const FontFeature.tabularFigures()], color: theme.colorScheme.primary);
    const spacing = 4.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (versionCheckComparison == -1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("New version:      ${remoteVersionCheck?.remoteVersion?.modVersion}", style: versionTextStyle),
              Text("Current version: ${localVersionCheck?.modVersion}", style: versionTextStyle),
              const Divider()
            ],
          ),
        Text(modInfo.name, style: theme.textTheme.titleMedium),
        Text("${modInfo.id} • ${modInfo.version}", style: theme.textTheme.labelSmall),
        const SizedBox(height: spacing),
        if (modInfo.author != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Author", style: theme.textTheme.labelMedium?.copyWith(color: theme.disabledColor)),
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Text(modInfo.author!,
                    maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium),
              ),
            ],
          ),
        const SizedBox(height: spacing),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Description", style: theme.textTheme.labelMedium?.copyWith(color: theme.disabledColor)),
            Text("${modInfo.description}",
                maxLines: 4, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: spacing),
        Text("Required game version", style: theme.textTheme.labelMedium?.copyWith(color: theme.disabledColor)),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(modInfo.gameVersion ?? "",
              style: theme.textTheme.labelMedium?.copyWith(color: widget.compatTextColor)),
        ),
        Text("Game version", style: theme.textTheme.labelMedium?.copyWith(color: theme.disabledColor)),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(ref.read(AppState.starsectorVersion).value ?? "", style: theme.textTheme.labelMedium),
        ),
        if (widget.compatWithGame == GameCompatibility.incompatible)
          Text("Error: this mod requires a different version of the game.",
              style: theme.textTheme.labelMedium?.copyWith(color: widget.compatTextColor)),
        const SizedBox(height: spacing),
        if (modInfo.dependencies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("Required Mods:", style: theme.textTheme.labelMedium),
          ),
        for (var dep in modInfo.dependencies)
          Builder(builder: (context) {
            var dependencyState = dep.isSatisfiedByAny(modVariants, enabledMods);
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                  "${dep.name ?? dep.id} ${dep.version?.toString().append(" ") ?? ""}${switch (dependencyState) {
                    Satisfied _ => "(found ${dependencyState.mod?.version})",
                    Missing _ => "(missing)",
                    Disabled _ => "(not enabled: ${dependencyState.mod?.version})",
                    VersionInvalid _ => "(wrong version: ${dependencyState.mod?.version})",
                    VersionWarning _ => "(found: ${dependencyState.mod?.version})",
                  }}",
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: switch (dependencyState) {
                    Satisfied _ => null,
                    Missing _ => vanillaErrorColor,
                    Disabled _ =>
                      vanillaWarningColor, // Disabled means it's present, so we can just enable it.
                    VersionInvalid _ => vanillaErrorColor,
                    VersionWarning _ => vanillaWarningColor,
                  })),
            );
          }),
        const SizedBox(height: spacing),
        if (modInfo.dependencies.any((dep) => dep.isSatisfiedByAny(modVariants, enabledMods) is VersionWarning))
          Text(
              "Warning: this mod requires a different version of a mod that you have installed, but might run with this one.",
              style: theme.textTheme.labelMedium?.copyWith(color: vanillaErrorColor)),
      ],
    );
  }
}