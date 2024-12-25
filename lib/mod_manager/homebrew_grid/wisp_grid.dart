import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_mod_group_row.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_mod_header_row_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_mod_row_view.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/vram_estimator.dart';

import '../../trios/mod_metadata.dart';

class WispGrid extends ConsumerStatefulWidget {
  static const gridRowSpacing = 8.0;
  static const lightTextOpacity = 0.8;
  final List<Mod?> mods;
  final Function(dynamic mod) onModRowSelected;

  const WispGrid(
      {super.key, required this.mods, required this.onModRowSelected});

  @override
  ConsumerState createState() => _WispGridState();
}

class _WispGridState extends ConsumerState<WispGrid> {
  Map<Object?, bool> collapseStates = {};
  final ScrollController _gridScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final vramEstState = ref.watch(AppState.vramEstimatorProvider);

    final gridState = ref.watch(appSettings.select((s) => s.modsGridState));
    final groupingSetting =
        GroupingSetting(grouping: ModGridGroupEnum.enabledState);

    final grouping =
        groupingSetting.grouping.mapToGroup(); // TODO (SL.modMetadata)
    final activeSortField = gridState.sortField ?? ModGridSortField.name;
    final metadata = ref.watch(AppState.modsMetadata.notifier);

    final mods = widget.mods.nonNulls
        // Sort by favorites first, then by the active sort field
        .sorted(
          (left, right) {
            final leftMetadata = metadata.getMergedModMetadata(left.id);
            final rightMetadata = metadata.getMergedModMetadata(right.id);
            final leftFavorited = leftMetadata?.isFavorited == true;
            final rightFavorited = rightMetadata?.isFavorited == true;

            if (leftFavorited != rightFavorited) {
              return leftFavorited ? -1 : 1;
            }

            final sortResult = _getSortValueForMod(
                        left, leftMetadata, activeSortField, vramEstState)
                    ?.compareTo(_getSortValueForMod(
                        right, rightMetadata, activeSortField, vramEstState)) ??
                0;
            return gridState.isSortDescending ? sortResult * -1 : sortResult;
          },
        )
        .groupBy((Mod mod) => grouping.getGroupSortValue(mod))
        .entries
        .let((entries) => groupingSetting.isSortDescending
            ? entries.sortedByDescending((entry) => entry.key)
            : entries.sortedByDescending((entry) => entry.key).reversed)
        .toList();

    bool isFirstGroup = true; // dumb but works

    final displayedMods =
        [SizedBox(height: 30, child: WispGridModHeaderRowView()) as Widget] +
            mods
                .flatMap((entry) {
                  final groupSortValue = entry.key;
                  final modsInGroup = entry.value;
                  final isCollapsed = collapseStates[groupSortValue] == true;
                  final groupName =
                      modsInGroup.firstOrNull?.let(grouping.getGroupName) ?? "";

                  final header = WispGridModGroupRowView(
                    groupName: groupName,
                    modsInGroup: modsInGroup,
                    isCollapsed: isCollapsed,
                    setCollapsed: (isCollapsed) {
                      setState(() {
                        collapseStates[groupSortValue] = isCollapsed;
                      });
                    },
                    isFirstGroupShown: isFirstGroup,
                  );
                  isFirstGroup = false;
                  final items = isCollapsed
                      ? []
                      : modsInGroup
                          .map((mod) => WispGridModRowView(
                                mod: mod,
                                onModRowSelected: widget.onModRowSelected,
                              ))
                          .toList();

                  return <Widget>[header, ...items];
                })
                .nonNulls
                .toList();

    // TODO smooth scrolling: https://github.com/dridino/smooth_list_view/blob/main/lib/smooth_list_view.dart
    return Scrollbar(
      controller: _gridScrollController,
      thumbVisibility: true,
      child: ListView.builder(
          itemCount: displayedMods.length,
          controller: _gridScrollController,
          itemBuilder: (context, index) {
            final item = displayedMods[index];

            if (item is WispGridModGroupRowView) {
              return item;
            }

            try {
              return item;
            } catch (e) {
              Fimber.v(() => 'Error in WispGrid: $e');
              return Text("Incoherent screaming");
            }
          }),
    );
  }
}

Comparable? _getSortValueForMod(Mod mod, ModMetadata? metadata,
    ModGridSortField sortField, VramEstimatorState vramEstimatorState) {
  return switch (sortField) {
    ModGridSortField.icons =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.isUtility == true
          ? "utility"
          : mod.findFirstEnabledOrHighestVersion?.modInfo.isTotalConversion ==
                  true
              ? "total conversion"
              : "other",
    ModGridSortField.name =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId,
    ModGridSortField.enabledState => mod.isEnabledOnUi.toComparable(),
    ModGridSortField.author =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.author?.toLowerCase() ?? "",
    ModGridSortField.version =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.version,
    ModGridSortField.vramImpact => vramEstimatorState
            .modVramInfo[mod.findHighestEnabledVersion?.smolId]
            ?.maxPossibleBytesForMod ??
        0,
    ModGridSortField.gameVersion =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.gameVersion,
    ModGridSortField.firstSeen => metadata?.firstSeen ?? 0,
    ModGridSortField.lastEnabled => metadata?.lastEnabled ?? 0,
  };
}
