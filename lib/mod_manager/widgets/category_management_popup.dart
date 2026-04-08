import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/mod_tag_manager/category_auto_color.dart';
import 'package:trios/mod_tag_manager/category_icon_palette.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';
import 'package:trios/mod_tag_manager/category_store.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/constants_theme.dart';

/// Shows a popup for bulk management of all categories.
/// Supports drag-to-reorder, inline rename, inline color/icon pickers,
/// inline creation, and delete with confirmation.
void showCategoryManagementPopup({
  required BuildContext context,
  required WidgetRef ref,
  Mod? mod,
}) {
  showDialog(
    context: context,
    builder: (context) => _CategoryManagementPopup(ref: ref, mod: mod),
  );
}

class _CategoryManagementPopup extends StatefulWidget {
  final WidgetRef ref;
  final Mod? mod;

  const _CategoryManagementPopup({required this.ref, this.mod});

  @override
  State<_CategoryManagementPopup> createState() =>
      _CategoryManagementPopupState();
}

class _CategoryManagementPopupState extends State<_CategoryManagementPopup> {
  // Rename state.
  String? _editingCategoryId;
  late final TextEditingController _renameController;
  late final FocusNode _renameFocusNode;

  // Inline expansion state — only one panel open at a time.
  String? _expandedColorCategoryId;
  String? _expandedIconCategoryId;

