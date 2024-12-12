import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_mod_row_view.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/vram_estimator.dart';

// TODO make this absolute, not relative
part '../../generated/mod_manager/homebrew_grid/wisp_grid.g.dart';

part 'wisp_grid.mapper.dart';

@riverpod
WispGridState modGridState(Ref ref) {
  // TODO get from settings
  return WispGridState(
      groupingSetting:
          GroupingSetting(grouping: ModGridGroupEnum.enabledState));
}

class WispGrid extends ConsumerStatefulWidget {
  final List<Mod?> mods;

  const WispGrid({super.key, required this.mods});

  @override
  ConsumerState createState() => _WispGridState();
}

class _WispGridState extends ConsumerState<WispGrid> {
  Map<Object?, bool> collapseStates = {};

  @override
  Widget build(BuildContext context) {
    final vramEstState = ref.watch(AppState.vramEstimatorProvider);

    // todo: get from state
    final gridState = ref.watch(modGridStateProvider);
    final groupingSetting =
        GroupingSetting(grouping: ModGridGroupEnum.enabledState);

    final grouping =
        groupingSetting.grouping.mapToGroup(); // TODO (SL.modMetadata)
    final activeSortField = gridState.sortField?.let((field) => ModGridSortField
            .values
            .enumFromStringCaseInsensitive<ModGridSortField>(field)) ??
        ModGridSortField.name;

    final mods = widget.mods
        .whereNotNull()
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

    final displayedMods = mods
        .map((entry) {
          final modState = entry.key;
          final modsInGroup = entry.value;
          final isCollapsed = collapseStates[modState] == true;
          final groupName =
              modsInGroup.firstOrNull?.let(grouping.getGroupName) ?? "";
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
          return isCollapsed ? null : modsInGroup;
        })
        .whereNotNull()
        .toList();

    final flattenedList = displayedMods.expand((element) => element).toList();

    // TODO smooth scrolling: https://github.com/dridino/smooth_list_view/blob/main/lib/smooth_list_view.dart
    return ListView.builder(
        itemCount: flattenedList.length,
        itemBuilder: (context, index) {
          final mod = flattenedList[index];

          return WispGridModRowView(mod: mod);
        });
  }
}

@MappableClass()
class WispGridRow<T> with WispGridRowMappable {
  final T item;

  WispGridRow(this.item);
}

@MappableClass()
class WispGridModRow extends WispGridRow<Mod> with WispGridModRowMappable {
  WispGridModRow(super.mod);
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
