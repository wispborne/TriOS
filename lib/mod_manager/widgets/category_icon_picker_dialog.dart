import 'package:flutter/material.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/mod_tag_manager/category_icon_palette.dart';
import 'package:trios/models/mod.dart';

/// Shows a dialog for picking a category icon.
/// Calls [onIconSelected] with the chosen icon, or `null` if cleared.
void showCategoryIconPicker({
  required BuildContext context,
  CategoryIcon? currentIcon,
  required Mod mod,
  required ValueChanged<CategoryIcon?> onIconSelected,
}) {
  showDialog(
    context: context,
    builder: (context) => _CategoryIconPickerDialog(
      currentIcon: currentIcon,
      onIconSelected: onIconSelected,
      mod: mod,
    ),
  );
}

class _CategoryIconPickerDialog extends StatelessWidget {
  final CategoryIcon? currentIcon;
  final ValueChanged<CategoryIcon?> onIconSelected;
  final Mod mod;

  const _CategoryIconPickerDialog({
    this.currentIcon,
    required this.onIconSelected,
    required this.mod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface;

    return AlertDialog(
      title: Text("Icon for ${mod.name}"),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Custom', style: theme.textTheme.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final icon in categorySvgIcons)
                    _buildIconTile(context, icon, iconColor),
                ],
              ),
              const SizedBox(height: 16),
              Text('Material', style: theme.textTheme.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final icon in categoryMaterialIcons)
                    _buildIconTile(context, icon, iconColor),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onIconSelected(null);
            Navigator.of(context).pop();
          },
          child: const Text('No Icon'),
        ),
      ],
    );
  }

  Widget _buildIconTile(
    BuildContext context,
    CategoryIcon icon,
    Color iconColor,
  ) {
    final isSelected = _isIconSelected(icon);
    return GestureDetector(
      onTap: () {
        onIconSelected(icon);
        Navigator.of(context).pop();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Center(child: icon.toWidget(size: 24, color: iconColor)),
      ),
    );
  }

  bool _isIconSelected(CategoryIcon icon) {
    if (currentIcon == null) return false;
    return switch ((currentIcon!, icon)) {
      (MaterialCategoryIcon a, MaterialCategoryIcon b) =>
        a.codePoint == b.codePoint,
      (SvgCategoryIcon a, SvgCategoryIcon b) => a.assetPath == b.assetPath,
      _ => false,
    };
  }
}
