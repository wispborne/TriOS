import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/utils/extensions.dart';

part 'wisp_grid_state.mapper.dart';

@MappableClass()
class WispGridState with WispGridStateMappable {
  final ModGridSortField? sortField;
  final bool isSortDescending;
  final Map<ModGridHeader, ModGridColumnSetting> columnSettings;
  final GroupingSetting groupingSetting;

  const WispGridState({
    this.sortField = ModGridSortField.name,
    this.isSortDescending = false,
    this.columnSettings = const {
      ModGridHeader.favorites: ModGridColumnSetting(position: 0, width: 50),
      ModGridHeader.changeVariantButton:
          ModGridColumnSetting(position: 1, width: 130),
      ModGridHeader.icons: ModGridColumnSetting(position: 2, width: 25),
      ModGridHeader.modIcon: ModGridColumnSetting(position: 3, width: 32),
      ModGridHeader.name: ModGridColumnSetting(position: 4, width: 200),
      ModGridHeader.author: ModGridColumnSetting(position: 5, width: 200),
      ModGridHeader.version: ModGridColumnSetting(position: 6, width: 100),
      ModGridHeader.vramImpact: ModGridColumnSetting(position: 7, width: 110),
      ModGridHeader.gameVersion: ModGridColumnSetting(position: 8, width: 100),
      ModGridHeader.firstSeen: ModGridColumnSetting(position: 9, width: 100),
      ModGridHeader.lastEnabled: ModGridColumnSetting(position: 10, width: 100),
    },
    this.groupingSetting =
        const GroupingSetting(grouping: ModGridGroupEnum.enabledState),
  });

  List<MapEntry<ModGridHeader, ModGridColumnSetting>> get sortedColumns {
    return columnSettings.entries
        .sortedByButBetter((entry) => entry.value.position);
  }

  List<MapEntry<ModGridHeader, ModGridColumnSetting>> get sortedVisibleColumns {
    return sortedColumns.where((entry) => entry.value.isVisible).toList();
  }
}

@MappableClass()
class ModGridColumnSetting with ModGridColumnSettingMappable {
  final int position;
  final double width;
  final bool isVisible;

  const ModGridColumnSetting({
    required this.position,
    required this.width,
    this.isVisible = true,
  });
}

@MappableClass()
class GroupingSetting with GroupingSettingMappable {
  final ModGridGroupEnum grouping;
  final bool isSortDescending;

  const GroupingSetting({
    required this.grouping,
    this.isSortDescending = false,
  });
}

// TODO would be nice to make these generic, not tied to the Mod Grid
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

extension ModGridHeaderName on ModGridHeader {
  String get displayName {
    switch (this) {
      case ModGridHeader.favorites:
        return 'Favorite';
      case ModGridHeader.changeVariantButton:
        return 'Version Select';
      case ModGridHeader.icons:
        return 'Mod Type Icon';
      case ModGridHeader.modIcon:
        return 'Mod Icon';
      case ModGridHeader.name:
        return 'Name';
      case ModGridHeader.author:
        return 'Author';
      case ModGridHeader.version:
        return 'Version';
      case ModGridHeader.vramImpact:
        return 'VRAM Est.';
      case ModGridHeader.gameVersion:
        return 'Game Version';
      case ModGridHeader.firstSeen:
        return 'First Seen';
        case ModGridHeader.lastEnabled:
        return 'Last Enabled';
    }
  }
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
