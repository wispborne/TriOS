import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
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
import 'package:url_launcher/url_launcher.dart';

import '../dashboard/mod_dependencies_widget.dart';
import '../dashboard/mod_list_basic.dart';
import '../dashboard/version_check_icon.dart';
import '../dashboard/version_check_text_readout.dart';
import '../models/mod.dart';
import '../trios/constants.dart';
import '../trios/download_manager/download_manager.dart';
import '../widgets/mod_type_icon.dart';
import '../widgets/moving_tooltip.dart';
import '../widgets/tooltip_frame.dart';

class Smol3 extends ConsumerStatefulWidget {
  const Smol3({super.key});

  @override
  ConsumerState createState() => _Smol3State();
}

typedef GridStateManagerCallback = Function(PlutoGridStateManager);

final _stateManagerProvider =
    StateProvider.autoDispose<PlutoGridStateManager?>((ref) => null);

class _Smol3State extends ConsumerState<Smol3> {
  Mod? selectedMod;
  late List<Mod> modsToDisplay;

  // Map<String, VersionCheckResult>? versionCheckResults;
  PlutoGridStateManager? stateManager;
  List<PlutoColumn> gridColumns = [];
  List<PlutoRow> gridRows = [];
  final lightTextOpacity = 0.8;
  GridStateManagerCallback? didSetStateManager;
  bool _hasSorted = false;

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
        versionSelectorWidth, lightTextOpacity, versionCheckResults));
    gridRows.addAll(createGridRows());
    // ref.listenManual(AppState.versionCheckResults, (prev, newResults) {
    //   // setState(() {
    //   versionCheckResults = newResults.valueOrNull;
    //   gridColumns.clear();
    //   gridRows.clear();
    //   const double versionSelectorWidth = 130;
    //   gridColumns.addAll(
    //       createColumns(versionSelectorWidth, modsToDisplay, lightTextOpacity));
    //   gridRows.addAll(createGridRows());
    //   stateManager?.notifyListeners(true, Random().nextInt(1000));
    //   // });
    // });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateManager = ref.watch(_stateManagerProvider);

    ref.watch(appSettings.select((value) => value.lastStarsectorVersion));
    var modCompatibility = ref.watch(AppState.modCompatibility);

    final mods = ref.watch(AppState.mods);
    final versionCheckResults =
        ref.watch(AppState.versionCheckResults).valueOrNull;
    modsToDisplay = mods;
    const double versionSelectorWidth = 130;
    if (stateManager != null) {
      stateManager.refRows.clearFromOriginal();
      stateManager.refRows.addAll(createGridRows());
      stateManager.refColumns.clearFromOriginal();
      stateManager.refColumns.addAll(createColumns(
          versionSelectorWidth, lightTextOpacity, versionCheckResults));
      PlutoGridStateManager.initializeRows(
          stateManager.refColumns, stateManager.refRows);
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
                // key: UniqueKey(),
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
                        evenRowColor:
                            theme.colorScheme.surface.withOpacity(0.4),
                        defaultCellPadding: EdgeInsets.zero,
                        defaultColumnFilterPadding: EdgeInsets.zero,
                        defaultColumnTitlePadding: EdgeInsets.zero,
                        rowHeight: 40)),
                onLoaded: (PlutoGridOnLoadedEvent event) {
                  // stateManager = event.stateManager;
                  ref.read(_stateManagerProvider.notifier).state =
                      event.stateManager;
                  didSetStateManager?.call(event.stateManager);

                  // event.stateManager.setRowGroup(PlutoRowGroupTreeDelegate(
                  //   resolveColumnDepth: (column) =>
                  //       event.stateManager.columnIndex(column),
                  //   showText: (cell) => true,
                  //   showFirstExpandableIcon: true,
                  // ));
                },
                onSorted: (PlutoGridOnSortedEvent event) {
                  // _sortColumnIndex = event.sortColumnIdx;
                  // _sortAscending = event.sortAscending;
                },
                columns: gridColumns,
                // columns: gridColumns,
                rows: gridRows,
                // rows: gridRows,
                onSelected: (event) {
                  if (event.row != null) {
                    final mod = _getModFromKey(event.row?.key);

                    setState(() {
                      if (selectedMod == mod) {
                        selectedMod = null;
                      } else {
                        selectedMod = mod;
                      }
                    });
                  }
                },
                // columnSpacing: 12,
                // horizontalMargin: 12,
                // bottomMargin: 16,
                // minWidth: 600,
                // showCheckboxColumn: false,
                // dividerThickness: 0,
                // headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                // sortColumnIndex: _sortColumnIndex,
                // sortAscending: _sortAscending,
                // sortArrowBuilder: (ascending, sorted) => Padding(
                //   padding: const EdgeInsets.only(left: 8, top: 2),
                //   child: !sorted
                //       ? Container()
                //       : ascending
                //           ? const Icon(Icons.arrow_upward, size: 14)
                //           : const Icon(Icons.arrow_downward, size: 14),
                // ),
                // onSelectAll: (selected) {},
                noRowsWidget: Center(
                    child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.rotate(
                              angle: .50,
                              child: SvgImageIcon(
                                  "assets/images/icon-ice-cream.svg",
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  width: 150),
                            ),
                            const Text("mmm, vanilla")
                          ],
                        ))),
              );
            }),
            if (selectedMod != null)
              Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: 400,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      boxShadow: [
                        ThemeManager.boxShadow,
                      ],
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.15),
                          width: 1,
                        ),
                        left: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.15),
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Builder(builder: (context) {
                      final variant = selectedMod!.findHighestVersion;
                      final versionCheck = ref
                          .watch(AppState.versionCheckResults)
                          .valueOrNull?[variant?.smolId];
                      if (variant == null) return const SizedBox();
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              child: SelectionArea(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (variant.iconFilePath != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 16),
                                            child: Image.file(
                                                variant.iconFilePath!.toFile(),
                                                width: 48,
                                                height: 48),
                                          )
                                        else
                                          const SizedBox(width: 0, height: 48),
                                        Text(
                                            variant.modInfo.name ?? "(no name)",
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                                    fontFamily: "Orbitron",
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                        "${variant.modInfo.id} ${variant.modInfo.version}",
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                                fontFamily:
                                                    GoogleFonts.sourceCodePro()
                                                        .fontFamily)),
                                    const SizedBox(height: 4),
                                    Text(
                                        "Starsector ${variant.modInfo.gameVersion}",
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                                fontFamily:
                                                    GoogleFonts.sourceCodePro()
                                                        .fontFamily)),
                                    if (variant.modInfo.isUtility ||
                                        variant.modInfo.isTotalConversion)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Tooltip(
                                            message: ModTypeIcon.getTooltipText(
                                                variant),
                                            child: Row(
                                              children: [
                                                ModTypeIcon(
                                                    modVariant: variant),
                                                const SizedBox(width: 8),
                                                Text(
                                                  variant.modInfo
                                                          .isTotalConversion
                                                      ? "Total Conversion"
                                                      : variant
                                                              .modInfo.isUtility
                                                          ? "Utility Mod"
                                                          : "",
                                                ),
                                              ],
                                            ),
                                          )),
                                    if (variant.modInfo.author
                                        .isNotNullOrEmpty())
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          const Text("Author",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(variant.modInfo.author ??
                                              "(no author)"),
                                        ],
                                      ),
                                    if (variant.modInfo.description
                                        .isNotNullOrEmpty())
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          const Text("Description",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(variant.modInfo.description ??
                                              "(no description)"),
                                        ],
                                      ),
                                    if (versionCheck?.remoteVersion?.modThreadId
                                            .isNotNullOrEmpty() ??
                                        false)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          TextButton(
                                              child: const Text(
                                                "Forum Thread",
                                              ),
                                              onPressed: () {
                                                launchUrl(Uri.parse(
                                                    "${Constants.forumModPageUrl}${versionCheck?.remoteVersion?.modThreadId}"));
                                              }),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    selectedMod = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Mod _getModFromKey(Key? key) {
    return (key as ValueKey<Mod>).value;
  }

  List<PlutoRow> createGridRows() {
    // final enabledMods =
    //     modsToDisplay.where((mod) => mod.isEnabledInGame).toList();
    // final disabledMods =
    //     modsToDisplay.where((mod) => !mod.isEnabledInGame).toList();
    //
    // return [
    //   PlutoRow(
    //       cells: {_Fields.name.toString(): PlutoCell(value: modsToDisplay[0].findFirstEnabledOrHighestVersion!.modInfo.name),},
    //       type: PlutoRowType.group(
    //           children: FilteredList(
    //               initialList: enabledMods
    //                   .mapIndexed((index, mod) {
    //                     return createRow(mod);
    //                   })
    //                   .whereNotNull()
    //                   .sortedBy<String>(
    //                       // Default sort by name
    //                       (e) =>
    //                           e.cells[_Fields.name.toString()]?.value
    //                               .toString() ??
    //                           "")
    //                   .toList()))),
    //   ...disabledMods
    //       .mapIndexed((index, mod) {
    //         return createRow(mod);
    //       })
    //       .whereNotNull()
    //       .sortedBy<String>(
    //           // Default sort by name
    //           (e) => e.cells[_Fields.name.toString()]?.value.toString() ?? "")
    // ]..toList();
    return modsToDisplay
        .mapIndexed((index, mod) => createRow(mod))
        .whereNotNull()
        .sortedBy<String>(
            // Default sort by name
            (e) => e.cells[_Fields.name.toString()]?.value.toString() ?? "")
        .toList();
  }

  PlutoRow? createRow(Mod mod) {
    final bestVersion = mod.findFirstEnabledOrHighestVersion;
    if (bestVersion == null) return null;

    return PlutoRow(
      key: ValueKey(mod),
      cells: {
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

  List<PlutoColumn> createColumns(
      double versionSelectorWidth,
      double lightTextOpacity,
      Map<String, VersionCheckResult>? versionCheckResults) {
    return [
      PlutoColumn(
          title: '',
          // Version selector
          width: versionSelectorWidth + 20,
          field: _Fields.versionSelector.toString(),
          type: PlutoColumnType.text(),
          enableSorting: false,
          renderer: (rendererContext) => Builder(builder: (context) {
                if (modsToDisplay.isEmpty) return const SizedBox();
                Mod mod = rendererContext.cell.value;
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
            return ModTypeIcon(
                modVariant: _getModFromKey(rendererContext.row.key)
                    .findFirstEnabledOrHighestVersion!);
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
          Mod mod = _getModFromKey(rendererContext.row.key);
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
          Mod mod = _getModFromKey(rendererContext.row.key);
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
          Mod mod = _getModFromKey(rendererContext.row.key);
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
        // onSort: (columnIndex, ascending) => _onSort(
        //     columnIndex,
        //     (mod) => mod.modVariants
        //         .map((e) => e.modInfo.version)
        //         .join(", ")),
      ),
      PlutoColumn(
        title: 'VRAM Est.',
        field: _Fields.vramEstimate.toString(),
        width: PlutoGridSettings.minColumnWidth,
        type: PlutoColumnType.number(),
        renderer: (rendererContext) => Builder(builder: (context) {
          if (modsToDisplay.isEmpty) return const SizedBox();
          Mod mod = _getModFromKey(rendererContext.row.key);
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
          Mod mod = _getModFromKey(rendererContext.row.key);
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
  versionSelector,
  utilityIcon,
  modIcon,
  name,
  author,
  versions,
  vramEstimate,
  gameVersion,
}
