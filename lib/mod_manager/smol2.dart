import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/mod_version_selection_dropdown.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../datatable3/data_table_3.dart';
import '../models/mod.dart';

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

  @override
  Widget build(BuildContext context) {
    final modsToDisplay = sortFunction(ref.watch(AppState.mods));
    const alternateRowColor = false;
    final enabledMods =
        ref.watch(AppState.enabledMods).value?.enabledMods ?? {};
    const double versionSelectorWidth = 150;

    return !kDebugMode
        ? Center(child: Image.asset("assets/images/construction.png"))
        : Padding(
            padding: const EdgeInsets.all(0),
            child: Theme(
              data: Theme.of(context).copyWith(
                //disable ripple
                splashFactory: NoSplash.splashFactory,
              ),
              child: DataTable3(
                columnSpacing: 12,
                horizontalMargin: 12,
                minWidth: 600,
                showCheckboxColumn: true,
                dividerThickness: 0,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                  DataColumn3(
                    label: const Text(''), // Version selector
                    fixedWidth: versionSelectorWidth,
                  ),
                  const DataColumn3(
                    label: Text(''), // Utility/Total Conversion icon
                    fixedWidth: 30,
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
                    label: Text('Author'),
                    onSort: (columnIndex, ascending) => _onSort(
                        columnIndex,
                        (mod) =>
                            mod.findFirstEnabledOrHighestVersion?.modInfo
                                .author ??
                            ""),
                  ),
                  DataColumn3(
                    label: Text('Version(s)'),
                    onSort: (columnIndex, ascending) => _onSort(
                        columnIndex,
                        (mod) => mod.modVariants
                            .map((e) => e.modInfo.version)
                            .join(", ")),
                  ),
                  DataColumn3(
                    label: Text('VRAM Est.'),
                  ),
                  DataColumn3(
                    label: Text('Req. Game Version'),
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
                      final bestVersion = mod.findFirstEnabledOrHighestVersion;
                      if (bestVersion == null) return null;

                      return DataRow3(
                        onSelectChanged: (selected) {
                          if (selected != null) {}
                        },
                        cells: [
                          DataCell(
                            ModVersionSelectionDropdown(
                                mod: mod, width: versionSelectorWidth),
                          ),
                          DataCell(
                            Tooltip(
                              message: bestVersion.modInfo.isTotalConversion
                                  ? "Total Conversion mods should not be run with any other mods, except Utility mods, unless explicitly stated to be compatible."
                                  : bestVersion.modInfo.isUtility
                                      ? "Utility mods may be added to or removed from a save at will."
                                      : "",
                              child: Opacity(
                                opacity: 0.7,
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: bestVersion.modInfo.isTotalConversion
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
                          DataCell(
                            SizedBox(
                              width: 30,
                              child: bestVersion.iconFilePath == null
                                  ? Container()
                                  : Image.file(
                                      bestVersion.iconFilePath!.toFile()),
                            ),
                          ),
                          DataCell(Text(bestVersion.modInfo.name ?? "(no name)",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))),
                          DataCell(Text(
                              bestVersion.modInfo.author ?? "(no author)")),
                          DataCell(Text(mod.modVariants
                              .map((e) => e.modInfo.version)
                              .join(", "))),
                          const DataCell(
                              Opacity(opacity: 0.5, child: Text("todo"))),
                          DataCell(Text(
                              bestVersion.modInfo.gameVersion ??
                                  "(no game version)",
                              style: compareGameVersions(
                                          bestVersion.modInfo.gameVersion,
                                          ref
                                              .watch(appSettings)
                                              .lastStarsectorVersion) ==
                                      GameCompatibility.compatible
                                  ? const TextStyle()
                                  : const TextStyle(color: vanillaErrorColor))),
                        ],
                        color: (alternateRowColor && index.isEven
                            ? WidgetStateProperty.all(
                                Theme.of(context).highlightColor)
                            : null),
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  width: 150),
                            ),
                            const Text("mmm, vanilla")
                          ],
                        ))),
              ),
            ),
          );
    ;
  }
}