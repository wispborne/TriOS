import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/mod_context_menu.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/graphics_lib_config_provider.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/vram_checker_logic.dart';
import 'package:trios/widgets/moving_tooltip.dart';

class OverlayWidgetData {
  final Widget child;
  final double left;

  const OverlayWidgetData({required this.child, required this.left});
}

abstract class WispGridGroup<T extends WispGridItem> {
  String key;
  String displayName;

  OverlayWidgetData? overlayWidget(
    BuildContext context,
    List<T> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<T>> columns, {
    double horizontalPaddingOffset = 0,
  }) => null;

  Widget wrapGroupWidget(
    BuildContext context,
    List<T> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<T>> columns, {
    required Widget child,
    List<ContextMenuEntry> additionalMenuEntries = const [],
  }) {
    if (additionalMenuEntries.isEmpty) return child;
    return ContextMenuRegion(
      contextMenu: ContextMenu(entries: additionalMenuEntries),
      child: child,
    );
  }

  WispGridGroup(this.key, this.displayName);

  String? getGroupName(T mod);

  Comparable? getGroupSortValue(T mod);

  /// Returns a color associated with the group that [mod] belongs to,
  /// or `null` if there is no color.
  Color? getGroupColor(T mod) => null;

  CategoryIcon? getGroupIcon(T mod) => null;

  bool isGroupVisible = true;
}

class UngroupedModGridGroup extends WispGridGroup<Mod> {
  UngroupedModGridGroup() : super('none', 'None');

  @override
  String getGroupName(Mod mod) => 'All Mods';

  @override
  Comparable getGroupSortValue(Mod mod) => 1;

  @override
  bool get isGroupVisible => false;
}

class EnabledStateModGridGroup extends WispGridGroup<Mod> {
  EnabledStateModGridGroup() : super('enabledState', 'Enabled');

  @override
  String getGroupName(Mod mod) => mod.isEnabledOnUi ? 'Enabled' : 'Disabled';

  @override
  Comparable getGroupSortValue(Mod mod) => mod.isEnabledOnUi ? 0 : 1;

  @override
  Widget wrapGroupWidget(
    BuildContext context,
    List<Mod> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<Mod>> columns, {
    required Widget child,
    List<ContextMenuEntry> additionalMenuEntries = const [],
  }) => ContextMenuRegion(
    contextMenu: ContextMenu(
      entries: [
        ...buildModBulkActionContextMenu(itemsInGroup, ref, context).entries,
        if (additionalMenuEntries.isNotEmpty) ...[
          const MenuDivider(),
          ...additionalMenuEntries,
        ],
      ],
    ),
    child: child,
  );

  @override
  OverlayWidgetData? overlayWidget(
    BuildContext context,
    List<Mod> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<Mod>> columns, {
    double horizontalPaddingOffset = 0,
  }) => _vramSummaryOverlayWidget(
    context,
    itemsInGroup,
    ref,
    shownIndex,
    columns,
    getGroupName(itemsInGroup.first),
    horizontalPaddingOffset: horizontalPaddingOffset,
  );
}

class CategoryModGridGroup extends WispGridGroup<Mod> {
  final WidgetRef ref;

  CategoryModGridGroup(this.ref) : super('category', 'Category');

  @override
  String getGroupName(Mod mod) {
    final store = ref.read(categoryManagerProvider).value;
    if (store == null) return 'Uncategorized';
    final assignments = store.modAssignments[mod.id] ?? [];
    final primary = assignments.firstWhereOrNull((a) => a.isPrimary);
    if (primary == null && assignments.isNotEmpty) {
      // Fallback to first assignment.
      final cat = store.categories.firstWhereOrNull(
        (c) => c.id == assignments.first.categoryId,
      );
      return cat?.name ?? 'Uncategorized';
    }
    if (primary == null) return 'Uncategorized';
    return store.categories
            .firstWhereOrNull((c) => c.id == primary.categoryId)
            ?.name ??
        'Uncategorized';
  }

