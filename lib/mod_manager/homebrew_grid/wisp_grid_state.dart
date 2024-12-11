import 'package:dart_mappable/dart_mappable.dart';

part 'wisp_grid_state.mapper.dart';

@MappableClass()
class WispGridState with WispGridStateMappable {
  final String? sortField;
  final bool isSortDescending;
  final Map<ModGridHeader, ModGridColumnSetting>? columnSettings;
  final GroupingSetting? groupingSetting;

  WispGridState({
    this.sortField,
    this.isSortDescending = true,
    this.columnSettings,
    this.groupingSetting,
  });
}

@MappableClass()
class ModGridColumnSetting with ModGridColumnSettingMappable {
  final int position;
  double? width;
  final bool isVisible;

  ModGridColumnSetting({
    required this.position,
    this.width,
    this.isVisible = true,
  });
}

@MappableClass()
class GroupingSetting with GroupingSettingMappable {
  final ModGridGroupEnum grouping;
  final bool isSortDescending;

  GroupingSetting({
    required this.grouping,
    this.isSortDescending = false,
  });
}

// TODO would be nice to make these generic, not tied to the Mod Grid
enum ModGridHeader {
  favorites,
  changeVariantButton,
  name,
  author,
  version,
  vramImpact,
  icons,
  gameVersion,
  // category
}

enum ModGridGroupEnum {
  enabledState,
  author,
  // category,
  modType,
  gameVersion,
}

enum ModGridSortField {
  enabledState,
  name,
  author,
  version,
  vramImpact,
  gameVersion,
  // category
}
