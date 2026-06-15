import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/mod_context_menu.dart';
import 'package:trios/mod_manager/mods_grid_page.dart' show vramColumnHovered;
import 'package:trios/mod_manager/widgets/category_context_menu.dart';
import 'package:trios/mod_manager/widgets/category_management_popup.dart';
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

void toggleShowModInAllCategories(WidgetRef ref) {
  final current = ref.read(appSettings).modsGridShowModInAllCategories;
  ref
      .read(appSettings.notifier)
      .update((s) => s.copyWith(modsGridShowModInAllCategories: !current));
}

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
    bool isSecondaryHeader = false,
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

  /// Whether rows in this grouping can be dragged to other groups.
  bool get supportsDragAndDrop => false;

  /// Called when items are dropped onto a group.
  /// [droppedItemKeys] are the keys of the dragged WispGridItems.
  /// [targetGroupItems] are the items currently in the target group.
  void onItemsDropped(
    List<String> droppedItemKeys,
    List<T> targetGroupItems,
    WidgetRef ref,
  ) {}

  /// Returns the label shown on the drag feedback badge.
  /// [draggedKeys] are the keys of the items being dragged.
  /// [allItems] is the full list of items so implementations can look up
  /// display names.
  String dragFeedbackLabel(List<String> draggedKeys, List<T> allItems) =>
      draggedKeys.length > 1
      ? '${draggedKeys.length} items'
      : draggedKeys.first;

  /// Returns the formatted label for the drag badge when hovering over a
  /// target group, or null to keep the idle label (e.g. when hovering the
  /// source group).
  String? dragHoverLabel(String targetGroupName, List<String> draggedKeys) =>
      targetGroupName;

  /// Identifier for drag operations to prevent cross-grid drops.
  String get dragDataType => key;

  /// Returns the display name for the group that [mod] belongs to.
  /// [groupSortValue] is needed for multi-group items to resolve the
  /// correct group identity.
  String? getGroupName(T mod, {Comparable? groupSortValue});

  Comparable? getGroupSortValue(T mod);

  /// Returns all group sort values for [mod]. Override to place an item
  /// in multiple groups (e.g. a mod assigned to several categories).
  /// Defaults to a single-element list from [getGroupSortValue].
  List<Comparable?> getAllGroupSortValues(T item) => [getGroupSortValue(item)];

  /// Returns a color associated with the group that [mod] belongs to,
  /// or `null` if there is no color.
  Color? getGroupColor(T mod, {Comparable? groupSortValue}) => null;

  CategoryIcon? getGroupIcon(T mod, {Comparable? groupSortValue}) => null;

  bool isGroupVisible = true;
}

class UngroupedModGridGroup extends WispGridGroup<Mod> {
  UngroupedModGridGroup() : super('none', 'None');

  @override
  String getGroupName(Mod mod, {Comparable? groupSortValue}) => 'All Mods';

  @override
  Comparable getGroupSortValue(Mod mod) => 1;

  @override
  bool get isGroupVisible => false;
}

class EnabledStateModGridGroup extends WispGridGroup<Mod> {
  EnabledStateModGridGroup() : super('enabledState', 'Enabled');

  @override
  String getGroupName(Mod mod, {Comparable? groupSortValue}) =>
      mod.isEnabledOnUi ? 'Enabled' : 'Disabled';

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
    bool isSecondaryHeader = false,
  }) => _vramSummaryOverlayWidget(
    context,
    itemsInGroup,
    ref,
    shownIndex,
    columns,
    getGroupName(itemsInGroup.first),
    horizontalPaddingOffset: horizontalPaddingOffset,
    isSecondaryHeader: isSecondaryHeader,
  );
}

class CategoryModGridGroup extends WispGridGroup<Mod> {
  /// Sort sentinel so "Uncategorized" always sorts last.
  static const String uncategorizedSortValue = 'zzzzzzzzz';

  final WidgetRef ref;

  CategoryModGridGroup(this.ref) : super('category', 'Category');

  @override
  bool get supportsDragAndDrop => true;

  @override
  String dragFeedbackLabel(List<String> draggedKeys, List<Mod> allItems) =>
      draggedKeys.length > 1
      ? 'Move ${draggedKeys.length} items to\u2026'
      : 'Move to\u2026';