  @override
  Comparable getGroupSortValue(Mod mod) {
    final name = getGroupName(mod);
    return name == 'Uncategorized' ? 'zzzzzzzzz' : name.toLowerCase();
  }

  @override
  Color? getGroupColor(Mod mod) {
    final store = ref.read(categoryManagerProvider).value;
    if (store == null) return null;
    final assignments = store.modAssignments[mod.id] ?? [];
    final primary = assignments.firstWhereOrNull((a) => a.isPrimary);
    final categoryId =
        primary?.categoryId ?? assignments.firstOrNull?.categoryId;
    if (categoryId == null) return null;
    return store.categories.firstWhereOrNull((c) => c.id == categoryId)?.color;
  }

  @override
  CategoryIcon? getGroupIcon(Mod mod) {
    final store = ref.read(categoryManagerProvider).value;
    if (store == null) return null;
    final assignments = store.modAssignments[mod.id] ?? [];
    final primary = assignments.firstWhereOrNull((a) => a.isPrimary);
    final categoryId =
        primary?.categoryId ?? assignments.firstOrNull?.categoryId;
    if (categoryId == null) return null;
    return store.categories.firstWhereOrNull((c) => c.id == categoryId)?.icon;
  }

  @override
  Widget wrapGroupWidget(
    BuildContext context,
    List<Mod> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<Mod>> columns, {
    required Widget child,
    List<ContextMenuEntry> additionalMenuEntries = const [],
  }) => ContextMenuRegion(
    contextMenu: ContextMenu(
      entries: [
        ...buildModBulkActionContextMenu(itemsInGroup, ref, context).entries,
        if (additionalMenuEntries.isNotEmpty) ...[
          const MenuDivider(),
          ...additionalMenuEntries,
        ],
      ],
    ),
    child: child,
  );

  @override
  OverlayWidgetData? overlayWidget(
    BuildContext context,
    List<Mod> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<Mod>> columns, {
    double horizontalPaddingOffset = 0,
  }) => _vramSummaryOverlayWidget(
    context,
    itemsInGroup,
    ref,
    shownIndex,
    columns,
    getGroupName(itemsInGroup.first),
    horizontalPaddingOffset: horizontalPaddingOffset,
  );
}

class AuthorModGridGroup extends WispGridGroup<Mod> {
  AuthorModGridGroup() : super('author', 'Author');

  @override
  String getGroupName(Mod mod) =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.author ?? 'No Author';

  @override
  Comparable? getGroupSortValue(Mod mod) =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.author?.toLowerCase();

  @override
  Widget wrapGroupWidget(
    BuildContext context,
    List<Mod> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<Mod>> columns, {
    required Widget child,
    List<ContextMenuEntry> additionalMenuEntries = const [],
  }) => ContextMenuRegion(
    contextMenu: ContextMenu(
      entries: [
        ...buildModBulkActionContextMenu(itemsInGroup, ref, context).entries,
        if (additionalMenuEntries.isNotEmpty) ...[
          const MenuDivider(),
          ...additionalMenuEntries,
        ],
      ],
    ),
    child: child,
  );

  @override
  OverlayWidgetData? overlayWidget(
    BuildContext context,
    List<Mod> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<Mod>> columns, {
    double horizontalPaddingOffset = 0,
  }) => _vramSummaryOverlayWidget(
    context,
    itemsInGroup,
    ref,
    shownIndex,
    columns,
    getGroupName(itemsInGroup.first),
    horizontalPaddingOffset: horizontalPaddingOffset,
  );
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

  @override
  Widget wrapGroupWidget(
    BuildContext context,
    List<Mod> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<Mod>> columns, {
    required Widget child,
    List<ContextMenuEntry> additionalMenuEntries = const [],
  }) => ContextMenuRegion(
    contextMenu: ContextMenu(
      entries: [
        ...buildModBulkActionContextMenu(itemsInGroup, ref, context).entries,
        if (additionalMenuEntries.isNotEmpty) ...[
          const MenuDivider(),
          ...additionalMenuEntries,
        ],
      ],
    ),
    child: child,
  );

