import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/widgets/category_icon_picker_dialog.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/mod_tag_manager/category_auto_color.dart';
import 'package:trios/mod_tag_manager/category_icon_palette.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';
import 'package:trios/mod_tag_manager/category_store.dart';
import 'package:trios/mod_tag_manager/mod_category_assignment.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';

import 'category_management_popup.dart';
import 'create_category_dialog.dart';

/// Builds a context menu for the category cell of a specific mod.
ContextMenu buildCategoryCellContextMenu({
  required String modId,
  required WidgetRef ref,
  required BuildContext context,
}) {
  final store = ref.read(categoryManagerProvider).value;
  if (store == null) {
    return ContextMenu(entries: []);
  }

  final notifier = ref.read(categoryManagerProvider.notifier);
  final allCategories = notifier.getAllCategories();
  final assignments = notifier.getAssignmentsForMod(modId);
  final assignedIds = assignments.map((a) => a.categoryId).toSet();
  final primaryId = assignments
      .firstWhere(
        (a) => a.isPrimary,
        orElse: () => const ModCategoryAssignment(categoryId: ''),
      )
      .categoryId;
  final primaryCategory = allCategories.firstWhereOrNull(
    (c) => c.id == primaryId,
  );
  final mod = ref.read(AppState.mods).firstWhere((mod) => mod.id == modId);

  return ContextMenu(
    maxHeight: MediaQuery.of(context).size.height * 0.8,
    entries: [
      if (mod != null) ...[
        MenuHeader(
          text: mod.findFirstEnabledOrHighestVersion!.modInfo.nameOrId,
          disableUppercase: false,
        ),
        const MenuDivider(),
      ],
      if (assignedIds.isNotEmpty) ...[
        MenuHeader(text: 'Set Primary Category'),
        ...allCategories
            .where((c) => assignedIds.contains(c.id))
            .map(
              (category) => MenuItem(
                label: category.name,
                icon: category.id == primaryId ? Icons.check : null,
                onSelected: () {
                  notifier.setPrimaryCategory(modId, category.id);
                },
              ),
            ),
        const MenuDivider(),
        MenuHeader(text: primaryCategory != null
            ? "Manage: ${primaryCategory.name}"
            : "(please select a primary category)"),
        ..._buildPrimaryManagementItems(
          mod: mod,
          primaryId: primaryId,
          notifier: notifier,
          allCategories: allCategories,
          context: context,
          ref: ref,
        ),
        const MenuDivider(),
      ],
      MenuItem(
        label: 'Add Category...',
        icon: Icons.add,
        onSelected: () {
          showCreateCategoryDialog(
            context: context,
            ref: ref,
            onCreated: (category) {
              notifier.addCategoryToMod(modId, category.id, isPrimary: true);
            },
            mod: mod,
          );
        },
      ),
      MenuItem(
        label: 'Manage Categories...',
        icon: Icons.settings,
        onSelected: () {
          showCategoryManagementPopup(context: context, ref: ref, mod: mod);
        },
      ),
      const MenuDivider(),
      MenuHeader(text: 'Choose Categories'),
      ...allCategories.map((category) {
        final isAssigned = assignedIds.contains(category.id);
        return CheckableMenuItem(
          label: category.name,
          leading: _buildCategoryLeading(category),
          isChecked: isAssigned,
          onSelected: () {
            if (isAssigned) {
              notifier.removeCategoryFromMod(modId, category.id);
            } else {
              notifier.addCategoryToMod(modId, category.id);
            }
          },
        );
      }),
    ],
    padding: const EdgeInsets.all(8.0),
  );
}

