import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/moving_tooltip.dart';

import 'category_context_menu.dart';

/// A cell widget for the categories column in the mods grid.
/// Shows the primary category with a color dot and name,
/// plus a +N suffix if additional categories are assigned.
class CategoryCell extends ConsumerStatefulWidget {
  final String modId;
  final Set<String> checkedModIds;

  const CategoryCell({
    super.key,
    required this.modId,
    this.checkedModIds = const {},
  });

  @override
  ConsumerState<CategoryCell> createState() => _CategoryCellState();
}

class _CategoryCellState extends ConsumerState<CategoryCell> {
  bool _isRenaming = false;
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

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(categoryManagerProvider).value;
    if (store == null) return const SizedBox.shrink();

    final notifier = ref.read(categoryManagerProvider.notifier);
    final categories = notifier.getCategoriesForMod(widget.modId);
    final primaryCategory = notifier.getPrimaryCategory(widget.modId);
    final extraCount = categories.length - 1;
    final theme = Theme.of(context);

    if (_isRenaming && primaryCategory != null) {
      return _buildRenameField(primaryCategory, notifier);
    }

    final isBatchSelection =
        widget.checkedModIds.length > 1 &&
        widget.checkedModIds.contains(widget.modId);

    return ContextMenuRegion(
      contextMenu: isBatchSelection
          ? buildCategoryBatchContextMenu(
              modIds: widget.checkedModIds,
              ref: ref,
              context: context,
            )
          : buildCategoryCellContextMenu(
              modId: widget.modId,
              ref: ref,
              context: context,
            ),
      child: GestureDetector(
        onDoubleTap: primaryCategory != null
            ? () {
                setState(() {
                  _isRenaming = true;
                  _renameController.text = primaryCategory.name;
                });
              }
            : null,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 32),
          color: Colors.transparent, // For hit testing
          child: primaryCategory == null
              ? null
              : Opacity(
                  opacity: WispGrid.lightTextOpacity,
                  child: Row(
                    spacing: 8,
                    children: [
                      ConditionalWrap(
                        condition: extraCount > 0,
                        wrapper: (child) => MovingTooltipWidget.text(
                          message:
                              (categories.toList()..sort((a, b) {
                                    if (a == primaryCategory) return -1;
                                    if (b == primaryCategory) return 1;
                                    return a.name.compareTo(b.name);
                                  }))
                                  .joinToString(
                                    separator: "\n",
                                    transform: (cat) => cat.name,
                                  ),
                          child: child,
                        ),
                        child: Expanded(
                          child: Text(
                            primaryCategory.name +
                                (extraCount > 0 ? ' +$extraCount' : ''),
                            style: theme.textTheme.labelLarge,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRenameField(
    Category primaryCategory,
    CategoryManagerNotifier notifier,
  ) {
    return TextField(
      controller: _renameController,
      autofocus: true,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        border: OutlineInputBorder(),
      ),
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) {
          notifier.updateCategory(primaryCategory.id, name: value.trim());
        }
        setState(() => _isRenaming = false);
      },
      onTapOutside: (_) {
        setState(() => _isRenaming = false);
      },
    );
  }
}