  @override
  String? dragHoverLabel(String targetGroupName, List<String> draggedKeys) {
    // Suppress when hovering the first dragged mod's own primary category.
    final store = ref.read(categoryManagerProvider).value;
    if (store != null && draggedKeys.isNotEmpty) {
      final assignments = store.modAssignments[draggedKeys.first] ?? [];
      final primary = assignments.firstWhereOrNull((a) => a.isPrimary);
      final categoryId =
          primary?.categoryId ?? assignments.firstOrNull?.categoryId;
      final sourceName = categoryId == null
          ? 'Uncategorized'
          : store.categories
                    .firstWhereOrNull((c) => c.id == categoryId)
                    ?.name ??
                'Uncategorized';
      if (sourceName == targetGroupName) return null;
    }

    return draggedKeys.length > 1
        ? 'Move ${draggedKeys.length} items to $targetGroupName'
        : 'Move to $targetGroupName';
  }

  @override
  void onItemsDropped(
    List<String> droppedItemKeys,
    List<Mod> targetGroupItems,
    WidgetRef ref,
  ) {
    final store = ref.read(categoryManagerProvider).value;
    if (store == null) return;
    final notifier = ref.read(categoryManagerProvider.notifier);

    // Resolve target category from the first item in the target group.
    final targetCategory = targetGroupItems.isEmpty
        ? null
        : _getCategoryForGroup(targetGroupItems);

    notifier.moveModsToCategory(droppedItemKeys, targetCategory?.id);
  }

  @override
  String getGroupName(Mod mod, {Comparable? groupSortValue}) {
    // Multi-group items pass groupSortValue to resolve the correct group.
    if (groupSortValue != null) {
      return _categoryFromSortValue(groupSortValue)?.name ?? 'Uncategorized';
    }

    return ref
            .read(categoryManagerProvider.notifier)
            .getPrimaryCategory(mod.id)
            ?.name ??
        'Uncategorized';
  }

  static String _sortValueForName(String name) =>
      name == 'Uncategorized' ? uncategorizedSortValue : name.toLowerCase();

  @override
  Comparable getGroupSortValue(Mod mod) =>
      _sortValueForName(getGroupName(mod));

  @override
  List<Comparable?> getAllGroupSortValues(Mod item) {
    final showAll = ref.read(appSettings).modsGridShowModInAllCategories;
    if (!showAll) return [getGroupSortValue(item)];

    final notifier = ref.read(categoryManagerProvider.notifier);
    final categories = notifier.getCategoriesForMod(item.id);
    if (categories.length <= 1) return [getGroupSortValue(item)];

    return categories
        .map((cat) => _sortValueForName(cat.name))
        .toList();
  }

  /// Resolves a category from a group sort value (lowercase name).
  Category? _categoryFromSortValue(Comparable? sortValue) {
    if (sortValue == null || sortValue == uncategorizedSortValue) return null;
    final store = ref.read(categoryManagerProvider).value;
    if (store == null) return null;
    return store.categories.firstWhereOrNull(
      (c) => c.name.toLowerCase() == sortValue,
    );
  }

  @override
  Color? getGroupColor(Mod mod, {Comparable? groupSortValue}) {
    if (groupSortValue != null) {
      return _categoryFromSortValue(groupSortValue)?.color;
    }
    return ref
        .read(categoryManagerProvider.notifier)
        .getPrimaryCategory(mod.id)
        ?.color;
  }

  @override
  CategoryIcon? getGroupIcon(Mod mod, {Comparable? groupSortValue}) {
    if (groupSortValue != null) {
      return _categoryFromSortValue(groupSortValue)?.icon;
    }
    return ref
        .read(categoryManagerProvider.notifier)
        .getPrimaryCategory(mod.id)
        ?.icon;
  }

