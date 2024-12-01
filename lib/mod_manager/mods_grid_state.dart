import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_manager/smol3.dart';
import 'package:trios/utils/dart_mappable_utils.dart';

part 'mods_grid_state.mapper.dart';

@MappableClass()
class ModsGridState with ModsGridStateMappable {
  @MappableField(hook: SafeDecodeHook(defaultValue: true))
  final bool isGroupEnabledExpanded;
  @MappableField(hook: SafeDecodeHook(defaultValue: true))
  final bool isGroupDisabledExpanded;
  @MappableField(hook: SafeDecodeHook())
  final ModsGridColumnState? sortedColumn;
  @MappableField(hook: SafeDecodeHook())
  final bool? sortAscending;
  @MappableField(hook: SafeDecodeHook())
  final List<ModsGridColumnState>? columns;

  ModsGridState({
    this.isGroupEnabledExpanded = true,
    this.isGroupDisabledExpanded = true,
    this.sortedColumn,
    this.sortAscending,
    this.columns,
  });
}

@MappableClass()
class ModsGridColumnState with ModsGridColumnStateMappable {
  SmolColumn column;
  bool? sortedAscending;
  double? width;
  double? width2;
  bool visible;

  ModsGridColumnState({
    required this.column,
    this.sortedAscending,
    this.width,
    this.visible = true,
  });
}
