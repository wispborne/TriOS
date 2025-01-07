import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/utils.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/mod_summary_panel.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/widgets/add_new_mods_button.dart';
import 'package:trios/widgets/dropdown_with_icon.dart';
import 'package:trios/widgets/refresh_mods_button.dart';

import '../mod_profiles/mod_profiles_manager.dart';
import '../mod_profiles/models/mod_profile.dart';
import '../models/mod.dart';
import '../trios/settings/settings.dart';
import '../utils/search.dart';
import '../widgets/disable.dart';
import '../widgets/moving_tooltip.dart';
import 'homebrew_grid/copy_mod_list_button.dart';
import 'homebrew_grid/filter_mods_search_view.dart';

final searchQuery = StateProvider.autoDispose<String>((ref) => "");

class ModsGridPage extends ConsumerStatefulWidget {
  const ModsGridPage({super.key});

  @override
  ConsumerState createState() => _ModsGridState();
}

class _ModsGridState extends ConsumerState<ModsGridPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;
  Mod? selectedMod;
  final _searchController = SearchController();
  AnimationController? animationController;
  List<Mod> filteredMods = [];

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final allMods = ref.watch(AppState.mods);
    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;
    final theme = Theme.of(context);

    // _searchController.value = TextEditingValue(text: ref.watch(searchQuery));
    final query = _searchController.value.text;
    final modsMatchingSearch = searchMods(allMods, query) ?? [];

    return Stack(
      children: [
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4, right: 4),
                    child: SizedBox(
                      height: 50,
                      child: Card(
                          child: Padding(
                              padding: const EdgeInsets.only(left: 2, right: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const SizedBox(width: 4),
                                  const AddNewModsButton(
                                    labelWidget: Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Text("Add Mod(s)"),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  const SizedBox(width: 4),
                                  RefreshModsButton(
                                    iconOnly: false,
                                    outlined: true,
                                    isRefreshing: isChangingModProfileProvider,
                                  ),
                                  const SizedBox(width: 4),
                                  Builder(builder: (context) {
                                    final vramEst = ref
                                        .watch(AppState.vramEstimatorProvider);
                                    final isScanningVram =
                                        vramEst.valueOrNull?.isScanning == true;
                                    return Animate(
                                      controller: animationController,
                                      effects: [
                                        if (isScanningVram)
                                          ShimmerEffect(
                                            colors: [
                                              theme.colorScheme.onSurface,
                                              theme.colorScheme.secondary,
                                              theme.colorScheme.primary,
                                              theme.colorScheme.secondary,
                                            ],
                                            duration: const Duration(
                                                milliseconds: 1500),
                                          )
                                      ],
                                      child: OutlinedButton.icon(
                                        onPressed: () => isScanningVram
                                            ? ref
                                                .read(AppState
                                                    .vramEstimatorProvider
                                                    .notifier)
                                                .cancelEstimation()
                                            : showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                      icon: const Icon(
                                                          Icons.memory),
                                                      title: const Text(
                                                          "Estimate VRAM"),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Text(
                                                              "This will scan all enabled mods and estimate the total VRAM usage."),
                                                          const SizedBox(
                                                              height: 8),
                                                          Text(
                                                              "This may take a few minutes and cause your computer to lag!",
                                                              style: TextStyle(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .error)),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            child: const Text(
                                                                "Cancel")),
                                                        TextButton(
                                                            onPressed: () {
                                                              ref
                                                                  .read(AppState
                                                                      .vramEstimatorProvider
                                                                      .notifier)
                                                                  .startEstimating();
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            child: const Text(
                                                                "Estimate"))
                                                      ],
                                                    )),
                                        label: Text(isScanningVram
                                            ? "Cancel Scan"
                                            : "Est. VRAM"),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.8),
                                          side: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.memory),
                                      ),
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 30,
                                    width: 300,
                                    child: FilterModsSearchBar(
                                        searchController: _searchController,
                                        query: ref.watch(searchQuery),
                                        ref: ref),
                                  ),
                                  const Spacer(),
                                  const SizedBox(width: 8),
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Text("Profile:"),
                                  ),
                                  MovingTooltipWidget.text(
                                    message:
                                        isGameRunning ? "Game is running" : "",
                                    child: Disable(
                                      isEnabled: !isGameRunning,
                                      child: SizedBox(
                                        width: 175,
                                        child: Builder(builder: (context) {
                                          final profiles = ref
                                              .watch(modProfilesProvider)
                                              .valueOrNull;
                                          final activeProfileId = ref.watch(
                                              appSettings.select(
                                                  (s) => s.activeModProfileId));
                                          return DropdownButton(
                                              value: profiles?.modProfiles
                                                  .firstWhereOrNull((p) =>
                                                      p.id == activeProfileId),
                                              isDense: true,
                                              isExpanded: true,
                                              hint: const Text("(none active)"),
                                              padding: const EdgeInsets.all(4),
                                              focusColor: Colors.transparent,
                                              items: profiles?.modProfiles
                                                      .map((p) =>
                                                          DropdownMenuItem(
                                                            value: p,
                                                            child: Text(
                                                              "${p.name} (${p.enabledModVariants.length} mods)",
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ))
                                                      .toList() ??
                                                  [],
                                              onChanged: (value) {
                                                if (value is ModProfile) {
                                                  ref
                                                      .read(modProfilesProvider
                                                          .notifier)
                                                      .showActivateDialog(
                                                          value, context);
                                                }
                                              });
                                        }),
                                      ),
                                    ),
                                  ),
                                  CopyModListButtonLarge(
                                      mods: allMods,
                                      enabledMods: allMods
                                          .where((mod) => mod.hasEnabledVariant)
                                          .toList()),
                                  // Builder(builder: (context) {
                                  //   final isDoubleClick = ref.watch(
                                  //       appSettings.select(
                                  //           (s) => s.doubleClickForModsPanel));
                                  //
                                  //   return AnimatedPopupMenuButton(
                                  //       icon: Icon(Icons.more_vert),
                                  //       showArrow: false,
                                  //       onSelected: (value) {
                                  //         ref.read(appSettings.notifier).update(
                                  //             (s) => s.copyWith(
                                  //                 doubleClickForModsPanel:
                                  //                     !value));
                                  //       },
                                  //       menuItems: [
                                  //         PopupMenuItem(
                                  //             value: isDoubleClick,
                                  //             child: Row(
                                  //               children: [
                                  //                 AbsorbPointer(
                                  //                   child: Checkbox(
                                  //                       value: isDoubleClick,
                                  //                       onChanged: (_) {}),
                                  //                 ),
                                  //                 SizedBox(width: 8),
                                  //                 // Space between icon and text
                                  //                 Text(
                                  //                     "Double-click to view side panel"),
                                  //               ],
                                  //             )),
                                  //       ]);
                                  // }),
                                  MovingTooltipWidget.text(
                                    message: "Open side panel",
                                    child: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedMod = modsMatchingSearch
                                                    .isEmpty
                                                ? null
                                                : modsMatchingSearch.random();
                                          });
                                        },
                                        icon: Icon(Icons.view_sidebar)),
                                  ),
                                ],
                              ))),
                    ),
                  ),
                )
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: WispGrid(
                  mods: modsMatchingSearch,
                  onModRowSelected: (mod) {
                    setState(() {
                      if (selectedMod == mod) {
                        selectedMod = null;
                      } else {
                        selectedMod = mod;
                      }
                    });
                  },
                  selectedMod: selectedMod,
                ),
              ),
            ),
          ],
        ),
        if (selectedMod != null)
          Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              width: 400,
              child: ModSummaryPanel(
                selectedMod,
                () {
                  setState(() {
                    selectedMod = null;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}