  /// Resolves the category for a group of mods (based on the first mod's primary assignment).
  Category? _getCategoryForGroup(List<Mod> itemsInGroup) {
    if (itemsInGroup.isEmpty) return null;
    return ref
        .read(categoryManagerProvider.notifier)
        .getPrimaryCategory(itemsInGroup.first.id);
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
  }) {
    final category = _getCategoryForGroup(itemsInGroup);
    final categoryEntries = category == null
        ? []
        : buildCategoryContextMenuEntries(
            context,
            ref,
            category,
            itemsInGroup.first,
          );

    return ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: [
          ...buildModBulkActionContextMenu(itemsInGroup, ref, context).entries,
          if (categoryEntries.isNotEmpty) ...[
            const MenuDivider(),
            ...categoryEntries,
            MenuDivider(),
            MenuItem(
              icon: ref.read(appSettings).modsGridShowModInAllCategories
                  ? Icons.check
                  : null,
              label: 'Repeat Mods In Each Category',
              onSelected: () => toggleShowModInAllCategories(ref),
            ),
            MenuItem(
              label: 'Manage Categories...',
              icon: Icons.settings,
              onSelected: () {
                showCategoryManagementPopup(context: context, ref: ref);
              },
            ),
          ],

          if (additionalMenuEntries.isNotEmpty) ...[
            const MenuDivider(),
            ...additionalMenuEntries,
          ],
        ],
      ),
      child: child,
    );
  }

  @override
  OverlayWidgetData? overlayWidget(
    BuildContext context,
    List<Mod> itemsInGroup,
    WidgetRef ref,
    int shownIndex,
    List<WispGridColumn<Mod>> columns, {
    double horizontalPaddingOffset = 0,
    bool isSecondaryHeader = false,
  }) => _vramSummaryOverlayWidget(
    context,
    itemsInGroup,
    ref,
    shownIndex,
    columns,
    getGroupName(itemsInGroup.first),
    horizontalPaddingOffset: horizontalPaddingOffset,
    isSecondaryHeader: isSecondaryHeader,
  );
}

class AuthorModGridGroup extends WispGridGroup<Mod> {
  AuthorModGridGroup() : super('author', 'Author');

  @override
  String getGroupName(Mod mod, {Comparable? groupSortValue}) =>
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
    bool isSecondaryHeader = false,
  }) => _vramSummaryOverlayWidget(
    context,
    itemsInGroup,
    ref,
    shownIndex,
    columns,
    getGroupName(itemsInGroup.first),
    horizontalPaddingOffset: horizontalPaddingOffset,
    isSecondaryHeader: isSecondaryHeader,
  );
}

class ModTypeModGridGroup extends WispGridGroup<Mod> {
  ModTypeModGridGroup() : super('modType', 'Mod Type');

  @override
  String getGroupName(Mod mod, {Comparable? groupSortValue}) {
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
      return CategoryModGridGroup.uncategorizedSortValue;
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
    bool isSecondaryHeader = false,
  }) => _vramSummaryOverlayWidget(
    context,
    itemsInGroup,
    ref,
    shownIndex,
    columns,
    getGroupName(itemsInGroup.first),
    horizontalPaddingOffset: horizontalPaddingOffset,
    isSecondaryHeader: isSecondaryHeader,
  );
}

class GameVersionModGridGroup extends WispGridGroup<Mod> {
  GameVersionModGridGroup() : super('gameVersion', 'Game Version');

  @override
  String getGroupName(Mod mod, {Comparable? groupSortValue}) =>
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
    bool isSecondaryHeader = false,
  }) => _vramSummaryOverlayWidget(
    context,
    itemsInGroup,
    ref,
    shownIndex,
    columns,
    getGroupName(itemsInGroup.first),
    horizontalPaddingOffset: horizontalPaddingOffset,
    isSecondaryHeader: isSecondaryHeader,
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
  bool isSecondaryHeader = false,
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

  final overlayBody = Padding(
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
    );

  final child = isSecondaryHeader
      ? MouseRegion(
          onEnter: (_) =>
              ref.read(vramColumnHovered.notifier).state = true,
          onExit: (_) =>
              ref.read(vramColumnHovered.notifier).state = false,
          child: Consumer(
            builder: (context, ref, _) => ref.watch(vramColumnHovered)
                ? overlayBody
                : const SizedBox.shrink(),
          ),
        )
      : overlayBody;

  return OverlayWidgetData(
    // Subtract padding added to group that isn't present on the mod row
    left: cellWidthBeforeVramColumn -
        6 +
        WispGrid.gridRowSpacing +
        horizontalPaddingOffset,
    child: child,
  );
}