  @override
  OverlayWidgetData? overlayWidget(
    BuildContext context,
    List<Mod> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<Mod>> columns, {
    double horizontalPaddingOffset = 0,
  }) => _vramSummaryOverlayWidget(
    context,
    itemsInGroup,
    ref,
    shownIndex,
    columns,
    getGroupName(itemsInGroup.first),
    horizontalPaddingOffset: horizontalPaddingOffset,
  );
}

class GameVersionModGridGroup extends WispGridGroup<Mod> {
  GameVersionModGridGroup() : super('gameVersion', 'Game Version');

  @override
  String getGroupName(Mod mod) =>
      mod.findFirstEnabledOrHighestVersion?.modInfo.gameVersion ?? 'Unknown';

  @override
  Comparable getGroupSortValue(Mod mod) => getGroupName(mod).toLowerCase();

  @override
  Widget wrapGroupWidget(
    BuildContext context,
    List<Mod> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<Mod>> columns, {
    required Widget child,
    List<ContextMenuEntry> additionalMenuEntries = const [],
  }) => ContextMenuRegion(
    contextMenu: ContextMenu(
      entries: [
        ...buildModBulkActionContextMenu(itemsInGroup, ref, context).entries,
        if (additionalMenuEntries.isNotEmpty) ...[
          const MenuDivider(),
          ...additionalMenuEntries,
        ],
      ],
    ),
    child: child,
  );

  @override
  OverlayWidgetData? overlayWidget(
    BuildContext context,
    List<Mod> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<Mod>> columns, {
    double horizontalPaddingOffset = 0,
  }) => _vramSummaryOverlayWidget(
    context,
    itemsInGroup,
    ref,
    shownIndex,
    columns,
    getGroupName(itemsInGroup.first),
    horizontalPaddingOffset: horizontalPaddingOffset,
  );
}

