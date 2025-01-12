import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktx/collections.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_mod_group_row.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_mod_header_row_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_mod_row_view.dart';
import 'package:trios/mod_manager/mod_context_menu.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
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
  final Mod? selectedMod;

  const WispGrid(
      {super.key,
      required this.mods,
      required this.onModRowSelected,
      this.selectedMod});

  @override
  ConsumerState createState() => _WispGridState();
}

class _WispGridState extends ConsumerState<WispGrid> {
  final ScrollController _gridScrollControllerVertical = ScrollController();
  final ScrollController _gridScrollControllerHorizontal = ScrollController();
  final Map<Object?, bool> collapseStates = {};
  final Set<String> _checkedModIds = {};

  /// Used for shift-clicking to select a range.
  String? _lastCheckedModId;
  List<Mod> _lastDisplayedMods = [];

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
    _lastDisplayedMods = mods.flatMap((entry) => entry.value).toList();

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
                          .map((mod) => buildWrappedModRow(mod, context))
                          .toList();

                  return <Widget>[header, ...items];
                })
                .nonNulls
                .toList();
    final totalRowWidth = gridState.sortedVisibleColumns
        .map((e) => e.value.width + WispGrid.gridRowSpacing)
        .sum;

    // TODO smooth scrolling: https://github.com/dridino/smooth_list_view/blob/main/lib/smooth_list_view.dart
    return Scrollbar(
      controller: _gridScrollControllerHorizontal,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _gridScrollControllerHorizontal,
        child: SizedBox(
          width: gridState.sortedVisibleColumns
              .map((e) => e.value.width + WispGrid.gridRowSpacing + 10)
              .sum
              .coerceAtMost(MediaQuery.of(context).size.width * 1.3),
          child: Scrollbar(
            controller: _gridScrollControllerVertical,
            scrollbarOrientation: ScrollbarOrientation.left,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: displayedMods.length,
                  controller: _gridScrollControllerVertical,
                  itemBuilder: (context, index) {
                    final item = displayedMods[index];

                    if (item is WispGridModGroupRowView) {
                      return Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: SizedBox(width: totalRowWidth, child: item),
                          ),
                          Spacer(),
                        ],
                      );
                    }

                    try {
                      return item;
                    } catch (e) {
                      Fimber.v(() => 'Error in WispGrid: $e');
                      return Text("Incoherent screaming");
                    }
                  }),
            ),
          ),
        ),
      ),
    );
  }

  ContextMenuRegion buildWrappedModRow(Mod mod, BuildContext context) {
    // Disabling the click for mods panel functionality because
    // having the double-click introduces a delay on all single-clicks in the row,
    // and single-clicking for the side panel is too annoying.
    // TODO see if there's a way to stop the onDoubleTap from delaying single-clicks
    // on the version dropdown popup.
    final doubleClickForModsPanel = true;
    // ref.watch(appSettings.select((s) => s.doubleClickForModsPanel));

    return ContextMenuRegion(
      contextMenu: _checkedModIds.length > 1
          ? buildModBulkActionContextMenu(
              _lastDisplayedMods
                  .where((mod) => _checkedModIds.contains(mod.id))
                  .toList(),
              ref,
              context)
          : buildModContextMenu(mod, ref, context, showSwapToVersion: true),
      child: WispGridModRowView(
        mod: mod,
        onTapped: () {
          if (HardwareKeyboard.instance.isShiftPressed) {
            _onRowCheck(
              modId: mod.id,
              shiftPressed: true,
              ctrlPressed: false,
            );
          } else if (HardwareKeyboard.instance.isControlPressed) {
            _onRowCheck(
              modId: mod.id,
              shiftPressed: false,
              ctrlPressed: true,
            );
          } else {
            if (!doubleClickForModsPanel || widget.selectedMod != null) {
              widget.onModRowSelected(mod);
            }
            _onRowCheck(
              modId: mod.id,
              shiftPressed: false,
              ctrlPressed: false,
            );
          }
        },
        onDoubleTapped: () {
          if (doubleClickForModsPanel) {
            widget.onModRowSelected(mod);
          }
        },
        // onModRowSelected: widget.onModRowSelected,
        isRowChecked: _checkedModIds.contains(mod.id),
      ),
    );
  }

  /// Handles multi-check logic for shift/control-clicking a row.
  /// Updates the set of checked mod IDs and the last checked mod ID.
  /// - `modId` The unique identifier of the row that was clicked.
  /// - `shiftPressed` True if the Shift key was held during the click.
  /// - `ctrlPressed` True if the Control (or Command on macOS) key was held during the click.
  void _onRowCheck({
    required String modId,
    required bool shiftPressed,
    required bool ctrlPressed,
  }) {
    final orderedModIds = _lastDisplayedMods.map((mod) => mod.id).toList();

    setState(() {
      if (!shiftPressed && !ctrlPressed) {
        _checkedModIds.clear();
        _lastCheckedModId = modId;
        return;
      }

      if (shiftPressed && _lastCheckedModId != null) {
        final lastIndex = orderedModIds.indexOf(_lastCheckedModId!);
        final currentIndex = orderedModIds.indexOf(modId);

        if (lastIndex == -1 || currentIndex == -1) {
          _checkedModIds
            ..clear()
            ..add(modId);
          _lastCheckedModId = modId;
          return;
        }

        final start = lastIndex < currentIndex ? lastIndex : currentIndex;
        final end = lastIndex < currentIndex ? currentIndex : lastIndex;
        final selectedRange = orderedModIds.sublist(start, end + 1);
        final allSelected = selectedRange.every(_checkedModIds.contains);

        allSelected
            ? _checkedModIds.removeAll(selectedRange)
            : _checkedModIds.addAll(selectedRange);

        _lastCheckedModId = modId;
      } else if (ctrlPressed) {
        _checkedModIds.contains(modId)
            ? _checkedModIds.remove(modId)
            : _checkedModIds.add(modId);

        _lastCheckedModId = modId;
      }
    });
  }
}

Comparable? _getSortValueForMod(
    Mod mod,
    ModMetadata? metadata,
    ModGridSortField sortField,
    AsyncValue<VramEstimatorState> vramEstimatorStateProvider) {
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
    ModGridSortField.vramImpact => vramEstimatorStateProvider
            .valueOrNull
            ?.modVramInfo[mod.findHighestEnabledVersion?.smolId]
            ?.maxPossibleBytesForMod ??
        0,
    ModGridSortField.gameVersion =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.gameVersion,
    ModGridSortField.firstSeen => metadata?.firstSeen ?? 0,
    ModGridSortField.lastEnabled => metadata?.lastEnabled ?? 0,
  };
}
