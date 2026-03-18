import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';
import 'package:trios/mod_tag_manager/mod_category_assignment.dart';
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
  final mod = ref
      .read(AppState.mods)
      .firstWhere((mod) => mod.id == modId);

  return ContextMenu(
    entries: [
      if (mod != null) ...[
        MenuHeader(
          text: mod.findFirstEnabledOrHighestVersion!.modInfo.nameOrId,
          disableUppercase: false,
        ),
        const MenuDivider(),
      ],
      if (assignedIds.isNotEmpty) ...[
        MenuHeader(text: 'Primary Category'),
        ...allCategories
            .where((c) => assignedIds.contains(c.id))
            .map(
              (category) => MenuItem(
                label: category.name,
                icon: category.id == primaryId ? Icons.check : null,
                leading: category.id != primaryId
                    ? _buildCategoryLeading(category)
                    : null,
                onSelected: () {
                  notifier.setPrimaryCategory(modId, category.id);
                },
              ),
            ),
        const MenuDivider(),
      ],
      MenuHeader(text: 'Categories'),
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
      const MenuDivider(),
      ..._buildPrimaryManagementItems(
        modId: modId,
        primaryId: primaryId,
        notifier: notifier,
        allCategories: allCategories,
        context: context,
      ),
      MenuItem(
        label: 'New Category...',
        icon: Icons.add,
        onSelected: () {
          showCreateCategoryDialog(
            context: context,
            ref: ref,
            onCreated: (category) {
              notifier.addCategoryToMod(modId, category.id, isPrimary: true);
            },
            mod: mod
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
    ],
    padding: const EdgeInsets.all(8.0),
  );
}

List<ContextMenuEntry> _buildPrimaryManagementItems({
  required String modId,
  required String primaryId,
  required CategoryManagerNotifier notifier,
  required List<Category> allCategories,
  required BuildContext context,
}) {
  final primaryCategory = allCategories
      .where((c) => c.id == primaryId)
      .firstOrNull;
  if (primaryCategory == null) return [];

  return [
    MenuItem(
      label: 'Rename "${primaryCategory.name}"...',
      icon: Icons.edit,
      onSelected: () {
        _showRenameDialog(
          context: context,
          currentName: primaryCategory.name,
          onRenamed: (newName) {
            notifier.updateCategory(primaryCategory.id, name: newName);
          },
        );
      },
    ),
    const MenuDivider(),
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

void _showRenameDialog({
  required BuildContext context,
  required String currentName,
  required ValueChanged<String> onRenamed,
}) {
  final controller = TextEditingController(text: currentName);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename Category'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Category name'),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            onRenamed(value.trim());
            Navigator.of(context).pop();
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) {
              onRenamed(value);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Rename'),
        ),
      ],
    ),
  );
}
