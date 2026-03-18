import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/mod_context_menu.dart';
import 'package:trios/mod_manager/widgets/category_icon_picker_dialog.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/mod_tag_manager/category_auto_color.dart';
import 'package:trios/mod_tag_manager/category_icon_palette.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';
import 'package:trios/mod_tag_manager/category_store.dart';
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

    for (final modId in droppedItemKeys) {
      if (targetCategory == null) {
        // Dropping into "Uncategorized" — remove all assignments.
        notifier.removeAllCategoriesFromMod(modId);
      } else {
        final assignments = store.modAssignments[modId] ?? [];
        final alreadyAssigned = assignments.any(
          (a) => a.categoryId == targetCategory.id,
        );
        if (alreadyAssigned) {
          notifier.setPrimaryCategory(modId, targetCategory.id);
        } else {
          notifier.addCategoryToMod(modId, targetCategory.id, isPrimary: true);
        }
      }
    }
  }

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

  /// Resolves the category for a group of mods (based on the first mod's primary assignment).
  Category? _getCategoryForGroup(List<Mod> itemsInGroup) {
    final store = ref.read(categoryManagerProvider).value;
    if (store == null || itemsInGroup.isEmpty) return null;
    final assignments = store.modAssignments[itemsInGroup.first.id] ?? [];
    final primary = assignments.firstWhereOrNull((a) => a.isPrimary);
    final categoryId =
        primary?.categoryId ?? assignments.firstOrNull?.categoryId;
    if (categoryId == null) return null;
    return store.categories.firstWhereOrNull((c) => c.id == categoryId);
  }

  List<ContextMenuEntry> _buildCategoryContextMenuEntries(
    BuildContext context,
    List<Mod> itemsInGroup,
  ) {
    final category = _getCategoryForGroup(itemsInGroup);
    if (category == null) return [];
    final notifier = ref.read(categoryManagerProvider.notifier);

    void onBrowseAllSelected() {
      showCategoryIconPicker(
        context: context,
        currentIcon: category.icon,
        onIconSelected: (icon) {
          if (icon == null) {
            notifier.updateCategory(category.id, clearIcon: true);
          } else {
            notifier.updateCategory(category.id, icon: icon);
          }
        },
        mod: itemsInGroup.first,
      );
    }

    return [
      MenuItem(
        label: 'Rename Category',
        icon: Icons.edit,
        onSelected: () {
          final controller = TextEditingController(text: category.name);
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text('Rename "${category.name}"'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Category name'),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    notifier.updateCategory(category.id, name: value.trim());
                  }
                  Navigator.of(dialogContext).pop();
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isNotEmpty) {
                      notifier.updateCategory(category.id, name: value);
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Rename'),
                ),
              ],
            ),
          );
        },
      ),
      MenuItem.submenu(
        label: 'Change Color',
        icon: Icons.palette,
        items: [
          MenuItem(
            label: '',
            icon: Icons.clear,
            padding: .only(left: 4),
            onSelected: () {
              notifier.updateCategory(category.id, clearColor: true);
            },
          ),
          for (final color in categoryColorPalette)
            _CategoryColorMenuItem(
              color: color,
              isSelected: category.color == color,
              onSelected: () {
                notifier.updateCategory(category.id, color: color);
              },
            ),
        ],
      ),
      MenuItem.submenu(
        label: 'Change Icon',
        icon: Icons.emoji_symbols,
        onSelected: onBrowseAllSelected,
        items: [
          MenuItem(
            label: 'Browse All…',
            icon: Icons.apps,
            onSelected: onBrowseAllSelected,
          ),
          MenuItem(
            label: 'No icon',
            icon: Icons.clear,
            onSelected: () {
              notifier.updateCategory(category.id, clearIcon: true);
            },
          ),
          const MenuDivider(),
          ..._getUnusedIcons(ref.read(categoryManagerProvider).value, category)
              .take(10)
              .map(
                (icon) => _CategoryIconMenuItem(
                  categoryIcon: icon,
                  isSelected: _isSameIcon(category.icon, icon),
                  onSelected: () {
                    notifier.updateCategory(category.id, icon: icon);
                  },
                ),
              ),
        ],
      ),
    ];
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
    final categoryEntries = _buildCategoryContextMenuEntries(
      context,
      itemsInGroup,
    );

    return ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: [
          ...buildModBulkActionContextMenu(itemsInGroup, ref, context).entries,
          if (categoryEntries.isNotEmpty) ...[
            const MenuDivider(),
            ...categoryEntries,
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

/// Returns icons from [allCategoryIcons] not used by any other category.
List<CategoryIcon> _getUnusedIcons(CategoryStore? store, Category current) {
  if (store == null) return allCategoryIcons;
  final usedIcons = store.categories
      .where((c) => c.id != current.id && c.icon != null)
      .map((c) => c.icon!)
      .toList();
  return allCategoryIcons
      .where((icon) => !usedIcons.any((used) => _isSameIcon(used, icon)))
      .toList();
}

bool _isSameIcon(CategoryIcon? a, CategoryIcon? b) {
  if (a == null || b == null) return false;
  return switch ((a, b)) {
    (MaterialCategoryIcon a, MaterialCategoryIcon b) =>
      a.codePoint == b.codePoint,
    (SvgCategoryIcon a, SvgCategoryIcon b) => a.assetPath == b.assetPath,
    _ => false,
  };
}

/// Custom context menu entry that renders a colored square swatch.
final class _CategoryColorMenuItem extends ContextMenuItem<void> {
  final Color color;
  final bool isSelected;

  const _CategoryColorMenuItem({
    required this.color,
    required this.isSelected,
    super.onSelected,
  });

  @override
  Widget builder(
    BuildContext context,
    ContextMenuState menuState, [
    FocusNode? focusNode,
  ]) {
    final isFocused = menuState.focusedEntry == this;
    final theme = Theme.of(context);
    final background = theme.colorScheme.surfaceContainerLow;

    return ConstrainedBox(
      constraints: const BoxConstraints.expand(height: 32.0),
      child: Material(
        color: isFocused ? theme.focusColor.withAlpha(20) : background,
        borderRadius: BorderRadius.circular(4.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => handleItemSelection(context),
          canRequestFocus: false,
          child: Row(
            children: [
              const SizedBox(width: 8.0),
              SizedBox.square(
                dimension: 32.0,
                child: Center(
                  child: Container(
                    width: isSelected ? 32 : 12,
                    height: isSelected ? 16 : 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(isSelected ? 4 : 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  String get debugLabel =>
      "[${hashCode.toString().substring(0, 5)}] color:$color";
}

/// Custom context menu entry that renders a category icon.
final class _CategoryIconMenuItem extends ContextMenuItem<void> {
  final CategoryIcon categoryIcon;
  final bool isSelected;

  const _CategoryIconMenuItem({
    required this.categoryIcon,
    required this.isSelected,
    super.onSelected,
  });

  @override
  Widget builder(
    BuildContext context,
    ContextMenuState menuState, [
    FocusNode? focusNode,
  ]) {
    final isFocused = menuState.focusedEntry == this;
    final theme = Theme.of(context);
    final background = theme.colorScheme.surfaceContainerLow;
    final iconColor = isFocused
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return ConstrainedBox(
      constraints: const BoxConstraints.expand(height: 32.0),
      child: Material(
        color: isFocused ? theme.focusColor.withAlpha(20) : background,
        borderRadius: BorderRadius.circular(4.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => handleItemSelection(context),
          canRequestFocus: false,
          child: Row(
            mainAxisAlignment: .center,
            children: [
              const SizedBox(width: 8.0),
              SizedBox.square(
                dimension: 32.0,
                child: Center(
                  child: categoryIcon.toWidget(size: 20, color: iconColor),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  String get debugLabel =>
      "[${hashCode.toString().substring(0, 5)}] icon:$categoryIcon";
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