  // New-category inline state.
  late final TextEditingController _newCatNameController;
  Color? _newCatColor;
  CategoryIcon? _newCatIcon;
  bool _showNewCatColorPicker = false;
  bool _showNewCatIconPicker = false;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController();
    _renameFocusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          setState(() => _editingCategoryId = null);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    _newCatNameController = TextEditingController()
      ..addListener(() => setState(() {}));
    _initNewCatColor();
  }

  void _initNewCatColor() {
    final store = widget.ref.read(categoryManagerProvider).value;
    if (store != null) {
      _newCatColor = pickAutoColor(store.categories);
    }
  }

  @override
  void dispose() {
    _renameController.dispose();
    _renameFocusNode.dispose();
    _newCatNameController.dispose();
    super.dispose();
  }

  CategoryManagerNotifier get _notifier =>
      widget.ref.read(categoryManagerProvider.notifier);

  void _collapseAllPickers() {
    _expandedColorCategoryId = null;
    _expandedIconCategoryId = null;
    _showNewCatColorPicker = false;
    _showNewCatIconPicker = false;
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.ref.read(categoryManagerProvider).value;
    if (store == null) return const SizedBox.shrink();

    final categories = _notifier.getAllCategories();
    final theme = Theme.of(context);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const .symmetric(horizontal: 48, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height - 64,
        ),
        child: Column(
          children: [
            // Header.
            Padding(
              padding: const .fromLTRB(16, 12, 8, 0),
              child: Row(
                spacing: 8,
                children: [
                  Text('Manage Categories', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Category list.
            Expanded(
              child: SingleChildScrollView(
                padding: const .symmetric(horizontal: 8),
                child: Column(
                  children: [
                    ClipRect(
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const .symmetric(vertical: 4),
                        itemCount: categories.length,
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) =>
                            _reorderCategories(categories, oldIndex, newIndex),
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(
                              TriOSThemeConstants.cornerRadius,
                            ),
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return _buildCategoryItem(
                            key: ValueKey(category.id),
                            category: category,
                            index: index,
                            store: store,
                            theme: theme,
                          );
                        },
                      ),
                    ),

                    // Inline new-category row.
                    _buildNewCategoryRow(theme, store),
                  ],
                ),
              ),
            ),

            // Footer.
            Padding(
              padding: const .fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Row(
                    spacing: 4,
                    children: [
                      // CheckboxWithLabel(
                      //   label: 'Auto-color',
                      //   labelStyle: theme.textTheme.labelMedium,
                      //   textPadding: .zero,
                      //   value: store.autoColorNewCategories,
                      //   onChanged: (value) {
                      //     _notifier.setAutoColorNewCategories(value ?? true);
                      //     if ((value ?? true) && _newCatColor == null) {
                      //       _newCatColor = pickAutoColor(
                      //         _notifier.getAllCategories(),
                      //       );
                      //     }
                      //     setState(() {});
                      //   },
                      // ),
                    ],
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category item (row + optional inline pickers).
  // ---------------------------------------------------------------------------

  Widget _buildCategoryItem({
    required Key key,
    required Category category,
    required int index,
    required CategoryStore store,
    required ThemeData theme,
  }) {
    final isEditing = _editingCategoryId == category.id;
    final colorScheme = theme.colorScheme;

    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The main row.
        Container(
          color: null,
          padding: const .symmetric(horizontal: 8, vertical: 2),
          child: Row(
            spacing: 8,
            children: [
              // Drag handle.
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              // Color circle.
              Padding(
                padding: const .only(left: 4),
                child: _ColorCircle(
                  color: category.color,
                  isSelected: _expandedColorCategoryId == category.id,
                  onTap: () => setState(() {
                    if (_expandedColorCategoryId == category.id) {
                      _expandedColorCategoryId = null;
                    } else {
                      _collapseAllPickers();
                      _expandedColorCategoryId = category.id;
                    }
                  }),
                ),
              ),

              // Icon indicator.
              _IconIndicator(
                icon: category.icon,
                color: category.color ?? colorScheme.onSurface,
                isSelected: _expandedIconCategoryId == category.id,
                onTap: () => setState(() {
                  if (_expandedIconCategoryId == category.id) {
                    _expandedIconCategoryId = null;
                  } else {
                    _collapseAllPickers();
                    _expandedIconCategoryId = category.id;
                  }
                }),
              ),
              // Edit button / confirm button.
              if (isEditing)
                _SmallIconButton(
                  icon: Icons.check,
                  tooltip: 'Confirm',
                  color: colorScheme.primary,
                  onPressed: () {
                    final value = _renameController.text.trim();
                    if (value.isNotEmpty) {
                      _notifier.updateCategory(category.id, name: value);
                    }
                    setState(() => _editingCategoryId = null);
                  },
                )
              else
                _SmallIconButton(
                  icon: Icons.edit_outlined,
                  color: theme.iconTheme.color,
                  tooltip: 'Rename',
                  onPressed: () => setState(() {
                    _editingCategoryId = category.id;
                    _renameController.text = category.name;
                    _renameFocusNode.requestFocus();
                  }),
                ),

              // Name (text or text field).
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: _renameController,
                        focusNode: _renameFocusNode,
                        autofocus: true,
                        style: theme.textTheme.labelLarge,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const .symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              TriOSThemeConstants.cornerRadius,
                            ),
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _notifier.updateCategory(
                              category.id,
                              name: value.trim(),
                            );
                          }
                          setState(() => _editingCategoryId = null);
                        },
                      )
                    : Text(
                        category.name,
                        style: theme.textTheme.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),

              // Delete button.
              _SmallIconButton(
                icon: Icons.delete,
                tooltip: 'Delete',
                onPressed: () => _handleDelete(category, store),
              ),
            ],
          ),
        ),

        // Inline color picker.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _expandedColorCategoryId == category.id
              ? _InlineColorPicker(
                  selectedColor: category.color,
                  onColorSelected: (color) {
                    _notifier.updateCategory(category.id, color: color);
                    setState(() => _expandedColorCategoryId = null);
                  },
                  onClear: () {
                    _notifier.updateCategory(category.id, clearColor: true);
                    setState(() => _expandedColorCategoryId = null);
                  },
                )
              : const SizedBox.shrink(),
        ),

        // Inline icon picker.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _expandedIconCategoryId == category.id
              ? _InlineIconPicker(
                  currentIcon: category.icon,
                  iconColor:
                      category.color ?? Theme.of(context).colorScheme.onSurface,
                  onIconSelected: (icon) {
                    _notifier.updateCategory(category.id, icon: icon);
                    setState(() => _expandedIconCategoryId = null);
                  },
                  onClear: () {
                    _notifier.updateCategory(category.id, clearIcon: true);
                    setState(() => _expandedIconCategoryId = null);
                  },
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Delete with confirmation.
  // ---------------------------------------------------------------------------

  void _handleDelete(Category category, CategoryStore store) {
    final count = _countModsUsingCategory(category.id, store);
    if (count == 0) {
      _notifier.deleteCategory(category.id);
      setState(() {});
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: Text(
          'This category is assigned to $count mod(s). '
          'They will become uncategorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _notifier.deleteCategory(category.id);
              Navigator.of(ctx).pop();
              setState(() {});
            },
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  int _countModsUsingCategory(String categoryId, CategoryStore store) {
    return store.modAssignments.values
        .where((list) => list.any((a) => a.categoryId == categoryId))
        .length;
  }

  // ---------------------------------------------------------------------------
  // Inline new-category row.
  // ---------------------------------------------------------------------------

  Widget _buildNewCategoryRow(ThemeData theme, CategoryStore store) {
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const .symmetric(horizontal: 8, vertical: 8),
          child: Row(
            spacing: 8,
            children: [
              // Spacer matching drag-handle width.
              const SizedBox(width: 24),

              // Color circle for new category.
              _ColorCircle(
                color: _newCatColor,
                isSelected: _showNewCatColorPicker,
                onTap: () => setState(() {
                  if (_showNewCatColorPicker) {
                    _showNewCatColorPicker = false;
                  } else {
                    _collapseAllPickers();
                    _showNewCatColorPicker = true;
                  }
                }),
              ),

              // Icon indicator for new category.
              _IconIndicator(
                icon: _newCatIcon,
                color: _newCatColor ?? colorScheme.onSurface,
                isSelected: _showNewCatIconPicker,
                placeholderIcon: Icons.add,
                onTap: () => setState(() {
                  if (_showNewCatIconPicker) {
                    _showNewCatIconPicker = false;
                  } else {
                    _collapseAllPickers();
                    _showNewCatIconPicker = true;
                  }
                }),
              ),

              // Name field.
              Expanded(
                child: TextField(
                  controller: _newCatNameController,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Add category...',
                    contentPadding: const .symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        TriOSThemeConstants.cornerRadius,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _createInlineCategory(),
                ),
              ),

              // Add button.
              IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: _newCatNameController.text.trim().isNotEmpty
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                iconSize: 24,
                tooltip: 'Create category',
                onPressed: _createInlineCategory,
              ),
            ],
          ),
        ),

        // Inline color picker for new category.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _showNewCatColorPicker
              ? _InlineColorPicker(
                  selectedColor: _newCatColor,
                  onColorSelected: (color) => setState(() {
                    _newCatColor = color;
                    _showNewCatColorPicker = false;
                  }),
                  onClear: () => setState(() {
                    _newCatColor = null;
                    _showNewCatColorPicker = false;
                  }),
                )
              : const SizedBox.shrink(),
        ),

        // Inline icon picker for new category.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _showNewCatIconPicker
              ? _InlineIconPicker(
                  currentIcon: _newCatIcon,
                  iconColor:
                      _newCatColor ?? Theme.of(context).colorScheme.onSurface,
                  onIconSelected: (icon) => setState(() {
                    _newCatIcon = icon;
                    _showNewCatIconPicker = false;
                  }),
                  onClear: () => setState(() {
                    _newCatIcon = null;
                    _showNewCatIconPicker = false;
                  }),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _createInlineCategory() {
    final name = _newCatNameController.text.trim();
    if (name.isEmpty) return;

    _notifier.createCategory(name, color: _newCatColor, icon: _newCatIcon);
    _newCatNameController.clear();

    // Reset for next creation.
    final store = widget.ref.read(categoryManagerProvider).value;
    setState(() {
      _newCatIcon = null;
      _showNewCatColorPicker = false;
      _showNewCatIconPicker = false;
      _newCatColor = pickAutoColor(_notifier.getAllCategories());
    });
  }

  // ---------------------------------------------------------------------------
  // Reorder.
  // ---------------------------------------------------------------------------

  void _reorderCategories(
    List<Category> categories,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex--;
    final reordered = List<Category>.from(categories);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    _notifier.reorderCategories(reordered.map((c) => c.id).toList());
    setState(() {});
  }
}

// =============================================================================
// Shared sub-widgets.
// =============================================================================

/// A small clickable color circle.
class _ColorCircle extends StatelessWidget {
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Change color',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color ?? Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? colorScheme.onSurface : colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small clickable icon indicator.
class _IconIndicator extends StatelessWidget {
  final CategoryIcon? icon;
  final Color color;
  final bool isSelected;
  final IconData placeholderIcon;
  final VoidCallback onTap;

  const _IconIndicator({
    required this.icon,
    required this.color,
    required this.isSelected,
    this.placeholderIcon = Icons.add,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Change icon',
      child: InkWell(
        borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surfaceContainer : null,
            borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: isSelected ? 0 : 1,
            ),
          ),
          child: Center(
            child:
                icon?.toWidget(size: 20, color: color) ??
                Icon(
                  placeholderIcon,
                  size: 16,
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withAlpha(100),
                ),
          ),
        ),
      ),
    );
  }
}

/// Compact icon button for row actions.
class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      iconSize: 18,
      tooltip: tooltip,
      color: color,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
    );
  }
}

