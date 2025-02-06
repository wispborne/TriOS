import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';

part 'wisp_grid_state.mapper.dart';

@MappableClass()
class WispGridColumn<T extends WispGridItem> with WispGridColumnMappable {
  final String key;
  final String name;
  final bool isSortable;
  final Comparable? Function(T item)? getSortValue;
  final Widget Function(HeaderBuilderModifiers modifiers)? headerCellBuilder;
  final Widget Function(T item, CellBuilderModifiers modifiers)? itemCellBuilder;
  final WispGridColumnState defaultState;

  const WispGridColumn({
    required this.key,
    required this.name,
    required this.isSortable,
    this.getSortValue,
    this.headerCellBuilder,
    this.itemCellBuilder,
    required this.defaultState,
  }) : assert(!isSortable || getSortValue != null);
}

@MappableClass()
class HeaderBuilderModifiers with HeaderBuilderModifiersMappable {
  final bool isHovering;

  const HeaderBuilderModifiers({
    required this.isHovering,
  });
}

@MappableClass()
class CellBuilderModifiers with CellBuilderModifiersMappable {
  final bool isHovering;
  final bool isRowChecked;
  final WispGridColumnState columnState;

  const CellBuilderModifiers({
    required this.isHovering,
    required this.isRowChecked,
    required this.columnState,
  });
}

@MappableClass()
class RowBuilderModifiers with RowBuilderModifiersMappable {
  final bool isHovering;
  final bool isRowChecked;

  const RowBuilderModifiers({
    required this.isHovering,
    required this.isRowChecked,
  });
}

@MappableClass()
class WispGridColumnState with WispGridColumnStateMappable {
  final int position;
  final double width;
  final bool isVisible;

  const WispGridColumnState({
    required this.position,
    required this.width,
    this.isVisible = true,
  });
}

/// Generic grid state for [WispGrid]
@MappableClass()
class WispGridState with WispGridStateMappable {
  final String? sortedColumnKey;
  final bool isSortDescending;
  final GroupingSetting? groupingSetting;
  final Map<String, WispGridColumnState> columnsState;

  const WispGridState({
    this.sortedColumnKey,
    this.isSortDescending = false,
    required this.columnsState,
    required this.groupingSetting,
  });

  /// Returns all columns in `columnSpecs` (the definitive list), merging
  /// any user-defined [WispGridColumnState] from [columnsState] onto the
  /// column's [defaultState], then sorting them by the final `position`.
  List<MapEntry<String, WispGridColumnState>> sortedColumns(
    List<WispGridColumn> columnSpecs,
  ) {
    final mergedStates = columnSpecs.map((spec) {
      // The user's override, if any
      final userState = columnsState[spec.key];
      // The column's default state
      final base = spec.defaultState;

      // Merge them: userState takes precedence if it exists
      final finalState = WispGridColumnState(
        position: userState?.position ?? base.position,
        width: userState?.width ?? base.width,
        isVisible: userState?.isVisible ?? base.isVisible,
      );

      return MapEntry(spec.key, finalState);
    }).toList();

    // Sort by final position
    mergedStates.sort((a, b) => a.value.position.compareTo(b.value.position));
    return mergedStates;
  }

  /// Returns only the visible columns (i.e., `isVisible == true`)
  /// in sorted order.
  List<MapEntry<String, WispGridColumnState>> sortedVisibleColumns(
    List<WispGridColumn> columnSpecs,
  ) {
    return sortedColumns(columnSpecs)
        .where((entry) => entry.value.isVisible)
        .toList();
  }

  // WispGridState empty() =>
  //     const WispGridState(groupingSetting: null, columnsState: {});
}

@MappableClass()
class GroupingSetting with GroupingSettingMappable {
  final String currentGroupedByKey;
  final bool isSortDescending;

  const GroupingSetting({
    required this.currentGroupedByKey,
    this.isSortDescending = false,
  });
}

///////// Things specific to the Mods tab
@MappableEnum()
enum ModGridHeader {
  favorites,
  changeVariantButton,
  icons,
  modIcon,
  name,
  author,
  version,
  vramImpact,
  gameVersion,
  firstSeen,
  lastEnabled,
  // category
}

@MappableEnum()
enum ModGridGroupEnum {
  enabledState,
  author,
  // category,
  modType,
  gameVersion,
}

@MappableEnum()
enum ModGridSortField {
  enabledState,
  icons,
  name,
  author,
  version,
  vramImpact,
  gameVersion,
  firstSeen,
  lastEnabled,
  // category
}

///////// Things specific to the Weapons tab
@MappableEnum()
enum WeaponGridHeader {
  weaponType,
  size,
  techManufacturer,
  primaryRoleStr,
  tier,
  damagePerShot,
  baseValue,
  range,
  damagePerSecond,
  emp,
  impact,
  turnRate,
  ops,
  ammo,
  ammoPerSec,
  reloadSize,
  energyPerShot,
  energyPerSecond,
  chargeup,
  chargedown,
  burstSize,
  burstDelay,
  minSpread,
  maxSpread,
  spreadPerShot,
  spreadDecayPerSec,
  beamSpeed,
  projSpeed,
  launchSpeed,
  flightTime,
  projHitpoints,
  autofireAccBonus,
  extraArcForAI,
  hints,
  tags,
  groupTag,
  speedStr,
  trackingStr,
  turnRateStr,
  accuracyStr,
  specClass,
}
