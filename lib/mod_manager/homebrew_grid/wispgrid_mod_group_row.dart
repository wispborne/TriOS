import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/tooltip_frame.dart';

import '../../vram_estimator/graphics_lib_config_provider.dart';
import '../../vram_estimator/models/graphics_lib_config.dart';
import '../../vram_estimator/vram_checker_logic.dart';
import 'wisp_grid_state.dart';

class WispGridModGroupRowView extends ConsumerStatefulWidget {
  final String groupName;
  final List<Mod> modsInGroup;
  final bool isCollapsed;
  final bool isFirstGroupShown;
  final Function(bool isCollapsed) setCollapsed;

  const WispGridModGroupRowView({
    super.key,
    required this.groupName,
    required this.modsInGroup,
    required this.isCollapsed,
    required this.isFirstGroupShown,
    required this.setCollapsed,
  });

  @override
  ConsumerState createState() => _WispGridModRowState();
}

class _WispGridModRowState extends ConsumerState<WispGridModGroupRowView> {
  @override
  Widget build(BuildContext context) {
    final groupName = widget.groupName;
    final modsInGroup = widget.modsInGroup;
    final vramMap = ref.watch(AppState.vramEstimatorProvider).modVramInfo;
    final graphicsLibConfig = ref.watch(graphicsLibConfigProvider);
    final smolIds = modsInGroup.nonNulls
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
    final vramFromVanilla = widget.isFirstGroupShown
        ? VramChecker.VANILLA_GAME_VRAM_USAGE_IN_BYTES
        : null;

    // Calculate the offset of the VRAM column
    final gridState = ref.watch(modGridStateProvider);
    final cellWidthBeforeVramColumn = gridState.columnSettings.entries
        .sortedBy<num>((entry) => entry.value.position)
        .takeWhile((element) => element.key != ModGridHeader.vramImpact)
        .map((e) => e.value.width + WispGrid.gridRowSpacing)
        .sum;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          onTap: () {
            widget.setCollapsed(!widget.isCollapsed);
          },
          // no ripple
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Stack(
              alignment: Alignment.centerLeft,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Icon(
                        widget.isCollapsed
                            ? Icons.keyboard_arrow_right
                            : Icons.keyboard_arrow_down,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text("${groupName ?? ""} (${modsInGroup.length})",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: ThemeManager.orbitron,
                              fontWeight: FontWeight.bold,
                            )),
                  ],
                ),
                Positioned(
                  // Subtract padding added to group that isn't present on the mod row
                  left: cellWidthBeforeVramColumn - 20,
                  child: Padding(
                      padding: EdgeInsets.only(right: 8, left: 0),
                      child: MovingTooltipWidget(
                        tooltipWidget: TooltipFrame(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // bold
                            Text("Estimated VRAM use by ${groupName} mods\n",
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
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                            if (graphicsLibConfig != null &&
                                graphicsLibConfig.areAnyEffectsEnabled)
                              Text(
                                  "Normal maps: ${graphicsLibConfig.areGfxLibNormalMapsEnabled ? "on" : "off"}"
                                  "\nMaterial maps: ${graphicsLibConfig.areGfxLibMaterialMapsEnabled ? "on" : "off"}"
                                  "\nSurface maps: ${graphicsLibConfig.areGfxLibSurfaceMapsEnabled ? "on" : "off"}",
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                            Text(
                                "\n${vramModsNoGraphicsLib.bytesAsReadableMB()} added by mods (${allEstimates.map((e) => e.images.length).sum} images)"
                                "${vramFromGraphicsLib.sum() > 0 ? "\n${vramFromGraphicsLib.sum().bytesAsReadableMB()} added by your GraphicsLib settings (${vramFromGraphicsLib.length} images)" : ""}"
                                "${vramFromVanilla != null ? "\n${vramFromVanilla.bytesAsReadableMB()} added by vanilla" : ""}"
                                "\n---"
                                "\n${(vramModsNoGraphicsLib + vramFromGraphicsLib.sum() + (vramFromVanilla ?? 0.0)).bytesAsReadableMB()} total",
                                style: Theme.of(context).textTheme.labelLarge)
                          ],
                        )),
                        child: Center(
                          child: Opacity(
                            opacity: WispGrid.lightTextOpacity,
                            child: Text(
                              "∑ ${(vramModsNoGraphicsLib + vramFromGraphicsLib.sum() + (vramFromVanilla ?? 0.0)).bytesAsReadableMB()}",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(),
                            ),
                          ),
                        ),
                      )),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