/// Builds a context menu for batch category operations on multiple mods.
ContextMenu buildCategoryBatchContextMenu({
  required Set<String> modIds,
  required WidgetRef ref,
  required BuildContext context,
}) {
  final store = ref.read(categoryManagerProvider).value;
  if (store == null) {
    return ContextMenu(entries: []);
  }

  final notifier = ref.read(categoryManagerProvider.notifier);
  final allCategories = notifier.getAllCategories();

  // A category is "assigned to all" if every selected mod has it.
  Set<String> assignedToAllIds() {
    if (modIds.isEmpty) return {};
    final sets = modIds.map(
      (id) => notifier.getAssignmentsForMod(id).map((a) => a.categoryId).toSet(),
    );
    return sets.reduce((a, b) => a.intersection(b));
  }

  final commonIds = assignedToAllIds();

  return ContextMenu(
    maxHeight: MediaQuery.of(context).size.height * 0.8,
    entries: [
      MenuHeader(text: '${modIds.length} mods selected'),
      const MenuDivider(),
      MenuHeader(text: 'Set Primary Category'),
      ...allCategories.map(
        (category) => MenuItem(
          label: category.name,
          leading: _buildCategoryLeading(category),
          onSelected: () {
            notifier.moveModsToCategory(modIds.toList(), category.id);
          },
        ),
      ),
      const MenuDivider(),
      MenuItem(
        label: 'Manage Categories...',
        icon: Icons.settings,
        onSelected: () {
          showCategoryManagementPopup(context: context, ref: ref);
        },
      ),
      const MenuDivider(),
      MenuHeader(text: 'Choose Categories'),
      ...allCategories.map((category) {
        final isAssigned = commonIds.contains(category.id);
        return CheckableMenuItem(
          label: category.name,
          leading: _buildCategoryLeading(category),
          isChecked: isAssigned,
          onSelected: () {
            for (final modId in modIds) {
              if (isAssigned) {
                notifier.removeCategoryFromMod(modId, category.id);
              } else {
                notifier.addCategoryToMod(modId, category.id);
              }
            }
          },
        );
      }),
    ],
    padding: const EdgeInsets.all(8.0),
  );
}

List<ContextMenuEntry> _buildPrimaryManagementItems({
  required Mod mod,
  required String primaryId,
  required CategoryManagerNotifier notifier,
  required List<Category> allCategories,
  required BuildContext context,
  required WidgetRef ref,
}) {
  final primaryCategory = allCategories
      .where((c) => c.id == primaryId)
      .firstOrNull;
  if (primaryCategory == null) return [];

  return [
    ...buildCategoryContextMenuEntries(context, ref, primaryCategory, mod),
  ];
}

Widget? _buildCategoryLeading(Category category) {
  final icon = category.icon;
  final color = category.color;
  if (icon == null && color == null) return null;

  if (icon != null) {
    return icon.toWidget(size: 16, color: color);
  }

  // Color only — show a color dot.
  return Center(
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

List<ContextMenuEntry> buildCategoryContextMenuEntries(
  BuildContext context,
  WidgetRef ref,
  Category category,
  Mod mod,
) {
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
      mod: mod,
    );
  }

  return [
    MenuItem(
      label: 'Rename',
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
      label: 'Category Color',
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
      label: 'Category Icon',
      icon: Icons.emoji_symbols,
      onSelected: onBrowseAllSelected,
      items: [
        MenuItem(
          label: 'None',
          icon: Icons.clear,
          onSelected: () {
            notifier.updateCategory(category.id, clearIcon: true);
          },
        ),
        ..._getUnusedIcons(ref.read(categoryManagerProvider).value, category)
            .take(10)
            .map(
              (icon) => _CategoryIconMenuItem(
                categoryIcon: icon,
                isSelected: category.icon == icon,
                onSelected: () {
                  notifier.updateCategory(category.id, icon: icon);
                },
              ),
            ),
        MenuItem(
          label: 'All icons…',
          icon: Icons.apps,
          onSelected: onBrowseAllSelected,
        ),
      ],
    ),
  ];
}

/// Returns icons from [allCategoryIcons] not used by any other category.
List<CategoryIcon> _getUnusedIcons(CategoryStore? store, Category current) {
  if (store == null) return allCategoryIcons;
  final usedIcons = store.categories
      .where((c) => c.id != current.id && c.icon != null)
      .map((c) => c.icon!)
      .toSet();
  return allCategoryIcons
      .where((icon) => !usedIcons.contains(icon))
      .toList();
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