/// An empty circle with a diagonal strikethrough, used as a "none" option
/// inline with color/icon palettes.
class _StrikethroughCircle extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? iconColor;

  const _StrikethroughCircle({
    required this.size,
    required this.onTap,
    this.iconColor,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isSelected
        ? colorScheme.onSurface.mix(iconColor ?? colorScheme.onSurface, 0.5)!
        : colorScheme.outline;
    final borderWidth = isSelected ? 2.0 : 1.0;

    return Tooltip(
      message: 'None',
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            size: Size(size, size),
            painter: _StrikethroughPainter(
              borderColor: borderColor,
              borderWidth: borderWidth,
              lineColor: borderColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _StrikethroughPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final Color lineColor;

  _StrikethroughPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - borderWidth;

    // Draw circle border.
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw diagonal strikethrough, clipped to the circle.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    // Draw from bottom-left to top-right.
    final inset = size.width * 0.15;
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(size.width - inset, inset),
      linePaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StrikethroughPainter oldDelegate) =>
      borderColor != oldDelegate.borderColor ||
      borderWidth != oldDelegate.borderWidth ||
      lineColor != oldDelegate.lineColor;
}

/// Inline color palette picker.
class _InlineColorPicker extends StatelessWidget {
  final Color? selectedColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onClear;

  const _InlineColorPicker({
    required this.selectedColor,
    required this.onColorSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const .fromLTRB(36, 8, 16, 8),
      color: theme.colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StrikethroughCircle(
                size: 24,
                iconColor: selectedColor,
                isSelected: selectedColor == null,
                onTap: onClear,
              ),
              for (final color in categoryColorPalette)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onColorSelected(color),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selectedColor == color
                          ? Border.all(
                              color: theme.colorScheme.onSurface,
                              width: 2,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inline icon picker with SVG + Material sections.
class _InlineIconPicker extends StatelessWidget {
  final CategoryIcon? currentIcon;
  final Color iconColor;
  final ValueChanged<CategoryIcon> onIconSelected;
  final VoidCallback onClear;

  const _InlineIconPicker({
    required this.currentIcon,
    required this.iconColor,
    required this.onIconSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const .fromLTRB(56, 4, 16, 8),
      color: theme.colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text('Custom', style: theme.textTheme.labelSmall),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    TriOSThemeConstants.cornerRadius,
                  ),
                  border: currentIcon == null
                      ? Border.all(color: iconColor, width: 2)
                      : null,
                ),
                child: Center(
                  child: _StrikethroughCircle(
                    size: 24,
                    iconColor: iconColor,
                    isSelected: currentIcon == null,
                    onTap: onClear,
                  ),
                ),
              ),
              for (final icon in categorySvgIcons)
                _buildIconTile(context, icon, theme),
            ],
          ),
          const SizedBox(height: 2),
          Text('Material', style: theme.textTheme.labelSmall),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final icon in categoryMaterialIcons)
                _buildIconTile(context, icon, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconTile(
    BuildContext context,
    CategoryIcon icon,
    ThemeData theme,
  ) {
    final isSelected = currentIcon == icon;
    return InkWell(
      borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
      onTap: () => onIconSelected(icon),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
          border: isSelected
              ? Border.all(color: iconColor, width: 2)
              : Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Center(child: icon.toWidget(size: 20, color: iconColor)),
      ),
    );
  }
}
