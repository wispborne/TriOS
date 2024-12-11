import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/models/mod.dart';

sealed class ModGridGroup {
  String? getGroupName(Mod mod);

  Comparable? getGroupSortValue(Mod mod);
}

class EnabledStateModGridGroup extends ModGridGroup {
  @override
  String getGroupName(Mod mod) => mod.isEnabledOnUi ? 'Enabled' : 'Disabled';

  @override
  Comparable getGroupSortValue(Mod mod) => mod.isEnabledOnUi ? 0 : 1;
}

// class CategoryModGridGroup extends ModGridGroup {
//   final ModMetadataManager modMetadataManager;
//
//   CategoryModGridGroup(this.modMetadataManager);
//
//   @override
//   String getGroupName(Mod mod) =>
//       mod.metadata(modMetadataManager)?.category ?? 'No Category';
//
//   @override
//   Comparable getGroupSortValue(Mod mod) =>
//       mod.metadata(modMetadataManager)?.category?.toLowerCase() ??
//           'zzzzzzzzzzzzzzzzzzzz';
// }

class AuthorModGridGroup extends ModGridGroup {
  @override
  String getGroupName(Mod mod) =>
      mod.findFirstEnabledOrHighestVersion?.modInfo?.author ?? 'No Author';

  @override
  Comparable? getGroupSortValue(Mod mod) =>
      mod.findFirstEnabledOrHighestVersion?.modInfo?.author?.toLowerCase();
}

class ModTypeModGridGroup extends ModGridGroup {
  @override
  String getGroupName(Mod mod) {
    final modInfo = mod.findFirstEnabledOrHighestVersion?.modInfo;
    if (modInfo?.isUtility == true) {
      return 'Utility';
    } else if (modInfo?.isTotalConversion == true) {
      return 'Total Conversion';
    } else {
      return 'Other';
    }
  }

  @override
  Comparable getGroupSortValue(Mod mod) {
    final modInfo = mod.findFirstEnabledOrHighestVersion?.modInfo;
    if (modInfo?.isUtility == true) {
      return 'Utility';
    } else if (modInfo?.isTotalConversion == true) {
      return 'Total Conversion';
    } else {
      return 'zzzzzzzzz';
    }
  }
}

class GameVersionModGridGroup extends ModGridGroup {
  @override
  String getGroupName(Mod mod) =>
      mod.findFirstEnabledOrHighestVersion?.modInfo?.gameVersion ?? 'Unknown';

  @override
  Comparable getGroupSortValue(Mod mod) => getGroupName(mod).toLowerCase();
}

extension ModGridGroupEnumExtension on ModGridGroupEnum {
  ModGridGroup mapToGroup() => // TODO: ModMetadataManager modMetadataManager) =>
  switch (this) {
    ModGridGroupEnum.enabledState => EnabledStateModGridGroup(),
    ModGridGroupEnum.author => AuthorModGridGroup(),
    // ModGridGroupEnum.category => CategoryModGridGroup(modMetadataManager),
    ModGridGroupEnum.modType => ModTypeModGridGroup(),
    ModGridGroupEnum.gameVersion => GameVersionModGridGroup(),
  };
}