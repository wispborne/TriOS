import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/mod_version_selection_dropdown.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../dashboard/mod_dependencies_widget.dart';
import '../dashboard/mod_list_basic.dart';
import '../dashboard/mod_summary_widget.dart';
import '../datatable3/data_table_3.dart';
import '../models/mod.dart';
import '../widgets/moving_tooltip.dart';
import '../widgets/tooltip_frame.dart';

class Smol2 extends ConsumerStatefulWidget {
  const Smol2({super.key});

  @override
  ConsumerState createState() => _Smol2State();
}

class _Smol2State extends ConsumerState<Smol2> {
  bool _sortAscending = true;
  int? _sortColumnIndex;
  List<Mod> Function(List<Mod>) sortFunction = (mods) => mods;

  List<Mod> _sortModsBy<T extends Comparable<T>>(
      List<Mod> mods, T Function(Mod) comparableGetter) {
    return _sortAscending
        ? mods.sortedBy<T>((mod) => comparableGetter(mod))
        : mods.sortedByDescending<T>((mod) => comparableGetter(mod));
  }

  _onSort<T extends Comparable<T>>(
      int columnIndex, T Function(Mod) comparableGetter) {
    setState(() {
      final isSameColumn = columnIndex == _sortColumnIndex;
      _sortColumnIndex = columnIndex;
      _sortAscending = isSameColumn ? !_sortAscending : true;
      sortFunction = (List<Mod> mods) => _sortModsBy(mods, comparableGetter);
    });
  }

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
  Widget build(BuildContext context) {
    final modsToDisplay = sortFunction(ref.watch(AppState.mods));
    const alternateRowColor = true;
    final enabledMods =
        ref.watch(AppState.enabledModsFile).value?.enabledMods ?? {};
    const double versionSelectorWidth = 150;
    final theme = Theme.of(context);
    const lightTextOpacity = 0.8;
    final lightTextColor =
        theme.colorScheme.onSurface.withOpacity(lightTextOpacity);

    return false
        ? Center(child: Image.asset("assets/images/construction.png"))
        : Padding(
            padding: const EdgeInsets.all(0),
            child: Theme(
              data: theme.copyWith(
                //disable ripple
                splashFactory: NoSplash.splashFactory,
              ),
              child: Column(
                children: [
                  Text(
                    "Warning: the Mods section is not finished. Use the Dashboard section for now.",
                    style: TextStyle(color: vanillaWarningColor),
                  ),
                  Expanded(
                    child: DataTable3(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 600,
                      showCheckboxColumn: false,
                      dividerThickness: 0,
                      headingTextStyle:
                          const TextStyle(fontWeight: FontWeight.bold),
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      sortArrowBuilder: (ascending, sorted) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: !sorted
                            ? Container()
                            : ascending
                                ? const Icon(Icons.arrow_upward, size: 14)
                                : const Icon(Icons.arrow_downward, size: 14),
                      ),
                      // onSelectAll: (selected) {},
                      columns: [
                        const DataColumn3(
                          label: Text(''), // Version selector
                          fixedWidth: versionSelectorWidth,
                        ),
                        const DataColumn3(
                          label: Text(''), // Utility/Total Conversion icon
                          fixedWidth: 35,
                        ),
                        const DataColumn3(
                          label: Text(''), // Mod icon
                          fixedWidth: 38,
                        ),
                        DataColumn3(
                          label: const Text('Name'),
                          onSort: (columnIndex, ascending) => _onSort(
                              columnIndex,
                              (mod) =>
                                  mod.findFirstEnabledOrHighestVersion?.modInfo
                                      .name ??
                                  ""),
                        ),
                        DataColumn3(
                          label: const Text('Author'),
                          onSort: (columnIndex, ascending) => _onSort(
                              columnIndex,
                              (mod) =>
                                  mod.findFirstEnabledOrHighestVersion?.modInfo
                                      .author ??
                                  ""),
                        ),
                        DataColumn3(
                          label: const Text('Version(s)'),
                          onSort: (columnIndex, ascending) => _onSort(
                              columnIndex,
                              (mod) => mod.modVariants
                                  .map((e) => e.modInfo.version)
                                  .join(", ")),
                        ),
                        const DataColumn3(
                          label: Text('VRAM Est.'),
                        ),
                        DataColumn3(
                          label: const Text('Req. Game Version'),
                          onSort: (columnIndex, ascending) => _onSort(
                              columnIndex,
                              (mod) =>
                                  mod.findFirstEnabledOrHighestVersion?.modInfo
                                      .gameVersion ??
                                  ""),
                        ),
                      ],
                      rows: modsToDisplay
                          .mapIndexed((index, mod) {
                            final bestVersion =
                                mod.findFirstEnabledOrHighestVersion;
                            final enabledVersion = mod.findFirstEnabled;
                            if (bestVersion == null) return null;
                            final gameVersion = ref.watch(appSettings.select(
                                (value) => value.lastStarsectorVersion));
                            final dependencies = ref.watch(
                                AppState.modCompatibility)[bestVersion.smolId];
                            final areDependenciesMet =
                                dependencies?.dependencyChecks.every((e) =>
                                            e.satisfiedAmount is Satisfied ||
                                            e.satisfiedAmount
                                                is VersionWarning) !=
                                        false &&
                                    dependencies?.gameCompatibility !=
                                        GameCompatibility.incompatible;

                            const rowHeight = kMinInteractiveDimension;
                            final extraRowHeight =
                                !areDependenciesMet ? 30.0 : 0.0;

                            Widget affixToTop({required Widget child}) => Align(
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    height: rowHeight,
                                    child: Center(child: child),
                                  ),
                                );

                            return DataRow3(
                              onSelectChanged: (selected) {
                                if (selected != null) {}
                              },
                              specificRowHeight: rowHeight + extraRowHeight,
                              color: (alternateRowColor && index.isEven
                                  ? WidgetStateProperty.all(theme
                                      .colorScheme.surface
                                      .withOpacity(0.4))
                                  : null),
                              cells: [
                                // Enable/Disable
                                DataCell3(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      affixToTop(
                                        child: ModVersionSelectionDropdown(
                                          mod: mod,
                                          width: versionSelectorWidth,
                                        ),
                                      ),
                                      if (!areDependenciesMet)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4, top: 4),
                                          child: Builder(builder: (context) {
                                            return Text(
                                              dependencies?.gameCompatibility ==
                                                      GameCompatibility
                                                          .incompatible
                                                  ? "Incompatible with ${gameVersion ?? "game version"}."
                                                  : dependencies
                                                          ?.dependencyChecks
                                                          .where((e) =>
                                                              e.satisfiedAmount
                                                                  is! Satisfied)
                                                          .map((e) => switch (e
                                                                  .satisfiedAmount) {
                                                                Satisfied _ =>
                                                                  null,
                                                                Missing _ =>
                                                                  "${e.dependency.formattedNameVersion} is missing.",
                                                                Disabled _ =>
                                                                  "${e.dependency.formattedNameVersion} is disabled and will be enabled.",
                                                                VersionInvalid
                                                                  _ =>
                                                                  "Missing version ${e.dependency.version} of ${e.dependency.nameOrId}.",
                                                                VersionWarning
                                                                  version =>
                                                                  "${e.dependency.nameOrId} version ${e.dependency.version} is wanted but ${version.modVariant!.bestVersion} may work.",
                                                              })
                                                          .join(" • ") ??
                                                      "",
                                              style: theme.textTheme.labelMedium?.copyWith(
                                                  color: dependencies
                                                              ?.gameCompatibility ==
                                                          GameCompatibility
                                                              .incompatible
                                                      ? vanillaErrorColor
                                                      : getTopDependencySeverity(
                                                              dependencies
                                                                      ?.dependencyStates ??
                                                                  [],
                                                              sortLeastSevere:
                                                                  false)
                                                          .getDependencySatisfiedColor()),
                                              maxLines: 1,
                                              softWrap: false,
                                              overflow: TextOverflow.visible,
                                            );
                                          }),
                                        ),
                                    ],
                                  ),
                                  builder: (context, child) =>
                                      tooltippy(child, bestVersion),
                                ),
                                // Utility/Total Conversion icon
                                DataCell3(
                                  Tooltip(
                                    message: bestVersion
                                            .modInfo.isTotalConversion
                                        ? "Total Conversion mods should not be run with any other mods, except Utility mods, unless explicitly stated to be compatible."
                                        : bestVersion.modInfo.isUtility
                                            ? "Utility mods may be added to or removed from a save at will."
                                            : "",
                                    child: affixToTop(
                                      child: Opacity(
                                        opacity: 0.7,
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: bestVersion
                                                  .modInfo.isTotalConversion
                                              ? const SvgImageIcon(
                                                  "assets/images/icon-death-star.svg")
                                              : bestVersion.modInfo.isUtility
                                                  ? const SvgImageIcon(
                                                      "assets/images/icon-utility-mod.svg")
                                                  : Container(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  builder: (context, child) =>
                                      ContextMenuRegion(
                                          contextMenu:
                                              ModListMini.buildContextMenu(
                                                  mod, ref, context),
                                          child: child),
                                ),
                                // Icon
                                DataCell3(
                                  affixToTop(
                                    child: SizedBox(
                                      width: 30,
                                      child: bestVersion.iconFilePath == null
                                          ? Container()
                                          : Image.file(bestVersion.iconFilePath!
                                              .toFile()),
                                    ),
                                  ),
                                  builder: (context, child) =>
                                      ContextMenuRegion(
                                          contextMenu:
                                              ModListMini.buildContextMenu(
                                                  mod, ref, context),
                                          child: child),
                                ),
                                // Name
                                DataCell3(
                                  Text(
                                    bestVersion.modInfo.name ?? "(no name)",
                                    style: GoogleFonts.roboto(
                                      textStyle: theme.textTheme.labelLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  builder: (context, child) =>
                                      ContextMenuRegion(
                                          contextMenu:
                                              ModListMini.buildContextMenu(
                                                  mod, ref, context),
                                          child: tooltippy(
                                              affixToTop(child: child),
                                              bestVersion)),
                                ),
                                DataCell3(
                                  Text(
                                      bestVersion.modInfo.author ??
                                          "(no author)",
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(color: lightTextColor)),
                                  builder: (context, child) =>
                                      ContextMenuRegion(
                                          contextMenu:
                                              ModListMini.buildContextMenu(
                                                  mod, ref, context),
                                          child: affixToTop(child: child)),
                                ),
                                DataCell3(affixToTop(
                                  child: mod.modVariants.isEmpty
                                      ? const Text("")
                                      : RichText(
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
                                                    style: theme
                                                        .textTheme.labelLarge
                                                        ?.copyWith(
                                                            color:
                                                                lightTextColor), // Style for the comma
                                                  ),
                                                TextSpan(
                                                  text: mod.modVariants[i]
                                                      .modInfo.version
                                                      .toString(),
                                                  style: theme
                                                      .textTheme.labelLarge
                                                      ?.copyWith(
                                                          color: enabledVersion ==
                                                                  mod.modVariants[
                                                                      i]
                                                              ? null
                                                              : lightTextColor), // Style for the remaining items
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                )),
                                DataCell3(
                                  Text("todo",
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(color: lightTextColor)),
                                  builder: (context, child) =>
                                      ContextMenuRegion(
                                          contextMenu:
                                              ModListMini.buildContextMenu(
                                                  mod, ref, context),
                                          child: affixToTop(child: child)),
                                ),
                                DataCell3(
                                  Opacity(
                                    opacity: lightTextOpacity,
                                    child: Text(
                                        bestVersion.modInfo.gameVersion ??
                                            "(no game version)",
                                        style: compareGameVersions(
                                                    bestVersion
                                                        .modInfo.gameVersion,
                                                    ref
                                                        .watch(appSettings)
                                                        .lastStarsectorVersion) ==
                                                GameCompatibility.compatible
                                            ? theme.textTheme.labelLarge
                                            : theme.textTheme.labelLarge
                                                ?.copyWith(
                                                    color: vanillaErrorColor)),
                                  ),
                                  builder: (context, child) =>
                                      ContextMenuRegion(
                                          contextMenu:
                                              ModListMini.buildContextMenu(
                                                  mod, ref, context),
                                          child: affixToTop(child: child)),
                                ),
                              ],
                            );
                          })
                          .whereNotNull()
                          .toList(),
                      empty: Center(
                          child: Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
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
                              ))),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
