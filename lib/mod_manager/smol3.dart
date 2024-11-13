import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/dashboard/changelogs.dart';
import 'package:trios/dashboard/mod_list_basic_entry.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/mod_version_selection_dropdown.dart';
import 'package:trios/mod_manager/mods_grid_state.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/mod_profiles/mod_profiles_manager.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/thirdparty/pluto_grid_plus/lib/pluto_grid_plus.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/debouncer.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/search.dart';
import 'package:trios/widgets/add_new_mods_button.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/text_with_icon.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dashboard/mod_dependencies_widget.dart';
import '../dashboard/version_check_icon.dart';
import '../models/mod.dart';
import '../trios/download_manager/download_manager.dart';
import '../widgets/mod_type_icon.dart';
import '../widgets/moving_tooltip.dart';
import '../widgets/refresh_mods_button.dart';
import '../widgets/tooltip_frame.dart';
import 'mod_context_menu.dart';
import 'mod_summary_panel.dart';

class Smol3 extends ConsumerStatefulWidget {
  const Smol3({super.key});

  @override
  ConsumerState createState() => _Smol3State();
}

typedef GridStateManagerCallback = Function(PlutoGridStateManager);

final searchQuery = StateProvider.autoDispose<String>((ref) => "");

final _stateManagerProvider =
    StateProvider.autoDispose<PlutoGridStateManager?>((ref) => null);

class SmolGridUiState {
  int? sortedColumnIdx;
  bool? sortAscending;
}

const _standardRowHeight = 40.0;
const _dependencyAddedRowHeight = 34.0;

