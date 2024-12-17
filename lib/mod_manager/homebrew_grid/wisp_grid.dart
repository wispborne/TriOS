import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:easy_sticky_header/easy_sticky_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_mod_group_row.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_mod_header_row_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_mod_row_view.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/vram_estimator.dart';

// provider for grid state
final modGridStateProvider = StateProvider<WispGridState>((ref) {
  return WispGridState(
      groupingSetting:
          GroupingSetting(grouping: ModGridGroupEnum.enabledState));
});

class WispGrid extends ConsumerStatefulWidget {
  final List<Mod?> mods;
  final Function(dynamic mod) onModRowSelected;

  static const double versionSelectorWidth = 130;
  static const lightTextOpacity = 0.8;

  const WispGrid(
      {super.key, required this.mods, required this.onModRowSelected});

  @override
  ConsumerState createState() => _WispGridState();
}

class _WispGridState extends ConsumerState<WispGrid> {
  Map<Object?, bool> collapseStates = {};
  ScrollController _gridScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final vramEstState = ref.watch(AppState.vramEstimatorProvider);

    // todo: get from state
    final gridState = ref.watch(modGridStateProvider);
    final groupingSetting =
        GroupingSetting(grouping: ModGridGroupEnum.enabledState);

    final grouping =
        groupingSetting.grouping.mapToGroup(); // TODO (SL.modMetadata)
    final activeSortField = gridState.sortField ?? ModGridSortField.name;
    // ?.let((field) =>
    // ModGridSortField
    //     .values
    //     .enumFromStringCaseInsensitive<ModGridSortField>(field)) ??
    // ModGridSortField.name;

    final mods = widget.mods.nonNulls
        // TODO also sort by favorited, when we get there
        .sortedByButBetter(
          (mod) => _getSortValueForMod(mod, activeSortField, vramEstState),
          isAscending: !gridState.isSortDescending,
        )
        .groupBy((Mod mod) => grouping.getGroupSortValue(mod))
        .entries
        .let((entries) => groupingSetting.isSortDescending
            ? entries.sortedByDescending((entry) => entry.key)
            : entries.sortedByDescending((entry) => entry.key).reversed)
        .toList();

    bool isFirstGroup = true; // dumb but works

    final displayedMods = [WispGridModHeaderRowView() as Widget] +
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
              // sticky header logic here in SMOL, needs to be added somehow
              // stickyHeader {
              //     ModGridSectionHeader(
              //         contentPadding = contentPadding,
              //         isCollapsed = isCollapsed,
              //         setCollapsed = { collapseStates[modState] = it },
              //         groupName = groupName,
              //         modsInGroup = modsInGroup,
              //         vramPosition = vramPosition
              //     )
              // }
              // return isCollapsed ? null : modsInGroup;
            })
            .nonNulls
            .toList();

    // final flattenedList = displayedMods.expand((element) => element).toList();

    // TODO smooth scrolling: https://github.com/dridino/smooth_list_view/blob/main/lib/smooth_list_view.dart
    return StickyHeader(
      child: Scrollbar(
        controller: _gridScrollController,
        thumbVisibility: true,
        child: ListView.builder(
            itemCount: displayedMods.length,
            controller: _gridScrollController,
            itemBuilder: (context, index) {
              final item = displayedMods[index];

              if (item is WispGridModGroupRowView) {
                return StickyContainerWidget(
                  index: index,
                  child: item,
                );
                // return WispGridModHeaderRowView();
              }

              try {
                // final mod = displayedMods[index - 1]; // -1 for header
                return item; //WispGridModRowView(mod: mod);
              } catch (e) {
                Fimber.v(() => 'Error in WispGrid: $e');
                return Text("Incoherent screaming");
              }
            }),
      ),
    );
  }
}

Comparable? _getSortValueForMod(Mod mod, ModGridSortField sortField,
    VramEstimatorState vramEstimatorState) {
  return switch (sortField) {
    ModGridSortField.name =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId,
    ModGridSortField.enabledState => mod.isEnabledOnUi.toComparable(),
    ModGridSortField.author =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.author?.toLowerCase(),
    ModGridSortField.version =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.version,
    ModGridSortField.vramImpact => vramEstimatorState
        .modVramInfo[mod.findHighestEnabledVersion?.smolId]
        ?.maxPossibleBytesForMod,
    ModGridSortField.gameVersion =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.gameVersion,
  };
}
