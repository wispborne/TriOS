import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod_variant.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../trios/app_state.dart';
import '../trios/trios_theme.dart';
import 'mod_list_basic.dart';

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
    final enabledMods = ref.watch(AppState.enabledMods).valueOrNull;
    final modVariants = ref.watch(AppState.modVariants).valueOrNull;
    final modVariant = widget.modVariant;
    final modInfo = modVariant.modInfo;
    if (modVariants == null || enabledMods == null) return const SizedBox();

    var remoteVersionCheck =
        ref.watch(versionCheckResults).valueOrNull?[modVariant.smolId];
    final localVersionCheck = modVariant.versionCheckerInfo;
    // final remoteVersionCheck = versionCheck?[modVariant.smolId];
    final versionCheckComparison =
        compareLocalAndRemoteVersions(localVersionCheck, remoteVersionCheck);
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: VersionCheckInfo(
              versionCheckComparison, localVersionCheck, remoteVersionCheck),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(modInfo.name, style: theme.textTheme.titleMedium),
            Text(modInfo.id, style: theme.textTheme.labelSmall),
            Text(modInfo.version.toString(),
                style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Text("${modInfo.description}",
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text("Required game version:",
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.disabledColor)),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(modInfo.gameVersion ?? "",
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: widget.compatTextColor)),
            ),
            Text("Game version:",
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.disabledColor)),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(ref.read(AppState.starsectorVersion).value ?? "",
                  style: theme.textTheme.labelMedium),
            ),
            if (widget.compatWithGame == GameCompatibility.Incompatible)
              Text("Error: this mod requires a different version of the game.",
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: widget.compatTextColor)),
            const SizedBox(height: 8),
            if (modInfo.dependencies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child:
                    Text("Required Mods:", style: theme.textTheme.labelMedium),
              ),
            for (var dep in modInfo.dependencies)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text("${dep.name ?? dep.id} ${dep.version ?? ""}",
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: switch (
                            dep.isSatisfiedByAny(modVariants, enabledMods)) {
                      DependencyStateType.Satisfied => null,
                      DependencyStateType.Missing =>
                        TriOSTheme.vanillaErrorColor,
                      DependencyStateType.Disabled =>
                        null, // Disabled means it's present, so we can just enable it.
                      DependencyStateType.WrongVersion =>
                        TriOSTheme.vanillaWarningColor
                    })),
              ),
            const SizedBox(height: 8),
            if (modInfo.dependencies.any((dep) =>
                dep.isSatisfiedByAny(modVariants, enabledMods) ==
                DependencyStateType.WrongVersion))
              Text(
                  "Warning: this mod requires a different version of a mod that you have installed, but might run with this one.",
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: TriOSTheme.vanillaErrorColor)),
            const SizedBox(height: 8),
            if (modInfo.author != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Author: ",
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.disabledColor)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2.0),
                      child: Text(modInfo.author!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (widget.modVariant.versionCheckerInfo != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Local VC: ${widget.modVariant.versionCheckerInfo?.modVersion ?? "N/A"}",
                      style: theme.textTheme.labelMedium),
                  Text(
                      "Remote VC: ${remoteVersionCheck?.remoteVersion?.modVersion ?? (remoteVersionCheck?.error != null ? "Error" : "N/A")}",
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: switch (remoteVersionCheck
                                  ?.remoteVersion?.modVersion
                                  ?.compareTo(widget.modVariant
                                      .versionCheckerInfo?.modVersion) ??
                              0) {
                        1 => theme.colorScheme.secondary,
                        _ => null,
                      })),
                ],
              ),
            if (widget.modVariant.versionCheckerInfo == null)
              Text("No version checker info",
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: TriOSTheme.vanillaWarningColor)),
          ],
        ),
      ],
    );
  }
}