class _Smol3State extends ConsumerState<Smol3>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  bool hasEverLoaded = false;
  Mod? selectedMod;
  int? selectedRowIdx;
  late List<Mod> modsToDisplay;
  late List<Mod> filteredMods;
  final searchController = SearchController();
  AnimationController? animationController;

  // Only update the UI once every 300ms
  final Debouncer gridStateDebouncer =
      Debouncer(initialDelayMs: 2000, milliseconds: 300);

  // Map<String, VersionCheckResult>? versionCheckResults;
  PlutoGridStateManager? stateManager;
  List<PlutoColumn> gridColumns = [];
  List<PlutoRow> gridRows = [];
  final lightTextOpacity = 0.8;
  GridStateManagerCallback? didSetStateManager;

  tooltippy(Widget child, List<ModVariant> modVariants) {
    final modCompat = ref.read(AppState.modCompatibility);
    final gameVersion =
        ref.read(appSettings.select((value) => value.lastStarsectorVersion));
    final compatWithGame = modVariants
        .map((e) => modCompat[e.smolId])
        .toList()
        .leastSevereCompatibility;
    final highestCompatibleGameVersion =
        modVariants.preferHighestVersionForGameVersion(gameVersion)!;

    return MovingTooltipWidget(
      tooltipWidget: SizedBox(
        width: 400,
        child: TooltipFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModDependenciesWidget(
                modVariant: highestCompatibleGameVersion,
                compatWithGame: compatWithGame,
                compatTextColor: compatWithGame.getGameCompatibilityColor(),
              ),
            ],
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(vsync: this);
    modsToDisplay = ref.read(AppState.mods);
    filteredMods = modsToDisplay;
    final versionCheckResults =
        ref.read(AppState.versionCheckResults).valueOrNull;
    const double versionSelectorWidth = 130;
    gridColumns.addAll(createColumns(versionSelectorWidth, lightTextOpacity,
        versionCheckResults, [], [], false));
    gridRows.addAll(createGridRows([], []));
  }

  @override
  void dispose() {
    gridStateDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final stateManager = ref.watch(_stateManagerProvider);
    final gridState =
        ref.watch(appSettings.select((value) => value.modsGridState));
    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

    ref.watch(appSettings.select((value) => value.lastStarsectorVersion));
    final query = ref.watch(searchQuery);
    searchController.value = TextEditingValue(text: query);

    final mods = ref.watch(AppState.mods);
    final versionCheckResults =
        ref.watch(AppState.versionCheckResults).valueOrNull;
    modsToDisplay = mods;
    filteredMods = filterMods(query);
    final enabledMods =
        filteredMods.where((mod) => mod.hasEnabledVariant).toList();
    final disabledMods =
        filteredMods.where((mod) => !mod.hasEnabledVariant).toList();

    const double versionSelectorWidth = 130;

    ref.listen(AppState.vramEstimatorProvider, (prev, next) {
      if (next.isScanning == true) {
        animationController?.repeat();
      } else {
        animationController?.reset();
      }
    });

    // Only update the UI once every 300ms
    // gridStateDebouncer.run(() {

    // Changing profile means lots of changes really fast, don't update the UI or else it'll be super laggy.
    if (!isChangingModProfileProvider) {
      if (stateManager != null) {
        stateManager.refRows.clearFromOriginal();
        stateManager.refRows.addAll(createGridRows(enabledMods, disabledMods,
            shouldSort: query.isEmpty));
        stateManager.refColumns.clearFromOriginal();
        stateManager.refColumns.addAll(createColumns(
            versionSelectorWidth,
            lightTextOpacity,
            versionCheckResults,
            enabledMods,
            disabledMods,
            isGameRunning));
        PlutoGridStateManager.initializeRows(
            stateManager.refColumns, stateManager.refRows);

        stateManager.setRowGroup(
          PlutoRowGroupByColumnDelegate(
            columns: [
              gridColumns[0],
            ],
            showFirstExpandableIcon: false,
            showCount: false,
          ),
        );
        if (stateManager.rows.isNotEmpty) {
          var enabledGroupRow = _getEnabledGroupRow(stateManager);
          if (enabledGroupRow != null &&
              gridState?.isGroupEnabledExpanded !=
                  stateManager.isExpandedGroupedRow(enabledGroupRow)) {
            stateManager.toggleExpandedRowGroup(rowGroup: enabledGroupRow);
          }
          var disabledGroupRow = _getDisabledGroupRow(stateManager);
          if (disabledGroupRow != null &&
              gridState?.isGroupDisabledExpanded !=
                  stateManager.isExpandedGroupedRow(disabledGroupRow)) {
            stateManager.toggleExpandedRowGroup(rowGroup: disabledGroupRow);
          }
          stateManager.setCurrentCell(stateManager.firstCell, selectedRowIdx);
        }
      }
    }
    // });

    return Column(
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
                                isRefreshing: isChangingModProfileProvider,
                              ),
                              const SizedBox(width: 4),
                              Builder(builder: (context) {
                                final vramEst =
                                    ref.watch(AppState.vramEstimatorProvider);
                                return Animate(
                                  controller: animationController,
                                  effects: [
                                    if (vramEst.isScanning)
                                    ShimmerEffect(
                                      colors: [
                                        theme.colorScheme.onSurface,
                                        theme.colorScheme.secondary,
                                        theme.colorScheme.primary,
                                        theme.colorScheme.secondary,
                                      ],
                                      duration:
                                          const Duration(milliseconds: 1500),
                                    )
                                  ],
                                  child: OutlinedButton.icon(
                                    onPressed: () => vramEst.isScanning
                                        ? ref
                                            .read(AppState
                                                .vramEstimatorProvider.notifier)
                                            .cancelEstimation()
                                        : showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                  icon:
                                                      const Icon(Icons.memory),
                                                  title: const Text(
                                                      "Estimate VRAM"),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Text(
                                                          "This will scan all enabled mods and estimate the total VRAM usage."),
                                                      const SizedBox(height: 8),
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
                                                          Navigator.of(context)
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
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: const Text(
                                                            "Estimate"))
                                                  ],
                                                )),
                                    label: Text(vramEst.isScanning
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
                                    searchController: searchController,
                                    query: query,
                                    ref: ref),
                              ),
                              const Spacer(),
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Text("Profile:"),
                              ),
                              Tooltip(
                                message: isGameRunning ? "Game is running" : "",
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
                                          padding: const EdgeInsets.all(4),
                                          focusColor: Colors.transparent,
                                          items: profiles?.modProfiles
                                                  .map((p) => DropdownMenuItem(
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
                                  mods: mods, enabledMods: enabledMods)
                            ],
                          ))),
                ),
              ),
            )
          ],
        ),
        Expanded(
          child: Theme(
            data: theme.copyWith(
              //disable ripple
              splashFactory: NoSplash.splashFactory,
            ),
            child: Stack(
              children: [
                Builder(builder: (context) {
                  final theme = Theme.of(context);
                  return PlutoGrid(
                    mode: PlutoGridMode.selectWithOneTap,
                    configuration: PlutoGridConfiguration(
                        scrollbar: const PlutoGridScrollbarConfig(
                            isAlwaysShown: true,
                            hoverWidth: 10,
                            scrollbarThickness: 8,
                            scrollbarRadius: Radius.circular(5),
                            dragDevices: {
                              PointerDeviceKind.stylus,
                              PointerDeviceKind.touch,
                              PointerDeviceKind.trackpad,
                              PointerDeviceKind.invertedStylus
                            }),
                        style: PlutoGridStyleConfig.dark(
                          enableCellBorderHorizontal: false,
                          enableCellBorderVertical: false,
                          rowHeight: _standardRowHeight,
                          activatedBorderColor: Colors.transparent,
                          inactivatedBorderColor: Colors.transparent,
                          menuBackgroundColor: theme.colorScheme.surface,
                          gridBackgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          rowColor: Colors.transparent,
                          borderColor: Colors.transparent,
                          cellColorInEditState: Colors.transparent,
                          cellColorInReadOnlyState: Colors.transparent,
                          gridBorderColor: Colors.transparent,
                          // cellCheckedColor: Colors.transparent,
                          activatedColor:
                              theme.colorScheme.onSurface.withOpacity(0.1),
                          evenRowColor:
                              theme.colorScheme.surface.withOpacity(0.4),
                          defaultCellPadding: EdgeInsets.zero,
                          defaultColumnFilterPadding: EdgeInsets.zero,
                          defaultColumnTitlePadding: EdgeInsets.zero,
                          enableRowColorAnimation: true,
                          iconSize: 12,
                          columnTextStyle: theme.textTheme.headlineSmall!
                              .copyWith(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                          dragTargetColumnColor:
                              theme.colorScheme.surface.darker(20),
                          iconColor: theme.colorScheme.onSurface.withAlpha(150),
                          cellTextStyle: theme.textTheme.labelLarge!
                              .copyWith(fontSize: 14),
                        )),
                    onLoaded: (PlutoGridOnLoadedEvent event) {
                      hasEverLoaded = true;
                      // stateManager = event.stateManager;
                      ref.read(_stateManagerProvider.notifier).state =
                          event.stateManager;
                      didSetStateManager?.call(event.stateManager);
                      // Most onLoad logic is done in beginning of `build` because that's called on rows/columns change
                    },
                    columns: gridColumns,
                    rows: gridRows,
                    rowColorCallback: (row) {
                      if (row.row == _getEnabledGroupRow(row.stateManager) ||
                          row.row == _getDisabledGroupRow(row.stateManager)) {
                        return theme.colorScheme.onSurface.withOpacity(0.1);
                      }
                      return Colors.transparent;
                    },
                    onSelected: (event) {
                      var row = event.row;

                      if (row != null) {
                        final mod = _getModFromKey(row.key);

                        if (mod == null) {
                          // Clicked on a group row
                          final stateManager = ref.read(_stateManagerProvider);
                          if (stateManager == null) return;
                          _toggleRowGroup(stateManager, row);
                        } else if (selectedMod == mod) {
                          setState(() {
                            selectedMod = null;
                            selectedRowIdx = null;
                          });
                        } else {
                          setState(() {
                            selectedMod = mod;
                            selectedRowIdx = event.rowIdx;
                          });
                        }
                      }
                    },
                    noRowsWidget: Center(
                        child: Container(
                            padding: const EdgeInsets.all(20),
                            child: (hasEverLoaded && modsToDisplay.isEmpty)
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Transform.rotate(
                                        angle: .50,
                                        child: SvgImageIcon(
                                            "assets/images/icon-ice-cream.svg",
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            width: 150),
                                      ),
                                      const Text("mmm, vanilla")
                                    ],
                                  )
                                : hasEverLoaded && filteredMods.isEmpty
                                    ? const Text("No mods found")
                                    : const Text("Loading mods..."))),
                  );
                }),
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
                            selectedRowIdx = null;
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Mod> filterMods(String query) {
    return searchMods(modsToDisplay, query) ?? [];
  }

  void _toggleRowGroup(PlutoGridStateManager stateManager, PlutoRow row) {
    final isEnabledRow =
        row.cells[_Fields.enableDisable.toString()]?.value == 'Enabled';
    final isDisabledRow =
        row.cells[_Fields.enableDisable.toString()]?.value == 'Disabled';
    ref.read(appSettings.notifier).update((s) {
      if (isEnabledRow) {
        return s.copyWith(
            modsGridState: (s.modsGridState ?? ModsGridState()).copyWith(
                isGroupEnabledExpanded:
                    !stateManager.isExpandedGroupedRow(row)));
      } else if (isDisabledRow) {
        return s.copyWith(
            modsGridState: (s.modsGridState ?? ModsGridState()).copyWith(
                isGroupDisabledExpanded:
                    !stateManager.isExpandedGroupedRow(row)));
      }
      return s;
    });
  }

  PlutoRow? _getEnabledGroupRow(PlutoGridStateManager stateManager) {
    return stateManager.rows.firstWhereOrNull((row) {
      return row.cells[_Fields.enableDisable.toString()]?.value == 'Enabled';
    });
  }

  PlutoRow? _getDisabledGroupRow(PlutoGridStateManager stateManager) {
    return stateManager.rows.firstWhereOrNull((row) {
      return row.cells[_Fields.enableDisable.toString()]?.value == 'Disabled';
    });
  }

  Mod? _getModFromKey(Key? key) {
    return key is ValueKey<Mod> ? key.value : null;
  }

  List<PlutoRow> createGridRows(List<Mod> enabledMods, List<Mod> disabledMods,
      {bool shouldSort = true}) {
    List<PlutoRow> sortIfNeeded(List<PlutoRow> rows) {
      if (shouldSort) {
        return rows.sortedBy<String>(
            (e) => e.cells[_Fields.name.toString()]?.value.toString() ?? "");
      }
      return rows;
    }

    return [
      ...sortIfNeeded(
        enabledMods
            .mapIndexed((index, mod) => createRow(mod))
            .whereNotNull()
            .toList(),
      ),
      ...sortIfNeeded(
        disabledMods
            .mapIndexed((index, mod) => createRow(mod))
            .whereNotNull()
            .toList(),
      ),
    ];
  }

  List<PlutoColumn> createColumns(
    double versionSelectorWidth,
    double lightTextOpacity,
    Map<String, RemoteVersionCheckResult>? versionCheckResults,
    List<Mod> enabledMods,
    List<Mod> disabledMods,
    bool isGameRunning,
  ) {
    return [
      PlutoColumn(
        title: '',
        field: _Fields.enableDisable.toString(),
        type: PlutoColumnType.select(['Enabled', 'Disabled']),
        width: 0.00000000000001,
        suppressedAutoSize: true,
        enableSorting: false,
        enableContextMenu: false,
        enableEditingMode: false,
        enableHideColumnMenuItem: true,
        backgroundColor: Colors.transparent,
        enableDropToResize: false,
        renderer: (rendererContext) => Builder(builder: (context) {
          if (filteredMods.isEmpty) return const SizedBox();
          if (rendererContext.row.depth > 0) return const SizedBox();
          final isEnabled =
              _getEnabledGroupRow(rendererContext.stateManager)?.key ==
                  rendererContext.row.key;
          return OverflowBox(
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            fit: OverflowBoxFit.deferToChild,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                  (rendererContext.cell.value ?? "") +
                      " (${isEnabled ? enabledMods.length : disabledMods.length})",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: ThemeManager.orbitron,
                        fontWeight: FontWeight.bold,
                      )),
            ),
          );
        }),
      ),
      PlutoColumn(
          title: '',
          // Version selector
          width: versionSelectorWidth + 20,
          minWidth: versionSelectorWidth + 20,
          field: _Fields.versionSelector.toString(),
          type: PlutoColumnType.text(),
          enableSorting: false,
          enableAutoEditing: false,
          enableEditingMode: false,
          enableSetColumnsMenuItem: false,
          enableDropToResize: false,
          enableFilterMenuItem: false,
          renderer: (rendererContext) => Builder(builder: (context) {
                if (filteredMods.isEmpty) return const SizedBox();
                final mod = _getModFromKey(rendererContext.row.key);
                if (mod == null) return const SizedBox();
                final bestVersion = mod.findFirstEnabledOrHighestVersion;
                if (bestVersion == null) return Container();
                return ContextMenuRegion(
                    contextMenu: buildModContextMenu(mod, ref, context,
                        showSwapToVersion: true),
                    child: tooltippy(
                      RowItemContainer(
                        child: Disable(
                          isEnabled: !isGameRunning,
                          child: ModVersionSelectionDropdown(
                              mod: mod,
                              width: versionSelectorWidth,
                              showTooltip: false),
                        ),
                      ),
                      mod.modVariants,
                    ));
              })),
      PlutoColumn(
          title: '',
          // Utility/Total Conversion icon
          width: 40,
          minWidth: 40,
          field: _Fields.utilityIcon.toString(),
          type: PlutoColumnType.number(),
          renderer: (rendererContext) {
            if (filteredMods.isEmpty) return const SizedBox();
            final mod = _getModFromKey(rendererContext.row.key);
            if (mod == null) return const SizedBox();
            return RowItemContainer(
              child: ModTypeIcon(
                  modVariant: mod.findFirstEnabledOrHighestVersion!),
            );
          }),
      PlutoColumn(
        title: '',
        // Mod icon
        width: 43,
        minWidth: 43,
        field: _Fields.modIcon.toString(),
        type: PlutoColumnType.text(),
        enableSorting: false,
        renderer: (rendererContext) => Builder(builder: (context) {
          if (filteredMods.isEmpty) return const SizedBox();
          String? iconPath = rendererContext.cell.value;
          return iconPath != null
              ? RowItemContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.file(
                        iconPath.toFile(),
                        width: 32,
                        height: 32,
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: 32, height: 32);
        }),
      ),
      PlutoColumn(
        title: 'Name',
        field: _Fields.name.toString(),
        type: PlutoColumnType.text(),
        renderer: (rendererContext) => Builder(builder: (context) {
          if (filteredMods.isEmpty) return const SizedBox();
          final mod = _getModFromKey(rendererContext.row.key);
          if (mod == null) return const SizedBox();
          final theme = Theme.of(context);
          final enabledVersion = mod.findFirstEnabled;
          final modCompatibility =
              ref.watch(AppState.modCompatibility)[enabledVersion?.smolId];
          final unmetDependencies = modCompatibility?.dependencyChecks
                  .where((e) => !e.isCurrentlySatisfied)
                  .toList() ??
              [];

          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: _standardRowHeight,
                  child: ContextMenuRegion(
                      contextMenu: buildModContextMenu(
                        mod,
                        ref,
                        context,
                        showSwapToVersion: true,
                      ),
                      child: tooltippy(
                        // affixToTop( child:
                        RowItemContainer(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 600,
                            ),
                            child: Text(
                              rendererContext.cell.value ?? "(no name)",
                              style: GoogleFonts.roboto(
                                textStyle: theme.textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // )
                          ),
                        ),
                        mod.modVariants,
                      )),
                ),
                if (unmetDependencies.isNotEmpty)
                  OverflowBox(
                    maxWidth: double.infinity,
                    alignment: Alignment.centerLeft,
                    fit: OverflowBoxFit.deferToChild,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...unmetDependencies.map((checkResult) {
                            final buttonStyle = OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: const Size(60, 34),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ThemeManager
                                    .cornerRadius), // Rounded corners
                              ),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Tooltip(
                                message:
                                    "Requires ${checkResult.dependency.formattedNameVersion}",
                                child: Row(
                                  children: [
                                    // if (checkResult.satisfiedAmount is Disabled)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Builder(builder: (context) {
                                        if (checkResult.satisfiedAmount
                                            is Disabled) {
                                          final disabledVariant = (checkResult
                                                  .satisfiedAmount as Disabled)
                                              .modVariant;
                                          return OutlinedButton(
                                              onPressed: () {
                                                ref
                                                    .read(AppState
                                                        .modVariants.notifier)
                                                    .changeActiveModVariant(
                                                        disabledVariant!.mod(
                                                            modsToDisplay)!,
                                                        disabledVariant);
                                              },
                                              style: buttonStyle,
                                              child: TextWithIcon(
                                                text:
                                                    "Enable ${disabledVariant?.modInfo.formattedNameVersion}",
                                                leading: disabledVariant
                                                            ?.iconFilePath ==
                                                        null
                                                    ? null
                                                    : Image.file(
                                                        (disabledVariant
                                                                    ?.iconFilePath ??
                                                                "")
                                                            .toFile(),
                                                        height: 20,
                                                        isAntiAlias: true,
                                                      ),
                                                leadingPadding:
                                                    const EdgeInsets.only(
                                                        right: 4),
                                              ));
                                        } else {
                                          final missingDependency =
                                              checkResult.dependency;

                                          return OutlinedButton(
                                              onPressed: () async {
                                                final modName =
                                                    missingDependency
                                                        .formattedNameVersionId;
                                                // Advanced search
                                                final url = Uri.parse(
                                                    'https://www.google.com/search?q=starsector+$modName+download');

                                                if (await canLaunchUrl(url)) {
                                                  await launchUrl(url);
                                                } else {
                                                  showSnackBar(
                                                      context: context,
                                                      content: const Text(
                                                          "Couldn't open browser. Google recommends Chrome for a faster experience!"));
                                                }
                                              },
                                              style: buttonStyle,
                                              child: TextWithIcon(
                                                text:
                                                    "Search ${missingDependency.formattedNameVersionId}",
                                                leading: const SvgImageIcon(
                                                  "assets/images/icon-search.svg",
                                                  width: 20,
                                                  height: 20,
                                                ),
                                                leadingPadding:
                                                    const EdgeInsets.only(
                                                        right: 4),
                                              ));
                                        }
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
              ]);
        }),
        // onSort: (columnIndex, ascending) => _onSort(
        //     columnIndex,
        //     (mod) =>
        //         mod.findFirstEnabledOrHighestVersion?.modInfo.name ??
        //         ""),
      ),
      PlutoColumn(
        title: 'Author',
        field: _Fields.author.toString(),
        type: PlutoColumnType.text(),
        textAlign: PlutoColumnTextAlign.left,
        // onSort: (columnIndex, ascending) => _onSort(
        //     columnIndex,
        //     (mod) =>
        //         mod.findFirstEnabledOrHighestVersion?.modInfo
        //             .author ??
        //         ""),
        renderer: (rendererContext) => Builder(builder: (context) {
          if (filteredMods.isEmpty) return const SizedBox();
          final mod = _getModFromKey(rendererContext.row.key);
          if (mod == null) return const SizedBox();
          final theme = Theme.of(context);
          final lightTextColor =
              theme.colorScheme.onSurface.withOpacity(lightTextOpacity);
          return ContextMenuRegion(
              contextMenu: buildModContextMenu(mod, ref, context,
                  showSwapToVersion: true),
              child: RowItemContainer(
                child: Text(
                  rendererContext.cell.value
                          ?.toString()
                          .replaceAll("\n", "   ") ??
                      "(no author)",
                  maxLines: 1,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: lightTextColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ));
        }),
      ),
      PlutoColumn(
        title: 'Version(s)',
        field: _Fields.versions.toString(),
        minWidth: 100,
        type: PlutoColumnType.text(),
        renderer: (rendererContext) => Builder(builder: (context) {
          if (filteredMods.isEmpty) return const SizedBox();
          final mod = _getModFromKey(rendererContext.row.key);
          if (mod == null) return const SizedBox();
          final bestVersion = mod.findFirstEnabledOrHighestVersion;
          final theme = Theme.of(context);
          final lightTextColor =
              theme.colorScheme.onSurface.withOpacity(lightTextOpacity);
          if (bestVersion == null) return const SizedBox();
          final enabledVersion = mod.findFirstEnabled;
          final versionCheckResultsNew =
              ref.watch(AppState.versionCheckResults).valueOrNull;
          //
          final versionCheckComparison =
              mod.updateCheck(versionCheckResultsNew ?? {});
          final localVersionCheck =
              versionCheckComparison?.variant.versionCheckerInfo;
          final remoteVersionCheck = versionCheckComparison?.remoteVersionCheck;
          final changelogUrl = Changelogs.getChangelogUrl(
              versionCheckComparison?.variant.versionCheckerInfo,
              versionCheckComparison?.remoteVersionCheck);

          return
              // affixToTop(                      child:
              mod.modVariants.isEmpty
                  ? const Text("")
                  : RowItemContainer(
                      child: Row(
                        children: [
                          if (changelogUrl.isNotNullOrEmpty())
                            MovingTooltipWidget(
                              tooltipWidget: SizedBox(
                                width: 400,
                                height: 400,
                                child: TooltipFrame(
                                  child: Stack(
                                    children: [
                                      Align(
                                          alignment: Alignment.topRight,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4, top: 0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 4),
                                                  child: SvgImageIcon(
                                                    "assets/images/icon-bullhorn-variant.svg",
                                                    color: theme
                                                        .colorScheme.primary,
                                                    width: 20,
                                                    height: 20,
                                                  ),
                                                ),
                                                Text(
                                                    "Click horn to see full changelog",
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: theme
                                                          .colorScheme.primary,
                                                    )),
                                              ],
                                            ),
                                          )),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Changelogs(
                                          localVersionCheck,
                                          remoteVersionCheck,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                          content: Changelogs(localVersionCheck,
                                              remoteVersionCheck)));
                                },
                                child: SvgImageIcon(
                                  "assets/images/icon-bullhorn-variant.svg",
                                  color:
                                      theme.iconTheme.color?.withOpacity(0.7),
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                            ),
                          MovingTooltipWidget(
                            tooltipWidget:
                                ModListBasicEntry.buildVersionCheckTextReadout(
                                    null,
                                    versionCheckComparison?.comparisonInt,
                                    localVersionCheck,
                                    remoteVersionCheck),
                            child: Disable(
                              isEnabled: !isGameRunning,
                              child: InkWell(
                                onTap: () {
                                  if (remoteVersionCheck?.remoteVersion !=
                                          null &&
                                      versionCheckComparison?.comparisonInt ==
                                          -1) {
                                    ref
                                        .read(downloadManager.notifier)
                                        .downloadUpdateViaBrowser(
                                            remoteVersionCheck!.remoteVersion!,
                                            activateVariantOnComplete: false,
                                            modInfo: bestVersion.modInfo);
                                  } else {
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                            content: ModListBasicEntry
                                                .changeAndVersionCheckAlertDialogContent(
                                                    changelogUrl,
                                                    localVersionCheck,
                                                    remoteVersionCheck,
                                                    versionCheckComparison
                                                        ?.comparisonInt)));
                                  }
                                },
                                onSecondaryTap: () => showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                        content: ModListBasicEntry
                                            .changeAndVersionCheckAlertDialogContent(
                                                changelogUrl,
                                                localVersionCheck,
                                                remoteVersionCheck,
                                                versionCheckComparison
                                                    ?.comparisonInt))),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: VersionCheckIcon.fromComparison(
                                      comparison: versionCheckComparison,
                                      theme: theme),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  for (var i = 0;
                                      i < mod.modVariants.length;
                                      i++) ...[
                                    if (i > 0)
                                      TextSpan(
                                        text: ', ',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                            color:
                                                lightTextColor), // Style for the comma
                                      ),
                                    TextSpan(
                                      text: mod.modVariants[i].modInfo.version
                                          .toString(),
                                      style: theme.textTheme.labelLarge?.copyWith(
                                          color: enabledVersion ==
                                                  mod.modVariants[i]
                                              ? null
                                              : lightTextColor), // Style for the remaining items
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                        // ),
                      ),
                    );
        }),
      ),
      PlutoColumn(
        title: 'VRAM Est.',
        field: _Fields.vramEstimate.toString(),
        width: 100,
        minWidth: 100,
        type: PlutoColumnType.number(),
        renderer: (rendererContext) => Builder(builder: (context) {
          if (filteredMods.isEmpty) return const SizedBox();
          final mod = _getModFromKey(rendererContext.row.key);
          if (mod == null) return const SizedBox();
          final theme = Theme.of(context);
          final lightTextColor =
              theme.colorScheme.onSurface.withOpacity(lightTextOpacity);
          final bestVersion = mod.findFirstEnabledOrHighestVersion;
          if (bestVersion == null) return const SizedBox();
          return ContextMenuRegion(
              contextMenu: buildModContextMenu(mod, ref, context,
                  showSwapToVersion: true),
              child: RowItemContainer(
                child: Builder(builder: (context) {
                  final vramEstimatorState =
                      ref.watch(AppState.vramEstimatorProvider);
                  final vramMap = vramEstimatorState.modVramInfo;
                  final biggestFish = vramMap
                      .maxBy((e) => e.value.totalBytesForMod)
                      ?.value
                      .totalBytesForMod;
                  final ratio = biggestFish == null
                      ? 0.00
                      : (vramMap[bestVersion.smolId]
                                  ?.totalBytesForMod
                                  .toDouble() ??
                              0) /
                          biggestFish.toDouble();
                  final vramEstimate = vramMap[bestVersion.smolId];

                  return Expanded(
                    child: MovingTooltipWidget.text(
                      message: vramEstimate == null
                          ? ""
                          : "Version ${vramEstimate.info.version}"
                              "\n\n${vramEstimate.totalBytesForMod.bytesAsReadableMB()}"
                              "\n${vramEstimate.images.length} images"
                              "",
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: vramEstimate?.totalBytesForMod != null
                                    ? Text(
                                        vramEstimate!.totalBytesForMod
                                            .bytesAsReadableMB(),
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(color: lightTextColor))
                                    : Align(
                                        alignment: Alignment.centerRight,
                                        child: Opacity(
                                            opacity: 0.5,
                                            child: Disable(
                                              isEnabled: !vramEstimatorState
                                                  .isScanning,
                                              child: MovingTooltipWidget.text(
                                                message: "Estimate VRAM usage",
                                                child: IconButton(
                                                  icon:
                                                      const Icon(Icons.memory),
                                                  iconSize: 24,
                                                  onPressed: () {
                                                    ref
                                                        .read(AppState
                                                            .vramEstimatorProvider
                                                            .notifier)
                                                        .startEstimating(
                                                            smolIdsToCheck: [
                                                          mod.findFirstEnabledOrHighestVersion!
                                                              .smolId
                                                        ]);
                                                  },
                                                ),
                                              ),
                                            )),
                                      )),
                          ),
                          if (vramEstimate != null)
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ));
        }),
      ),
      PlutoColumn(
        title: 'Game Version',
        field: _Fields.gameVersion.toString(),
        minWidth: 120,
        type: PlutoColumnType.text(),
        // onSort: (columnIndex, ascending) => _onSort(
        //     columnIndex,
        //     (mod) =>
        //         mod.findFirstEnabledOrHighestVersion?.modInfo
        //             .gameVersion ??
        //         ""),
        renderer: (rendererContext) => Builder(builder: (context) {
          if (filteredMods.isEmpty) return const SizedBox();
          final mod = _getModFromKey(rendererContext.row.key);
          if (mod == null) return const SizedBox();
          final bestVersion = mod.findFirstEnabledOrHighestVersion;
          final theme = Theme.of(context);

          return ContextMenuRegion(
              contextMenu: buildModContextMenu(mod, ref, context,
                  showSwapToVersion: true),
              child: RowItemContainer(
                child: Opacity(
                  opacity: lightTextOpacity,
                  child: Text(rendererContext.cell.value ?? "(no game version)",
                      style: compareGameVersions(
                                  bestVersion?.modInfo.gameVersion,
                                  ref
                                      .watch(appSettings)
                                      .lastStarsectorVersion) ==
                              GameCompatibility.perfectMatch
                          ? theme.textTheme.labelLarge
                          : theme.textTheme.labelLarge?.copyWith(
                              color: ThemeManager.vanillaErrorColor)),
                ),
              ));
        }),
      ),
    ];
  }

  PlutoRow? createRow(Mod mod) {
    final bestVersion = mod.findFirstEnabledOrHighestVersion;
    if (bestVersion == null) return null;
    final enabledVersion = mod.findFirstEnabled;
    final modCompatibility =
        ref.watch(AppState.modCompatibility)[enabledVersion?.smolId];
    final vramEstimate = ref.watch(AppState.vramEstimatorProvider).modVramInfo;

    final satisfiableDependencies = modCompatibility?.dependencyChecks
            .orEmpty()
            .countWhere((e) => e.isCurrentlySatisfied != true) ??
        0;
    return PlutoRow(
      key: ValueKey(mod),
      height: satisfiableDependencies > 0
          ? _standardRowHeight +
              (_dependencyAddedRowHeight * satisfiableDependencies)
          : null,
      cells: {
        _Fields.enableDisable.toString(): PlutoCell(
          value: mod.hasEnabledVariant ? 'Enabled' : 'Disabled',
        ),
        // Enable/Disable
        _Fields.versionSelector.toString(): PlutoCell(value: mod),

        // Utility/Total Conversion icon
        _Fields.utilityIcon.toString(): PlutoCell(
          value: bestVersion.modInfo.isUtility
              ? 1
              : bestVersion.modInfo.isTotalConversion
                  ? 2
                  : 0,
        ),
        // Icon
        _Fields.modIcon.toString(): PlutoCell(
          value: bestVersion.iconFilePath,
        ),
        // Name
        _Fields.name.toString(): PlutoCell(
          value: bestVersion.modInfo.name,
        ),
        _Fields.author.toString(): PlutoCell(
          value: mod.findFirstEnabledOrHighestVersion?.modInfo.author,
        ),
        _Fields.versions.toString(): PlutoCell(
          value: bestVersion.modInfo.version?.raw,
        ),
        _Fields.vramEstimate.toString(): PlutoCell(
          value: vramEstimate[mod.id]?.totalBytesForMod,
        ),
        _Fields.gameVersion.toString(): PlutoCell(
          value: bestVersion.modInfo.gameVersion,
        ),
      },
    );
  }

  Padding showCompatibilityErrorMessage(
      DependencyCheck? dependencies, String? gameVersion, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Builder(builder: (context) {
        return Text(
          dependencies?.gameCompatibility == GameCompatibility.incompatible
              ? "Incompatible with ${gameVersion ?? "game version"}."
              : dependencies?.dependencyChecks
                      .where((e) => e.satisfiedAmount is! Satisfied)
                      .map((e) => switch (e.satisfiedAmount) {
                            Satisfied _ => null,
                            Missing _ =>
                              "${e.dependency.formattedNameVersion} is missing.",
                            Disabled _ => null,
                            VersionInvalid _ =>
                              "Missing version ${e.dependency.version} of ${e.dependency.nameOrId}.",
                            VersionWarning version =>
                              "${e.dependency.nameOrId} version ${e.dependency.version} is wanted but ${version.modVariant!.bestVersion} may work.",
                          })
                      .join(" • ") ??
                  "",
          style: theme.textTheme.labelMedium?.copyWith(
              color: dependencies?.gameCompatibility ==
                      GameCompatibility.incompatible
                  ? ThemeManager.vanillaErrorColor
                  : getTopDependencySeverity(
                          dependencies?.dependencyStates ?? [], gameVersion,
                          sortLeastSevere: false)
                      .getDependencySatisfiedColor()),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        );
      }),
    );
  }
}