OverlayWidgetData? _vramSummaryOverlayWidget(
  BuildContext context,
  List<Mod> itemsInGroup,
  WidgetRef ref,
  int shownIndex,
  List<WispGridColumn<Mod>> columns,
  String groupName, {
  double horizontalPaddingOffset = 0,
}) {
  final vramProvider = ref.watch(AppState.vramEstimatorProvider);
  final vramMap = vramProvider.value?.modVramInfo ?? {};
  final graphicsLibConfig = ref.watch(graphicsLibConfigProvider);
  final variantsInGroup = itemsInGroup.nonNulls
      .map((e) => e.findFirstEnabledOrHighestVersion)
      .nonNulls
      .toList();
  final allEstimatesIncludingMissing = variantsInGroup.map(
    (e) => vramMap[e.smolId],
  );
  final allEstimates = allEstimatesIncludingMissing.nonNulls.toList();
  final vramModsNoGraphicsLib = allEstimates
      .map((e) => e.imagesNotIncludingGraphicsLib().sum())
      .sum;
  final isGraphicsLibPreloadingAll = graphicsLibConfig?.preloadAllMaps == true;
  final vramFromGraphicsLib = isGraphicsLibPreloadingAll
      ? allEstimates
            .expand(
              (mod) => List.generate(
                mod.images.length,
                (i) => ModImageView(i, mod.images),
              ),
            )
            .where(
              (view) =>
                  view.graphicsLibType != null &&
                  view.isUsedBasedOnGraphicsLibConfig(graphicsLibConfig),
            )
            .map((view) => view.bytesUsed)
            .toList()
      : [200000000];

  // TODO include vanilla graphicslib usage
  final vramFromVanilla = shownIndex == 0
      ? VramChecker.VANILLA_GAME_VRAM_USAGE_IN_BYTES
      : null;

  // Calculate the offset of the VRAM column
  final gridState = ref.watch(appSettings.select((s) => s.modsGridState));
  final cellWidthBeforeVramColumn = gridState.getWidthUpToColumn(
    ModGridHeader.vramImpact.name,
    columns,
  );

  return OverlayWidgetData(
    // Subtract padding added to group that isn't present on the mod row
    left:
        cellWidthBeforeVramColumn -
        6 +
        WispGrid.gridRowSpacing +
        horizontalPaddingOffset,
    child: Padding(
      padding: EdgeInsets.only(right: 8, left: 0),
      child: MovingTooltipWidget.framed(
        tooltipWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // bold
            Text(
              "Estimated VRAM use by ${groupName.trim().split("\n").firstOrNull}\n",
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (graphicsLibConfig != null)
              Text(
                "GraphicsLib settings",
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            if (graphicsLibConfig != null)
              Text(
                "Enabled: ${graphicsLibConfig.areAnyEffectsEnabled ? "yes" : "no"}"
                "\nGenerate Normal maps: ${graphicsLibConfig.autoGenNormals ? "on" : "off"}"
                "\nPreload all: ${graphicsLibConfig.preloadAllMaps ? "on" : "off"}",
                style: Theme.of(context).textTheme.labelLarge,
              ),
            if (graphicsLibConfig != null &&
                graphicsLibConfig.areAnyEffectsEnabled)
              Text(
                "\nNormal maps: ${graphicsLibConfig.areGfxLibNormalMapsEnabled ? "on" : "off"}"
                "\nMaterial maps: ${graphicsLibConfig.areGfxLibMaterialMapsEnabled ? "on" : "off"}"
                "\nSurface maps: ${graphicsLibConfig.areGfxLibSurfaceMapsEnabled ? "on" : "off"}",
                style: Theme.of(context).textTheme.labelLarge,
              ),
            Text(
              "\n${vramModsNoGraphicsLib.bytesAsReadableMB()} added by mods (${allEstimates.map((e) => e.images.length).sum} images)"
              "${vramFromGraphicsLib.sum() > 0 ? "\n${vramFromGraphicsLib.sum().bytesAsReadableMB()} added by your GraphicsLib settings (${isGraphicsLibPreloadingAll ? "${vramFromGraphicsLib.length} images" : "roughly"})" : ""}"
              "${vramFromVanilla != null ? "\n${vramFromVanilla.bytesAsReadableMB()} added by vanilla" : ""}"
              "\n---"
              "\n${(vramModsNoGraphicsLib + vramFromGraphicsLib.sum() + (vramFromVanilla ?? 0.0)).bytesAsReadableMB()} total",
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        child: ContextMenuRegion(
          contextMenu: ContextMenu(
            entries: [
              MenuItem(
                label: '(Re)estimate VRAM Usage',
                icon: Icons.memory,
                onSelected: () {
                  ref
                      .read(AppState.vramEstimatorProvider.notifier)
                      .startEstimating(variantsToCheck: variantsInGroup);
                },
              ),
            ],
          ),
          child: Center(
            child: Opacity(
              opacity: WispGrid.lightTextOpacity,
              child: Row(
                crossAxisAlignment: .center,
                children: [
                  Text(
                    "∑ ${(vramModsNoGraphicsLib + vramFromGraphicsLib.sum() + (vramFromVanilla ?? 0.0)).bytesAsReadableMB()}",
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  if (allEstimatesIncludingMissing.contains(null))
                    Builder(
                      builder: (context) {
                        final variantsToCheck = variantsInGroup
                            .where((e) => vramMap[e.smolId] == null)
                            .toList();
                        return MovingTooltipWidget.text(
                          message:
                              "Estimate VRAM usage for ${variantsToCheck.length} unscanned mods",
                          child: IconButton(
                            icon: const Icon(Icons.memory),
                            iconSize: 20,
                            onPressed: () {
                              ref
                                  .read(AppState.vramEstimatorProvider.notifier)
                                  .startEstimating(
                                    variantsToCheck: variantsToCheck,
                                  );
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
