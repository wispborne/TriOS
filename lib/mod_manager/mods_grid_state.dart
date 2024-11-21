import 'package:dart_mappable/dart_mappable.dart';

part 'mods_grid_state.mapper.dart';

@MappableClass()
class ModsGridState with ModsGridStateMappable {
  final bool isGroupEnabledExpanded;
  final bool isGroupDisabledExpanded;

  ModsGridState({
    this.isGroupEnabledExpanded = true,
    this.isGroupDisabledExpanded = true,
  });
}
