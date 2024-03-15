import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/trios_theme.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../trios/app_state.dart';
import '../trios/settings/settings.dart';

class ModListMini extends ConsumerStatefulWidget {
  const ModListMini({super.key});

  @override
  ConsumerState createState() => _ModListMiniState();
}

class _ModListMiniState extends ConsumerState<ModListMini> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final enabledModIds = ref.watch(AppState.enabledModIds).valueOrNull;
    final enabledMods = ref.watch(AppState.enabledMods).valueOrNull;
    var modList = ref.watch(AppState.modInfos).valueOrNull;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text("Mods", style: Theme.of(context).textTheme.titleLarge),
          Text(modList != null ? " ${enabledModIds?.length ?? 0} of ${modList.length} enabled" : "",
              style: Theme.of(context).textTheme.labelMedium),
          Expanded(
            child: ref.watch(AppState.modInfos).when(
                  data: (modInfos) {
                    return VsScrollbar(
                      controller: _scrollController,
                      isAlwaysShown: true,
                      showTrackOnHover: true,
                      child: ListView.builder(
                        shrinkWrap: true,
                        controller: _scrollController,
                        itemCount: modInfos.length,
                        itemBuilder: (context, index) {
                          var modInfo = modInfos.sortedBy((info) => info.name).toList()[index];
                          var compatWithGame =
                              compareGameVersions(modInfo.gameVersion, ref.read(AppState.starsectorVersion).value);
                          final compatTextColor = switch (compatWithGame) {
                            GameCompatibility.Incompatible => TriOSTheme.vanillaErrorColor,
                            GameCompatibility.Warning => TriOSTheme.vanillaWarningColor,
                            GameCompatibility.Compatible => null,
                          };
                          var theme = Theme.of(context);
                          return Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Flexible(
                                child: SizedBox(
                                  height: 26,
                                  child: MovingTooltipWidget(
                                    tooltipWidget: SizedBox(
                                        width: 350,
                                        height: 400,
                                        child: Card(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: theme.cardColor,
                                              borderRadius: BorderRadius.circular(TriOSTheme.cornerRadius),
                                              border: Border.all(color: theme.colorScheme.onBackground),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(modInfo.name, style: theme.textTheme.titleMedium),
                                                  Text(modInfo.id, style: theme.textTheme.labelSmall),
                                                  Text(modInfo.version.toString(), style: theme.textTheme.labelMedium),
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
                                                            ?.copyWith(color: compatTextColor)),
                                                  ),
                                                  Text("Game version:",
                                                      style: theme.textTheme.labelMedium
                                                          ?.copyWith(color: theme.disabledColor)),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 8.0),
                                                    child: Text(ref.read(AppState.starsectorVersion).value ?? "",
                                                        style: theme.textTheme.labelMedium),
                                                  ),
                                                  if (compatWithGame == GameCompatibility.Incompatible)
                                                    Text("Error: this mod requires a different version of the game.",
                                                        style: theme.textTheme.labelMedium
                                                            ?.copyWith(color: compatTextColor)),
                                                  const SizedBox(height: 8),
                                                  if (modInfo.dependencies.isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8.0),
                                                      child: Text("Required Mods:", style: theme.textTheme.labelMedium),
                                                    ),
                                                  for (var dep in modInfo.dependencies)
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 8.0),
                                                      child: Text("${dep.name ?? dep.id} ${dep.version ?? ""}",
                                                          style: theme.textTheme.labelMedium?.copyWith(
                                                              color: switch (
                                                                  dep.isSatisfiedByAny(modInfos, enabledMods!)) {
                                                            DependencyStateType.Satisfied => null,
                                                            DependencyStateType.Missing => TriOSTheme.vanillaErrorColor,
                                                            DependencyStateType.Disabled =>
                                                              null, // Disabled means it's present, so we can just enable it.
                                                            DependencyStateType.WrongVersion =>
                                                              TriOSTheme.vanillaWarningColor
                                                          })),
                                                    ),
                                                  const SizedBox(height: 8),
                                                  if (modInfo.dependencies.any((dep) =>
                                                      dep.isSatisfiedByAny(modInfos, enabledMods!) ==
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
                                                ],
                                              ),
                                            ),
                                          ),
                                        )),
                                    child: CheckboxWithLabel(
                                      labelWidget: Text("${modInfo.name} ${modInfo.version}",
                                          overflow: TextOverflow.fade,
                                          softWrap: false,
                                          maxLines: 1,
                                          style: theme.textTheme.labelLarge?.copyWith(color: compatTextColor)),
                                      value: enabledModIds?.contains(modInfo.id) ?? false,
                                      expand: true,
                                      onChanged: (_) {
                                        if (true) {
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
                                        if (enabledModIds == null) return;
                                        var isCurrentlyEnabled = enabledModIds.contains(modInfo.id);

                                        // TODO check mod dependencies.
                                        // We can disable mods without checking compatibility, but we can't enable them without checking.
                                        if (!isCurrentlyEnabled) {
                                          final compatResult = compatWithGame;
                                          if (compatResult == GameCompatibility.Incompatible) {
                                            ScaffoldMessenger.of(context).clearSnackBars();
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                              content: Text(
                                                  "Mod ${modInfo.name} is not compatible with your game version (${ref.read(AppState.starsectorVersion).value})"),
                                            ));
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
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: SizedBox(width: 48, height: 48, child: CircularProgressIndicator())),
                  error: (error, stackTrace) => Text('Error: $error'),
                ),
          ),
        ],
      ),
    );
  }
}
