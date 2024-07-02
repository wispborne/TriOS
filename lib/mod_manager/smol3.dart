import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/mod_version_selection_dropdown.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../dashboard/mod_dependencies_widget.dart';
import '../dashboard/mod_list_basic.dart';
import '../dashboard/version_check_icon.dart';
import '../dashboard/version_check_text_readout.dart';
import '../models/mod.dart';
import '../trios/download_manager/download_manager.dart';
import '../widgets/mod_type_icon.dart';
import '../widgets/moving_tooltip.dart';
import '../widgets/tooltip_frame.dart';
import 'mod_summary_panel.dart';
import 'mods_grid_state.dart';

class Smol3 extends ConsumerStatefulWidget {
  const Smol3({super.key});

  @override
  ConsumerState createState() => _Smol3State();
}

typedef GridStateManagerCallback = Function(PlutoGridStateManager);

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

  // Map<String, VersionCheckResult>? versionCheckResults;
  PlutoGridStateManager? stateManager;
  List<PlutoColumn> gridColumns = [];
  List<PlutoRow> gridRows = [];
  final lightTextOpacity = 0.8;
  GridStateManagerCallback? didSetStateManager;

  tooltippy(Widget child, ModVariant modVariant) {
    final compatWithGame = ref
        .read(AppState.modCompatibility)[modVariant.smolId]
        ?.gameCompatibility;

    return MovingTooltipWidget(
      tooltipWidget: SizedBox(
        width: 400,
        child: TooltipFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModDependenciesWidget(
                modVariant: modVariant,
                compatWithGame: compatWithGame,
                compatTextColor: compatWithGame?.getGameCompatibilityColor(),
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

    final mods = ref.watch(AppState.mods);
    final versionCheckResults =
        ref.watch(AppState.versionCheckResults).valueOrNull;
    modsToDisplay = mods;
    final enabledMods =
        modsToDisplay.where((mod) => mod.isEnabledInGame).toList();
    final disabledMods =
        modsToDisplay.where((mod) => !mod.isEnabledInGame).toList();

    const double versionSelectorWidth = 130;
    if (stateManager != null) {
      stateManager.refRows.clearFromOriginal();
      stateManager.refRows.addAll(createGridRows(enabledMods, disabledMods));
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
        if (gridState?.isGroupEnabledExpanded !=
            stateManager
                .isExpandedGroupedRow(_getEnabledGroupRow(stateManager))) {
          stateManager.toggleExpandedRowGroup(
              rowGroup: _getEnabledGroupRow(stateManager));
        }
        if (gridState?.isGroupDisabledExpanded !=
            stateManager
                .isExpandedGroupedRow(_getDisabledGroupRow(stateManager))) {
          stateManager.toggleExpandedRowGroup(
              rowGroup: _getDisabledGroupRow(stateManager));
        }
        stateManager.setCurrentCell(stateManager.firstCell, selectedRowIdx);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(0),
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
                    scrollbar: const PlutoGridScrollbarConfig(dragDevices: {
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.touch,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.invertedStylus
                    }),
                    style: PlutoGridStyleConfig.dark(
                      iconSize: 16,
                      enableCellBorderHorizontal: false,
                      enableCellBorderVertical: false,
                      activatedBorderColor: Colors.transparent,
                      inactivatedBorderColor: Colors.transparent,
                      menuBackgroundColor: theme.colorScheme.surface,
                      gridBackgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      rowColor: Colors.transparent,
                      borderColor: Colors.transparent,
                      cellColorInReadOnlyState: Colors.transparent,
                      gridBorderColor: Colors.transparent,
                      checkedColor: Colors.transparent,
                      activatedColor:
                          theme.colorScheme.onSurface.withOpacity(0.1),
                      evenRowColor: theme.colorScheme.surface.withOpacity(0.4),
                      defaultCellPadding: EdgeInsets.zero,
                      defaultColumnFilterPadding: EdgeInsets.zero,
                      defaultColumnTitlePadding: EdgeInsets.zero,
                      rowHeight: 40,
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
                        child: hasEverLoaded
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
    );
  }

  void _toggleRowGroup(PlutoGridStateManager stateManager, PlutoRow row) {
    final isEnabledRow =
        row.cells[_Fields.enableDisable.toString()]?.value == 'Enabled';
    final isDisabledRow =
        row.cells[_Fields.enableDisable.toString()]?.value == 'Disabled';
    ref.read(appSettings.notifier).update((s) {
      if (isEnabledRow) {
        return s.copyWith(
            modsGridState: ModsGridState(
                isGroupEnabledExpanded:
                    !stateManager.isExpandedGroupedRow(row)));
      } else if (isDisabledRow) {
        return s.copyWith(
            modsGridState: ModsGridState(
                isGroupDisabledExpanded:
                    !stateManager.isExpandedGroupedRow(row)));
      }
      return s;
    });
  }

  PlutoRow _getEnabledGroupRow(PlutoGridStateManager stateManager) {
    return stateManager.rows.firstWhereOrNull((row) {
      return row.cells[_Fields.enableDisable.toString()]?.value == 'Enabled';
    })!;
  }

  PlutoRow _getDisabledGroupRow(PlutoGridStateManager stateManager) {
    return stateManager.rows.firstWhereOrNull((row) {
      return row.cells[_Fields.enableDisable.toString()]?.value == 'Disabled';
    })!;
  }

  Mod? _getModFromKey(Key? key) {
    return key is ValueKey<Mod> ? key.value : null;
  }

  List<PlutoRow> createGridRows(List<Mod> enabledMods, List<Mod> disabledMods) {
    // expanded: ref.read(appSettings.select((value) =>
    // value.modsGridState?.isGroupEnabledExpanded)) ??
    //     true

    return [
      ...enabledMods
          .mapIndexed((index, mod) => createRow(mod))
          .whereNotNull()
          .sortedBy<String>(
              // Default sort by name
              (e) => e.cells[_Fields.name.toString()]?.value.toString() ?? ""),
      ...disabledMods
          .mapIndexed((index, mod) => createRow(mod))
          .whereNotNull()
          .sortedBy<String>(
              // Default sort by name
              (e) => e.cells[_Fields.name.toString()]?.value.toString() ?? "")
    ]..toList();
    // return modsToDisplay
    //     .mapIndexed((index, mod) => createRow(mod))
    //     .whereNotNull()
    //     .sortedBy<String>(
    //         // Default sort by name
    //         (e) => e.cells[_Fields.name.toString()]?.value.toString() ?? "")
    //     .toList();
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
          if (modsToDisplay.isEmpty) return const SizedBox();
          if (rendererContext.row.depth > 0) return const SizedBox();
          final isEnabled =
              _getEnabledGroupRow(rendererContext.stateManager).key ==
                  rendererContext.row.key;
          return OverflowBox(
              maxWidth: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.only(left: 100),
                  child: Text(
                      (rendererContext.cell.value ?? "") +
                          " (${isEnabled ? enabledMods.length : disabledMods.length})",
                      overflow: TextOverflow.visible,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          )),
                ),
              ));
        }),
      ),
      PlutoColumn(
          title: '',
          // Version selector
          width: versionSelectorWidth + 20,
          field: _Fields.versionSelector.toString(),
          type: PlutoColumnType.text(),
          enableSorting: false,
          renderer: (rendererContext) => Builder(builder: (context) {
                if (modsToDisplay.isEmpty) return const SizedBox();
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
                    contextMenu:
                        ModListMini.buildContextMenu(mod, ref, context),
                    child: tooltippy(
                        ModVersionSelectionDropdown(
                            mod: mod,
                            width: versionSelectorWidth,
                            showTooltip: false),
                        bestVersion));
              })),
      PlutoColumn(
          title: '',
          // Utility/Total Conversion icon
          width: 40,
          field: _Fields.utilityIcon.toString(),
          type: PlutoColumnType.number(),
          renderer: (rendererContext) {
            if (modsToDisplay.isEmpty) return const SizedBox();
            final mod = _getModFromKey(rendererContext.row.key);
            if (mod == null) return const SizedBox();
            return ModTypeIcon(
                modVariant: mod.findFirstEnabledOrHighestVersion!);
          }),
      PlutoColumn(
        title: '',
        // Mod icon
        width: 43,
        field: _Fields.modIcon.toString(),
        type: PlutoColumnType.text(),
        enableSorting: false,
        renderer: (rendererContext) => Builder(builder: (context) {
          if (modsToDisplay.isEmpty) return const SizedBox();
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
          if (modsToDisplay.isEmpty) return const SizedBox();
          final mod = _getModFromKey(rendererContext.row.key);
          if (mod == null) return const SizedBox();
          final bestVersion = mod.findFirstEnabledOrHighestVersion;
          final theme = Theme.of(context);
          return ContextMenuRegion(
              contextMenu: ModListMini.buildContextMenu(mod, ref, context),
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
                  bestVersion!));
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
          if (modsToDisplay.isEmpty) return const SizedBox();
          final mod = _getModFromKey(rendererContext.row.key);
          if (mod == null) return const SizedBox();
          final theme = Theme.of(context);
          final lightTextColor =
              theme.colorScheme.onSurface.withOpacity(lightTextOpacity);
          return ContextMenuRegion(
              contextMenu: ModListMini.buildContextMenu(mod, ref, context),
              child: Text(rendererContext.cell.value ?? "(no author)",
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: lightTextColor)));
        }),
      ),
      PlutoColumn(
        title: 'Version(s)',
        field: _Fields.versions.toString(),
        type: PlutoColumnType.text(),
        renderer: (rendererContext) => Builder(builder: (context) {
          if (modsToDisplay.isEmpty) return const SizedBox();
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

          return
              // affixToTop(                      child:
              mod.modVariants.isEmpty
                  ? const Text("")
                  : Row(
                      children: [
                        MovingTooltipWidget(
                          tooltipWidget: SizedBox(
                            width: 500,
                            child: TooltipFrame(
                                child: VersionCheckTextReadout(
                                    versionCheckComparison,
                                    localVersionCheck,
                                    remoteVersionCheck,
                                    true)),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (remoteVersionCheck?.remoteVersion != null &&
                                  compareLocalAndRemoteVersions(
                                          localVersionCheck,
                                          remoteVersionCheck) ==
                                      -1) {
                                downloadUpdateViaBrowser(
                                    remoteVersionCheck!.remoteVersion!,
                                    ref,
                                    context,
                                    activateVariantOnComplete: true,
                                    modInfo: bestVersion.modInfo);
                              } else {
                                showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                            content: SelectionArea(
                                          child: VersionCheckTextReadout(
                                              versionCheckComparison,
                                              localVersionCheck,
                                              remoteVersionCheck,
                                              true),
                                        )));
                              }
                            },
                            onSecondaryTap: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                        content: SelectionArea(
                                      child: VersionCheckTextReadout(
                                          versionCheckComparison,
                                          localVersionCheck,
                                          remoteVersionCheck,
                                          true),
                                    ))),
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
        width: PlutoGridSettings.minColumnWidth,
        type: PlutoColumnType.number(),
        renderer: (rendererContext) => Builder(builder: (context) {
          if (modsToDisplay.isEmpty) return const SizedBox();
          final mod = _getModFromKey(rendererContext.row.key);
          if (mod == null) return const SizedBox();
          final theme = Theme.of(context);
          final lightTextColor =
              theme.colorScheme.onSurface.withOpacity(lightTextOpacity);
          final bestVersion = mod.findFirstEnabledOrHighestVersion;
          if (bestVersion == null) return const SizedBox();
          return ContextMenuRegion(
              contextMenu: ModListMini.buildContextMenu(mod, ref, context),
              child: Text("todo",
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: lightTextColor)));
        }),
      ),
      PlutoColumn(
        title: 'Req. Game Version',
        field: _Fields.gameVersion.toString(),
        type: PlutoColumnType.text(),
        // onSort: (columnIndex, ascending) => _onSort(
        //     columnIndex,
        //     (mod) =>
        //         mod.findFirstEnabledOrHighestVersion?.modInfo
        //             .gameVersion ??
        //         ""),
        renderer: (rendererContext) => Builder(builder: (context) {
          if (modsToDisplay.isEmpty) return const SizedBox();
          final mod = _getModFromKey(rendererContext.row.key);
          if (mod == null) return const SizedBox();
          final bestVersion = mod.findFirstEnabledOrHighestVersion;
          final theme = Theme.of(context);

          return ContextMenuRegion(
              contextMenu: ModListMini.buildContextMenu(mod, ref, context),
              child: Opacity(
                opacity: lightTextOpacity,
                child: Text(rendererContext.cell.value ?? "(no game version)",
                    style: compareGameVersions(bestVersion?.modInfo.gameVersion,
                                ref.watch(appSettings).lastStarsectorVersion) ==
                            GameCompatibility.perfectMatch
                        ? theme.textTheme.labelLarge
                        : theme.textTheme.labelLarge
                            ?.copyWith(color: vanillaErrorColor)),
              ));
        }),
      ),
    ];
  }

  PlutoRow? createRow(Mod mod) {
    final bestVersion = mod.findFirstEnabledOrHighestVersion;
    if (bestVersion == null) return null;

    return PlutoRow(
      key: ValueKey(mod),
      cells: {
        _Fields.enableDisable.toString(): PlutoCell(
          value: mod.isEnabledInGame ? 'Enabled' : 'Disabled',
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
            //     contextMenu: ModListMini.buildContextMenu(
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
                  ? vanillaErrorColor
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
