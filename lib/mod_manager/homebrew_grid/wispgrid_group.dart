import 'package:trios/models/mod.dart';

abstract class WispGridGroup<T> {
  String key;
  String displayName;

  WispGridGroup(this.key, this.displayName);

  String? getGroupName(T mod);

  Comparable? getGroupSortValue(T mod);
}

class EnabledStateModGridGroup extends WispGridGroup<Mod> {
  EnabledStateModGridGroup() : super('enabledState', 'Enabled');

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

class AuthorModGridGroup extends WispGridGroup<Mod> {
  AuthorModGridGroup() : super('author', 'Author');

  @override
  String getGroupName(Mod mod) =>
      mod.findFirstEnabledOrHighestVersion?.modInfo?.author ?? 'No Author';

  @override
  Comparable? getGroupSortValue(Mod mod) =>
      mod.findFirstEnabledOrHighestVersion?.modInfo?.author?.toLowerCase();
}

class ModTypeModGridGroup extends WispGridGroup<Mod> {
  ModTypeModGridGroup() : super('modType', 'Mod Type');

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

class GameVersionModGridGroup extends WispGridGroup<Mod> {
  GameVersionModGridGroup() : super('gameVersion', 'Game Version');

  @override
  String getGroupName(Mod mod) =>
      mod.findFirstEnabledOrHighestVersion?.modInfo?.gameVersion ?? 'Unknown';

  @override
  Comparable getGroupSortValue(Mod mod) => getGroupName(mod).toLowerCase();
}
//
// extension ModGridGroupEnumExtension on ModGridGroupEnum {
//   WispGridGroup mapToGroup() =>
//       // TODO: ModMetadataManager modMetadataManager) =>
//       switch (this) {
//         ModGridGroupEnum.enabledState => EnabledStateModGridGroup(),
//         ModGridGroupEnum.author => AuthorModGridGroup(),
//         // ModGridGroupEnum.category => CategoryModGridGroup(modMetadataManager),
//         ModGridGroupEnum.modType => ModTypeModGridGroup(),
//         ModGridGroupEnum.gameVersion => GameVersionModGridGroup(),
//       };
// }
