import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/widgets/category_icon_picker_dialog.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/mod_tag_manager/category_auto_color.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';
import 'package:trios/models/mod.dart';

/// Shows a small dialog for quickly creating a new category.
/// Calls [onCreated] with the newly created category.
void showCreateCategoryDialog({
  required BuildContext context,
  required WidgetRef ref,
  ValueChanged<Category>? onCreated,
  required Mod mod,
}) {
  showDialog(
    context: context,
    builder: (context) =>
        _CreateCategoryDialog(ref: ref, onCreated: onCreated, mod: mod),
  );
}

class _CreateCategoryDialog extends StatefulWidget {
  final WidgetRef ref;
  final ValueChanged<Category>? onCreated;
  final Mod mod;

  const _CreateCategoryDialog({
    required this.ref,
    this.onCreated,
    required this.mod,
  });

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final _nameController = TextEditingController();
  Color? _selectedColor;
  CategoryIcon? _selectedIcon;

  @override
  void initState() {
    super.initState();
    // Preview the auto-color.
    final store = widget.ref.read(categoryManagerProvider).value;
    if (store != null) {
      _selectedColor = pickAutoColor(store.categories);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Category name'),
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 16),
          Row(
            spacing: 8,
            children: [
              const Text('Color:'),
              GestureDetector(
                onTap: _showColorPicker,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _selectedColor ?? Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
              if (_selectedColor != null)
                TextButton(
                  onPressed: () => setState(() => _selectedColor = null),
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            spacing: 8,
            children: [
              const Text('Icon:'),
              GestureDetector(
                onTap: _showIconPicker,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Center(
                    child:
                        _selectedIcon?.toWidget(
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ) ??
                        Icon(
                          Icons.add,
                          size: 20,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
              ),
              if (_selectedIcon != null)
                TextButton(
                  onPressed: () => setState(() => _selectedIcon = null),
                  child: const Text('Clear'),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _create, child: const Text('Create')),
      ],
    );
  }

  void _create() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final notifier = widget.ref.read(categoryManagerProvider.notifier);
    final category = notifier.createCategory(
      name,
      color: _selectedColor,
      icon: _selectedIcon,
    );
    widget.onCreated?.call(category);
    Navigator.of(context).pop();
  }

  void _showIconPicker() {
    showCategoryIconPicker(
      context: context,
      currentIcon: _selectedIcon,
      mod: widget.mod,
      onIconSelected: (icon) => setState(() => _selectedIcon = icon),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final color in categoryColorPalette)
              GestureDetector(
                onTap: () {
                  setState(() => _selectedColor = color);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _selectedColor == color
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
      ),
    );
  }
}
