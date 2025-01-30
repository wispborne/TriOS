import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/graphics_lib_config_provider.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/vram_checker_logic.dart';
import 'package:trios/widgets/moving_tooltip.dart';

abstract class WispGridGroup<T extends WispGridItem> {
  String key;
  String displayName;

  Widget? overlayWidget(BuildContext context, List<T> itemsInGroup,
          WidgetRef ref, int shownIndex, List<WispGridColumn<T>> columns) =>
      null;

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

  @override
  Widget? overlayWidget(BuildContext context, List<Mod> itemsInGroup,
      WidgetRef ref, int shownIndex, List<WispGridColumn<Mod>> columns) {
    return Builder(builder: (context) {
      final vramProvider = ref.watch(AppState.vramEstimatorProvider);
      final vramMap = vramProvider.valueOrNull?.modVramInfo ?? {};
      final graphicsLibConfig = ref.watch(graphicsLibConfigProvider);
      final smolIds = itemsInGroup.nonNulls
          .map((e) => e.findFirstEnabledOrHighestVersion)
          .nonNulls
          .toList();
      final allEstimates =
          smolIds.map((e) => vramMap[e.smolId]).nonNulls.toList();
      const disabledGraphicsLibConfig = GraphicsLibConfig.disabled;
      final vramModsNoGraphicsLib = allEstimates
          .map((e) => e.bytesUsingGraphicsLibConfig(disabledGraphicsLibConfig))
          .sum;
      final vramFromGraphicsLib = allEstimates
          .flatMap((e) => e.images.where((e) =>
              e.graphicsLibType != null &&
              e.isUsedBasedOnGraphicsLibConfig(graphicsLibConfig)))
          .map((e) => e.bytesUsed)
          .toList();
      // TODO include vanilla graphicslib usage
      final vramFromVanilla =
          shownIndex == 0 ? VramChecker.VANILLA_GAME_VRAM_USAGE_IN_BYTES : null;

      // Calculate the offset of the VRAM column
      final gridState = ref.watch(appSettings.select((s) => s.modsGridState));
      final cellWidthBeforeVramColumn = gridState
          .sortedVisibleColumns(columns)
          .takeWhile((element) => element.key != ModGridHeader.vramImpact.name)
          .map((e) => e.value.width + WispGrid.gridRowSpacing)
          .sum;

      return Positioned(
        // Subtract padding added to group that isn't present on the mod row
        left: cellWidthBeforeVramColumn - 20 + WispGrid.gridRowSpacing,
        child: Padding(
            padding: EdgeInsets.only(right: 8, left: 0),
            child: MovingTooltipWidget.framed(
              tooltipWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // bold
                  Text(
                      "Estimated VRAM use by ${getGroupName(itemsInGroup.first)} mods\n",
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (graphicsLibConfig != null)
                    Text("GraphicsLib settings",
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  if (graphicsLibConfig != null)
                    Text(
                        "Enabled: ${graphicsLibConfig.areAnyEffectsEnabled ? "yes" : "no"}",
                        style: Theme.of(context).textTheme.labelLarge),
                  if (graphicsLibConfig != null &&
                      graphicsLibConfig.areAnyEffectsEnabled)
                    Text(
                        "Normal maps: ${graphicsLibConfig.areGfxLibNormalMapsEnabled ? "on" : "off"}"
                        "\nMaterial maps: ${graphicsLibConfig.areGfxLibMaterialMapsEnabled ? "on" : "off"}"
                        "\nSurface maps: ${graphicsLibConfig.areGfxLibSurfaceMapsEnabled ? "on" : "off"}",
                        style: Theme.of(context).textTheme.labelLarge),
                  Text(
                      "\n${vramModsNoGraphicsLib.bytesAsReadableMB()} added by mods (${allEstimates.map((e) => e.images.length).sum} images)"
                      "${vramFromGraphicsLib.sum() > 0 ? "\n${vramFromGraphicsLib.sum().bytesAsReadableMB()} added by your GraphicsLib settings (${vramFromGraphicsLib.length} images)" : ""}"
                      "${vramFromVanilla != null ? "\n${vramFromVanilla.bytesAsReadableMB()} added by vanilla" : ""}"
                      "\n---"
                      "\n${(vramModsNoGraphicsLib + vramFromGraphicsLib.sum() + (vramFromVanilla ?? 0.0)).bytesAsReadableMB()} total",
                      style: Theme.of(context).textTheme.labelLarge)
                ],
              ),
              child: Center(
                child: Opacity(
                  opacity: WispGrid.lightTextOpacity,
                  child: Text(
                    "∑ ${(vramModsNoGraphicsLib + vramFromGraphicsLib.sum() + (vramFromVanilla ?? 0.0)).bytesAsReadableMB()}",
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(),
                  ),
                ),
              ),
            )),
      );
    });
  }
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