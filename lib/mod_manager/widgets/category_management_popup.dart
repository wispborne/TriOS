import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/mod_tag_manager/category_auto_color.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';

/// Shows a popup for bulk management of all categories.
/// Supports drag-to-reorder, inline rename, right-click for color/delete.
void showCategoryManagementPopup({
  required BuildContext context,
  required WidgetRef ref,
}) {
  showDialog(
    context: context,
    builder: (context) => _CategoryManagementPopup(ref: ref),
  );
}

class _CategoryManagementPopup extends StatefulWidget {
  final WidgetRef ref;

  const _CategoryManagementPopup({required this.ref});

  @override
  State<_CategoryManagementPopup> createState() =>
      _CategoryManagementPopupState();
}

class _CategoryManagementPopupState extends State<_CategoryManagementPopup> {
  int? _editingIndex;
  late TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController();
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  CategoryManagerNotifier get _notifier =>
      widget.ref.read(categoryManagerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final store = widget.ref.read(categoryManagerProvider).value;
    if (store == null) return const SizedBox.shrink();

    final categories = _notifier.getAllCategories();
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Manage Categories'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                onReorder: (oldIndex, newIndex) {
                  _reorderCategories(categories, oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isEditing = _editingIndex == index;

                  return _buildCategoryRow(
                    key: ValueKey(category.id),
                    category: category,
                    index: index,
                    isEditing: isEditing,
                    theme: theme,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add),
                  label: const Text('New Category'),
                ),
                const Spacer(),
                Row(
                  spacing: 4,
                  children: [
                    const Text('Auto-color'),
                    Switch(
                      value: store.autoColorNewCategories,
                      onChanged: (value) {
                        _notifier.setAutoColorNewCategories(value);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildCategoryRow({
    required Key key,
    required Category category,
    required int index,
    required bool isEditing,
    required ThemeData theme,
  }) {
    if (isEditing) {
      return ListTile(
        key: key,
        leading: _buildColorDot(category),
        title: TextField(
          controller: _renameController,
          autofocus: true,
          style: theme.textTheme.bodyMedium,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _notifier.updateCategory(category.id, name: value.trim());
            }
            setState(() => _editingIndex = null);
          },
          onTapOutside: (_) {
            setState(() => _editingIndex = null);
          },
        ),
      );
    }

    return ContextMenuRegion(
      key: key,
      contextMenu: _buildCategoryItemContextMenu(category),
      child: ListTile(
        leading: _buildColorDot(category),
        title: GestureDetector(
          onDoubleTap: () {
            setState(() {
              _editingIndex = index;
              _renameController.text = category.name;
            });
          },
          child: Text(category.name),
        ),
        trailing: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
      ),
    );
  }

  Widget _buildColorDot(Category category) {
    return GestureDetector(
      onTap: () => _showColorPicker(category),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: category.color ?? Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }

  ContextMenu _buildCategoryItemContextMenu(Category category) {
    return ContextMenu(
      entries: [
        MenuItem(
          label: 'Rename',
          icon: Icons.edit,
          onSelected: () {
            final allCategories = _notifier.getAllCategories();
            final index = allCategories.indexWhere((c) => c.id == category.id);
            if (index != -1) {
              setState(() {
                _editingIndex = index;
                _renameController.text = category.name;
              });
            }
          },
        ),
        MenuItem(
          label: 'Change Color',
          icon: Icons.palette,
          onSelected: () => _showColorPicker(category),
        ),
        const MenuDivider(),
        MenuItem(
          label: 'Delete',
          icon: Icons.delete,
          onSelected: () {
            _notifier.deleteCategory(category.id);
            setState(() {});
          },
        ),
      ],
      padding: const EdgeInsets.all(8.0),
    );
  }

  void _showColorPicker(Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Color for "${category.name}"'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final color in categoryColorPalette)
              GestureDetector(
                onTap: () {
                  _notifier.updateCategory(category.id, color: color);
                  Navigator.of(dialogContext).pop();
                  setState(() {});
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: category.color == color
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 2,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _notifier.updateCategory(category.id, clearColor: true);
              Navigator.of(dialogContext).pop();
              setState(() {});
            },
            child: const Text('No Color'),
          ),
        ],
      ),
    );
  }

  void _addCategory() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _notifier.createCategory(value.trim());
              Navigator.of(dialogContext).pop();
              setState(() {});
            }
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
                _notifier.createCategory(value);
                Navigator.of(dialogContext).pop();
                setState(() {});
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _reorderCategories(
    List<Category> categories,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex--;
    final reordered = List<Category>.from(categories);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // Update sortOrder for all reordered categories.
    for (var i = 0; i < reordered.length; i++) {
      _notifier.updateCategory(reordered[i].id, sortOrder: i);
    }
    setState(() {});
  }
}
