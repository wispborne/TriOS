import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:trios/dashboard/changelogs.dart';
import 'package:trios/dashboard/mod_list_basic_entry.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/mod_version_selection_dropdown.dart';
import 'package:trios/mod_manager/mods_grid_state.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/search.dart';
import 'package:trios/widgets/add_new_mods_button.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../dashboard/mod_dependencies_widget.dart';
import '../dashboard/version_check_icon.dart';
import '../models/mod.dart';
import '../trios/download_manager/download_manager.dart';
import '../widgets/mod_type_icon.dart';
import '../widgets/moving_tooltip.dart';
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

class _Smol3State extends ConsumerState<Smol3>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool hasEverLoaded = false;
  Mod? selectedMod;
  int? selectedRowIdx;
  late List<Mod> modsToDisplay;
  late List<Mod> filteredMods;
  final searchController = SearchController();

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
    modsToDisplay = ref.read(AppState.mods);
    filteredMods = modsToDisplay;
    final versionCheckResults =
        ref.read(AppState.versionCheckResults).valueOrNull;
    const double versionSelectorWidth = 130;
    gridColumns.addAll(createColumns(
        versionSelectorWidth, lightTextOpacity, versionCheckResults, [], []));
    gridRows.addAll(createGridRows([], []));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final stateManager = ref.watch(_stateManagerProvider);
    final gridState =
        ref.watch(appSettings.select((value) => value.modsGridState));

    ref.watch(appSettings.select((value) => value.lastStarsectorVersion));
    var modCompatibility = ref.watch(AppState.modCompatibility);
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
    if (stateManager != null) {
      stateManager.refRows.clearFromOriginal();
      stateManager.refRows.addAll(
          createGridRows(enabledMods, disabledMods, shouldSort: query.isEmpty));
      stateManager.refColumns.clearFromOriginal();
      stateManager.refColumns.addAll(createColumns(versionSelectorWidth,
          lightTextOpacity, versionCheckResults, enabledMods, disabledMods));
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

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: Card(
                    child: Padding(
                  padding: const EdgeInsets.only(left: 2, right: 8),
                  child: Stack(
                    children: [
                      const AddNewModsButton(
                        labelWidget: Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text("Add Mod(s)"),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 30,
                          width: 300,
                          child: SearchAnchor(
                            searchController: searchController,
                            builder: (BuildContext context,
                                SearchController controller) {
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
                                              ref
                                                  .read(searchQuery.notifier)
                                                  .state = "";
                                              // filteredMods =
                                              //     filterMods(query);
                                            },
                                          )
                                  ],
                                  backgroundColor: WidgetStateProperty.all(
                                      Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer),
                                  onChanged: (value) {
                                    ref.read(searchQuery.notifier).state =
                                        value;
                                    // setState(() {
                                    //   query = value;
                                    //   filteredMods = filterMods(value);
                                    // });
                                  });
                            },
                            suggestionsBuilder: (BuildContext context,
                                SearchController controller) {
                              return [];
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
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
                          // rowHeight: 40,
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
    Map<String, VersionCheckResult>? versionCheckResults,
    List<Mod> enabledMods,
    List<Mod> disabledMods,
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
                        fontFamily: 'Orbitron',
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
          renderer: (rendererContext) => Builder(builder: (context) {
                if (filteredMods.isEmpty) return const SizedBox();
                final mod = _getModFromKey(rendererContext.row.key);
                if (mod == null) return const SizedBox();
                final bestVersion = mod.findFirstEnabledOrHighestVersion;
                if (bestVersion == null) return Container();
                final gameVersion = ref.watch(
                    appSettings.select((value) => value.lastStarsectorVersion));
                final dependencies =
                    ref.watch(AppState.modCompatibility)[bestVersion.smolId];
                final areDependenciesMet = dependencies?.dependencyChecks.every(
                            (e) =>
                                e.satisfiedAmount is Satisfied ||
                                e.satisfiedAmount is VersionWarning ||
                                e.satisfiedAmount is Disabled) !=
                        false &&
                    dependencies?.gameCompatibility !=
                        GameCompatibility.incompatible;

                return ContextMenuRegion(
                    contextMenu: buildModContextMenu(mod, ref, context),
                    child: tooltippy(
                      ModVersionSelectionDropdown(
                          mod: mod,
                          width: versionSelectorWidth,
                          showTooltip: false),
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
            return ModTypeIcon(
                modVariant: mod.findFirstEnabledOrHighestVersion!);
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
              ? Image.file(
                  iconPath.toFile(),
                  width: 32,
                  height: 32,
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
          final bestVersion = mod.findFirstEnabledOrHighestVersion;
          final theme = Theme.of(context);
          return ContextMenuRegion(
              contextMenu: buildModContextMenu(mod, ref, context),
              child: tooltippy(
                // affixToTop( child:
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 600,
                  ),
                  child: Text(
                    rendererContext.cell.value ?? "(no name)",
                    style: GoogleFonts.roboto(
                      textStyle: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // )
                ),
                mod.modVariants,
              ));
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
              contextMenu: buildModContextMenu(mod, ref, context),
              child: Text(rendererContext.cell.value ?? "(no author)",
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: lightTextColor)));
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

          final localVersionCheck = mod.findHighestVersion?.versionCheckerInfo;
          final remoteVersionCheck =
              versionCheckResultsNew?[bestVersion.smolId];
          final versionCheckComparison = compareLocalAndRemoteVersions(
              localVersionCheck, remoteVersionCheck);
          final changelogUrl =
              Changelogs.getChangelogUrl(localVersionCheck, remoteVersionCheck);

          return
              // affixToTop(                      child:
              mod.modVariants.isEmpty
                  ? const Text("")
                  : Row(
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
                                                padding: const EdgeInsets.only(
                                                    right: 4),
                                                child: SvgImageIcon(
                                                  "assets/images/icon-bullhorn-variant.svg",
                                                  color:
                                                      theme.colorScheme.primary,
                                                  width: 20,
                                                  height: 20,
                                                ),
                                              ),
                                              Text(
                                                  "Click horn to see full changelog",
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
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
                                color: theme.iconTheme.color?.withOpacity(0.7),
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ),
                        MovingTooltipWidget(
                          tooltipWidget:
                              ModListBasicEntry.buildVersionCheckTextReadout(
                                  null,
                                  versionCheckComparison,
                                  localVersionCheck,
                                  remoteVersionCheck),
                          child: InkWell(
                            onTap: () {
                              if (remoteVersionCheck?.remoteVersion != null &&
                                  compareLocalAndRemoteVersions(
                                          localVersionCheck,
                                          remoteVersionCheck) ==
                                      -1) {
                                ref
                                    .read(downloadManager.notifier)
                                    .downloadUpdateViaBrowser(
                                        remoteVersionCheck!.remoteVersion!,
                                        context,
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
                                                versionCheckComparison)));
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
                                            versionCheckComparison))),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              child: VersionCheckIcon(
                                  localVersionCheck: localVersionCheck,
                                  remoteVersionCheck: remoteVersionCheck,
                                  versionCheckComparison:
                                      versionCheckComparison,
                                  theme: theme),
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
              contextMenu: buildModContextMenu(mod, ref, context),
              child: Text("todo",
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: lightTextColor)));
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
              contextMenu: buildModContextMenu(mod, ref, context),
              child: Opacity(
                opacity: lightTextOpacity,
                child: Text(rendererContext.cell.value ?? "(no game version)",
                    style: compareGameVersions(bestVersion?.modInfo.gameVersion,
                                ref.watch(appSettings).lastStarsectorVersion) ==
                            GameCompatibility.perfectMatch
                        ? theme.textTheme.labelLarge
                        : theme.textTheme.labelLarge
                            ?.copyWith(color: ThemeManager.vanillaErrorColor)),
              ));
        }),
      ),
    ];
  }

  PlutoRow? createRow(Mod mod) {
    final bestVersion = mod.findFirstEnabledOrHighestVersion;
    if (bestVersion == null) return null;
    final dependencies = ref.watch(AppState.modCompatibility)[bestVersion.smolId];
    final gameVersion =
        ref.watch(appSettings.select((value) => value.lastStarsectorVersion));

    return PlutoRow(
      key: ValueKey(mod),
      height: dependencies
                  ?.mostSevereDependency(gameVersion)
                  ?.isCurrentlySatisfied ==
              true
          ? null
          : 100,
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
            // Text("todo",
            //     style: theme.textTheme.labelLarge
            //         ?.copyWith(color: lightTextColor)),
            // builder: (context, child) => ContextMenuRegion(
            //     contextMenu: buildModContextMenu(
            //         mod, ref, context),
            //     child: affixToTop(child: child)),
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
