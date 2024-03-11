import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../trios/app_state.dart';

class ModListMini extends ConsumerStatefulWidget {
  const ModListMini({super.key});

  @override
  ConsumerState createState() => _ModListMiniState();
}

class _ModListMiniState extends ConsumerState<ModListMini> {
  final ScrollController _scrollController = ScrollController();
  List<String>? enabledMods;

  @override
  Widget build(BuildContext context) {
    ref.watch(appState.enabledModIds).whenData((value) {
      setState(() {
        enabledMods = value;
      });
    });

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text("Mods", style: Theme.of(context).textTheme.titleLarge),
          Expanded(
            child: ref.watch(appState.modInfos).when(
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
                          var modInfo = modInfos[index];
                          final color = switch (
                              compareGameVersions(modInfo.gameVersion, ref.read(appState.starsectorVersion).value)) {
                            GameCompatibility.DiffVersion => const Color.fromARGB(255, 252, 99, 0),
                            GameCompatibility.DiffRC => const Color.fromARGB(255, 253, 212, 24),
                            GameCompatibility.SameRC => null,
                          };
                          return Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Flexible(
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
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stackTrace) => Text('Error: $error'),
                ),
          ),
        ],
      ),
    );
  }
}
