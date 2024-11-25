import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_manager/smol3.dart';

part 'mods_grid_state.mapper.dart';

@MappableClass()
class ModsGridState with ModsGridStateMappable {
  final bool isGroupEnabledExpanded;
  final bool isGroupDisabledExpanded;
  final SmolColumn? sortedColumn;
  final bool? sortAscending;
  final List<SmolColumn>? columnOrder;

  ModsGridState({
    this.isGroupEnabledExpanded = true,
    this.isGroupDisabledExpanded = true,
    this.sortedColumn,
    this.sortAscending,
    this.columnOrder,
  });
}
