import 'package:flutter/material.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/mod_tag_manager/category_icon_palette.dart';
import 'package:trios/mod_tag_manager/material_icons_all.dart';
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

class _CategoryIconPickerDialog extends StatefulWidget {
  final CategoryIcon? currentIcon;
  final ValueChanged<CategoryIcon?> onIconSelected;
  final Mod mod;

  const _CategoryIconPickerDialog({
    this.currentIcon,
    required this.onIconSelected,
    required this.mod,
  });

  @override
  State<_CategoryIconPickerDialog> createState() =>
      _CategoryIconPickerDialogState();
}

class _CategoryIconPickerDialogState
    extends State<_CategoryIconPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  List<SvgCategoryIcon> _filteredSvgIcons = categorySvgIcons;
  List<({String name, int codePoint})> _filteredMaterialIcons =
      allMaterialIcons;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final q = value.toLowerCase().trim();
    if (q == _query) return;
    setState(() {
      _query = q;
      if (q.isEmpty) {
        _filteredSvgIcons = categorySvgIcons;
        _filteredMaterialIcons = allMaterialIcons;
      } else {
        _filteredSvgIcons = categorySvgIcons
            .where((icon) => (_svgDisplayNames[icon.assetPath] ?? '').contains(q))
            .toList();
        _filteredMaterialIcons = allMaterialIcons
            .where((icon) => icon.name.replaceAll('_', ' ').contains(q))
            .toList();
      }
    });
  }

  /// Precomputed display names for SVG icons, keyed by asset path.
  static final Map<String, String> _svgDisplayNames = {
    for (final icon in categorySvgIcons)
      icon.assetPath: _computeSvgDisplayName(icon.assetPath),
  };

  /// Extracts a human-readable name from an SVG asset path.
  /// e.g. `assets/images/icon-death-star.svg` → `death star`
  static String _computeSvgDisplayName(String assetPath) {
    var name = assetPath.split('/').last;
    name = name.replaceFirst('icon-', '');
    name = name.replaceFirst('.svg', '');
    return name.replaceAll('-', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface;

    return AlertDialog(
      title: Text("Icon for ${widget.mod.name}"),
      content: SizedBox(
        width: 480,
        height: 520,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search icons...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredSvgIcons.isEmpty &&
                      _filteredMaterialIcons.isEmpty
                  ? const Center(child: Text('No icons found'))
                  : CustomScrollView(
                      slivers: [
                        // Custom SVG icons section
                        if (_filteredSvgIcons.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Custom',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final icon in _filteredSvgIcons)
                                  _buildCategoryIconTile(
                                    context,
                                    icon,
                                    iconColor,
                                    tooltip: _svgDisplayNames[icon.assetPath],
                                  ),
                              ],
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 16),
                          ),
                        ],

                        // Material icons section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Material',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ),
                        if (_filteredMaterialIcons.isNotEmpty)
                          SliverGrid.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 10,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: _filteredMaterialIcons.length,
                            itemBuilder: (context, index) {
                              final entry =
                                  _filteredMaterialIcons[index];
                              final icon = MaterialCategoryIcon(
                                entry.codePoint,
                              );
                              return _buildCategoryIconTile(
                                context,
                                icon,
                                iconColor,
                                tooltip: entry.name
                                    .replaceAll('_', ' '),
                              );
                            },
                          )
                        else
                          const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child:
                                    Text('No material icons found'),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onIconSelected(null);
            Navigator.of(context).pop();
          },
          child: const Text('No Icon'),
        ),
      ],
    );
  }

  Widget _buildCategoryIconTile(
    BuildContext context,
    CategoryIcon icon,
    Color iconColor, {
    String? tooltip,
  }) {
    final isSelected = widget.currentIcon == icon;
    final tile = GestureDetector(
      onTap: () {
        widget.onIconSelected(icon);
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
              : Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
        ),
        child: Center(child: icon.toWidget(size: 24, color: iconColor)),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: tile);
    }
    return tile;
  }

}
