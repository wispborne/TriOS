import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
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
    final enabledMods = ref.watch(AppState.enabledModIds).value;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text("Mods", style: Theme.of(context).textTheme.titleLarge),
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
                          final color = switch (
                              compareGameVersions(modInfo.gameVersion, ref.read(AppState.starsectorVersion).value)) {
                            GameCompatibility.DiffVersion => const Color.fromARGB(255, 252, 99, 0),
                            GameCompatibility.DiffRC => const Color.fromARGB(255, 253, 212, 24),
                            GameCompatibility.SameRC => null,
                          };
                          return Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Flexible(
                                child: SizedBox(
                                  height: 26,
                                  child: CheckboxWithLabel(
                                    labelWidget: Text("${modInfo.name} ${modInfo.version}",
                                        overflow: TextOverflow.fade,
                                        softWrap: false,
                                        maxLines: 1,
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color)),
                                    value: enabledMods?.contains(modInfo.id) ?? false,
                                    expand: true,
                                    onChanged: (_) {
                                      if (enabledMods == null) return;
                                      var isCurrentlyEnabled = enabledMods.contains(modInfo.id);

                                      // TODO check mod dependencies.
                                      // We can disable mods without checking compatibility, but we can't enable them without checking.
                                      if (!isCurrentlyEnabled) {
                                        final compatResult = compareGameVersions(
                                            modInfo.gameVersion, ref.read(AppState.starsectorVersion).value);
                                        if (compatResult == GameCompatibility.DiffVersion) {
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