class FilterModsSearchBar extends StatelessWidget {
  const FilterModsSearchBar({
    super.key,
    required this.searchController,
    required this.query,
    required this.ref,
  });

  final SearchController searchController;
  final String query;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      searchController: searchController,
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
            controller: controller,
            leading: const Icon(Icons.search),
            hintText: "Filter mods...",
            trailing: [
              query.isEmpty
                  ? Container()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        controller.clear();
                        ref.read(searchQuery.notifier).state = "";
                        // filteredMods =
                        //     filterMods(query);
                      },
                    )
            ],
            backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainer),
            onChanged: (value) {
              ref.read(searchQuery.notifier).state = value;
              // setState(() {
              //   query = value;
              //   filteredMods = filterMods(value);
              // });
            });
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        return [];
      },
    );
  }
}

class CopyModListButtonLarge extends StatelessWidget {
  const CopyModListButtonLarge({
    super.key,
    required this.mods,
    required this.enabledMods,
  });

  final List<Mod> mods;
  final List<Mod> enabledMods;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
        message: "Copy mod list to clipboard\n\nRight-click for ALL mods",
        child: Padding(
          padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
          child: GestureDetector(
            onSecondaryTap: () {
              copyModListToClipboardFromMods(mods, context);
            },
            child: OutlinedButton.icon(
              onPressed: () =>
                  copyModListToClipboardFromMods(enabledMods, context),
              label: const Text("Copy"),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              icon: const Icon(
                Icons.copy,
                size: 20,
              ),
            ),
          ),
        ));
  }
}

class RowItemContainer extends StatelessWidget {
  final Widget child;

  const RowItemContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _standardRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [child],
            ),
          ),
        ),
      ],
    );
  }
}

enum _Fields {
  enableDisable,
  versionSelector,
  utilityIcon,
  modIcon,
  name,
  author,
  versions,
  vramEstimate,
  gameVersion,
}
