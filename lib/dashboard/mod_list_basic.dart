import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/dashboard/mod_summary_widget.dart';
import 'package:trios/trios/trios_theme.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../mod_manager/version_checker.dart';
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
    final modList = ref.watch(AppState.modVariants).valueOrNull;
    var versionCheck = ref.watch(versionCheckResults).valueOrNull;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text("Mods", style: Theme.of(context).textTheme.titleLarge),
          Text(modList != null ? " ${enabledModIds?.length ?? 0} of ${modList.length} enabled" : "",
              style: Theme.of(context).textTheme.labelMedium),
          Expanded(
            child: ref.watch(AppState.modVariants).when(
                  data: (modVariants) {
                    return VsScrollbar(
                      controller: _scrollController,
                      isAlwaysShown: true,
                      showTrackOnHover: true,
                      child: ListView.builder(
                        shrinkWrap: true,
                        controller: _scrollController,
                        itemCount: modVariants.length,
                        itemBuilder: (context, index) {
                          final modVariant = modVariants.sortedBy((info) => info.modInfo.name).toList()[index];
                          final modInfo = modVariant.modInfo;
                          final localVersionCheck = modVariant.versionCheckerInfo;
                          final remoteVersionCheck = versionCheck?[modVariant.smolId];
                          final compatWithGame =
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
                                              child: ModSummaryWidget(
                                                modVariant: modVariant,
                                                compatWithGame: compatWithGame,
                                                compatTextColor: compatTextColor,
                                              ),
                                            ),
                                          ),
                                        )),
                                    child: CheckboxWithLabel(
                                      labelWidget: Row(
                                        children: [
                                          if (localVersionCheck?.modVersion != null &&
                                              remoteVersionCheck?.remoteVersion?.modVersion != null)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 4),
                                              child: Icon(
                                                  switch (localVersionCheck?.modVersion
                                                      ?.compareTo(remoteVersionCheck?.remoteVersion?.modVersion)) {
                                                    -1 => Icons.download,
                                                    0 => Icons.check,
                                                    _ => Icons.check,
                                                  },
                                                  size: 20,
                                                  color: switch (localVersionCheck?.modVersion
                                                      ?.compareTo(remoteVersionCheck?.remoteVersion?.modVersion)) {
                                                    -1 => theme.colorScheme.secondary,
                                                    _ => null,
                                                  }),
                                            ),
                                          if (localVersionCheck?.modVersion == null ||
                                              remoteVersionCheck?.remoteVersion?.modVersion == null)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 4),
                                              child: ColorFiltered(
                                                colorFilter: greyscale,
                                                child: Text("🥱",
                                                    style: theme.textTheme.labelMedium
                                                        ?.copyWith(color: theme.disabledColor.withOpacity(0.35))),
                                              ),
                                            ),
                                          Expanded(
                                            child: Text("${modInfo.name} ${modInfo.version}",
                                                overflow: TextOverflow.fade,
                                                softWrap: false,
                                                maxLines: 1,
                                                style: theme.textTheme.labelLarge?.copyWith(color: compatTextColor)),
                                          ),
                                        ],
                                      ),
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
