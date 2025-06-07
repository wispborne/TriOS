import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/utils.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/models/enabled_mods.dart';
import 'package:trios/models/mod_variant.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../themes/theme_manager.dart';
import '../trios/app_state.dart';

class ModDependenciesWidget extends ConsumerStatefulWidget {
  final ModVariant modVariant;
  final Color? compatTextColor;
  final GameCompatibility? compatWithGame;

  const ModDependenciesWidget({
    super.key,
    required this.modVariant,
    this.compatTextColor,
    this.compatWithGame,
  });

  @override
  ConsumerState createState() => _ModDependenciesWidgetState();
}

class _ModDependenciesWidgetState extends ConsumerState<ModDependenciesWidget> {
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
    // var remoteVersionCheck =
    //     ref.watch(AppState.versionCheckResults).valueOrNull?[modVariant.smolId];
    // final localVersionCheck = modVariant.versionCheckerInfo;
    // final remoteVersionCheck = versionCheck?[modVariant.smolId];
    // final versionCheckComparison =
    //     compareLocalAndRemoteVersions(localVersionCheck, remoteVersionCheck);

    final theme = Theme.of(context);

    // var versionTextStyle = theme.textTheme.labelLarge?.copyWith(
    //     fontFeatures: [const FontFeature.tabularFigures()],
    //     color: theme.colorScheme.primary);
    const spacing = 4.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Required game version",
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.disabledColor,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            modInfo.gameVersion ?? "",
            style: theme.textTheme.labelMedium?.copyWith(
              color: widget.compatTextColor,
            ),
          ),
        ),
        if (modInfo.originalGameVersion != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Original game version",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: ThemeManager.vanillaWarningColor.withOpacity(0.8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  modInfo.originalGameVersion ?? "",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ThemeManager.vanillaWarningColor,
                  ),
                ),
              ),
            ],
          ),
        Text(
          "Game version",
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.disabledColor,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(gameVersion ?? "", style: theme.textTheme.labelMedium),
        ),
        if (widget.compatWithGame == GameCompatibility.incompatible)
          Text(
            "Error: this mod requires a different version of the game.",
            style: theme.textTheme.labelMedium?.copyWith(
              color: widget.compatTextColor,
            ),
          ),
        const SizedBox(height: spacing),
        if (modInfo.dependencies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("Required Mods:", style: theme.textTheme.labelMedium),
          ),
        for (var dep in modInfo.dependencies)
          Builder(
            builder: (context) {
              var dependencyState = dep.isSatisfiedByAny(
                modVariants,
                enabledMods,
                gameVersion,
              );
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  "${dep.name ?? dep.id} ${dep.version?.toString().append(" ") ?? ""}${switch (dependencyState) {
                    Satisfied _ => "(found ${dependencyState.modVariant?.modInfo.version})",
                    Missing _ => "(missing)",
                    Disabled _ => "(disabled: ${dependencyState.modVariant?.modInfo.version})",
                    VersionInvalid _ => "(wrong version: ${dependencyState.modVariant?.modInfo.version})",
                    VersionWarning _ => "(found: ${dependencyState.modVariant?.modInfo.version})",
                  }}",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: switch (dependencyState) {
                      Satisfied _ => null,
                      Missing _ => ThemeManager.vanillaErrorColor,
                      Disabled _ =>
                        ThemeManager
                            .vanillaWarningColor, // Disabled means it's present, so we can just enable it.
                      VersionInvalid _ => ThemeManager.vanillaErrorColor,
                      VersionWarning _ => ThemeManager.vanillaWarningColor,
                    },
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: spacing),
        if (modInfo.dependencies.any(
          (dep) =>
              dep.isSatisfiedByAny(modVariants, enabledMods, gameVersion)
                  is VersionWarning,
        ))
          Text(
            "Warning: this mod requires a different version of a mod that you have installed, but might run with this one.",
            style: theme.textTheme.labelMedium?.copyWith(
              color: ThemeManager.vanillaErrorColor,
            ),
          ),
      ],
    );
  }
}
