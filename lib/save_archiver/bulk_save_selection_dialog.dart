import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/save_archiver/size_stat.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';

class SaveSelectionItem {
  final String id;

  final String title;
  final String subtitle;

  final int sizeInBytes;

  /// Shown beside the size when set.
  final int? estimatedSavingsInBytes;

  /// How much space the save takes up once restored. Shown beside the size
  /// when set.
  final int? restoredSizeInBytes;

  /// Disabled rows are excluded from the returned selection.
  final bool selectable;
  final String? blockedReason;

  const SaveSelectionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sizeInBytes,
    this.estimatedSavingsInBytes,
    this.restoredSizeInBytes,
    this.selectable = true,
    this.blockedReason,
  });
}

class BulkSaveSelection {
  /// Disabled rows are never included.
  final Set<String> ids;

  /// Whether the dialog's checkbox was ticked. False when it had none.
  final bool checkboxTicked;

  const BulkSaveSelection({required this.ids, required this.checkboxTicked});
}

/// Returns the selection, or null on cancellation. The caller should act only
/// on the returned IDs.
///
/// [checkboxLabel] adds a checkbox under the totals, unticked at the start.
Future<BulkSaveSelection?> showBulkSaveSelectionDialog({
  required BuildContext context,
  required String title,
  required String explanation,
  required List<SaveSelectionItem> items,
  required Set<String> initiallySelected,
  required String Function(int count) confirmLabel,
  required IconData confirmIcon,
  String? estimateTooltip,
  String? checkboxLabel,
}) => showDialog<BulkSaveSelection>(
  context: context,
  builder: (context) => _BulkSaveSelectionDialog(
    title: title,
    explanation: explanation,
    items: items,
    initiallySelected: initiallySelected,
    confirmLabel: confirmLabel,
    confirmIcon: confirmIcon,
    estimateTooltip: estimateTooltip,
    checkboxLabel: checkboxLabel,
  ),
);

class _BulkSaveSelectionDialog extends StatefulWidget {
  final String title;
  final String explanation;
  final List<SaveSelectionItem> items;
  final Set<String> initiallySelected;
  final String Function(int count) confirmLabel;
  final IconData confirmIcon;

  /// Shown on hover over the total estimated savings.
  final String? estimateTooltip;

  final String? checkboxLabel;

  const _BulkSaveSelectionDialog({
    required this.title,
    required this.explanation,
    required this.items,
    required this.initiallySelected,
    required this.confirmLabel,
    required this.confirmIcon,
    required this.estimateTooltip,
    required this.checkboxLabel,
  });

  @override
  State<_BulkSaveSelectionDialog> createState() =>
      _BulkSaveSelectionDialogState();
}

class _BulkSaveSelectionDialogState extends State<_BulkSaveSelectionDialog> {
  final _scrollController = ScrollController();
  late Set<String> _selected = _onlySelectable(widget.initiallySelected);
  var _checkboxTicked = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Set<String> _onlySelectable(Set<String> ids) => widget.items
      .where((item) => item.selectable && ids.contains(item.id))
      .map((item) => item.id)
      .toSet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.textTheme.labelSmall?.color?.withAlpha(180);
    final selectedItems = widget.items
        .where((item) => _selected.contains(item.id))
        .toList();
    final totalBytes = selectedItems.map((item) => item.sizeInBytes).sum;
    final hasEstimates = widget.items.any(
      (item) => item.estimatedSavingsInBytes != null,
    );
    final totalSavings = selectedItems
        .map((item) => item.estimatedSavingsInBytes ?? 0)
        .sum;
    final hasRestoredSizes = widget.items.any(
      (item) => item.restoredSizeInBytes != null,
    );
    final totalRestoredSize = selectedItems
        .map((item) => item.restoredSizeInBytes ?? 0)
        .sum;
    final missingRestoredSizeCount = selectedItems
        .where((item) => item.restoredSizeInBytes == null)
        .length;
    final selectableCount = widget.items
        .where((item) => item.selectable)
        .length;

    final restoredSizeStat = SizeStat(
      label: 'Space needed',
      value: totalRestoredSize.bytesAsReadable(),
    );

    final savingsStat = SizeStat(
      label: 'Space saved (estimate)',
      value: '~${totalSavings.bytesAsReadable()}',
    );

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(widget.title),
          Text(
            widget.explanation,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.textTheme.labelMedium?.color?.withAlpha(180),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Flexible(
              child: widget.items.isEmpty
                  ? Padding(
                      padding: const .symmetric(vertical: 24),
                      child: Text(
                        'Nothing here yet.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      controller: _scrollController,
                      child: ListView.separated(
                        controller: _scrollController,
                        shrinkWrap: true,
                        itemCount: widget.items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _buildRow(theme, widget.items[index], mutedColor),
                      ),
                    ),
            ),
            const Divider(height: 1),
            Row(
              spacing: 32,
              children: [
                SizeStat(
                  label: 'Selected',
                  value: '${_selected.length} of $selectableCount',
                ),
                SizeStat(
                  label: 'Total size',
                  value: totalBytes.bytesAsReadable(),
                ),
                if (hasEstimates)
                  widget.estimateTooltip == null
                      ? savingsStat
                      : MovingTooltipWidget.text(
                          message: widget.estimateTooltip!,
                          child: savingsStat,
                        ),
                if (hasRestoredSizes)
                  missingRestoredSizeCount == 0
                      ? restoredSizeStat
                      : MovingTooltipWidget.text(
                          message:
                              'Leaves out $missingRestoredSizeCount '
                              'archive${missingRestoredSizeCount == 1 ? '' : 's'} '
                              'with no recorded original size.',
                          child: restoredSizeStat,
                        ),
              ],
            ),
            if (widget.checkboxLabel case final label?)
              CheckboxListTile(
                value: _checkboxTicked,
                onChanged: (value) =>
                    setState(() => _checkboxTicked = value == true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(label),
              ),
          ],
        ),
      ),
      actionsAlignment: .spaceBetween,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            TextButton(
              onPressed: selectableCount == 0
                  ? null
                  : () => setState(
                      () => _selected = widget.items
                          .where((item) => item.selectable)
                          .map((item) => item.id)
                          .toSet(),
                    ),
              child: const Text('Select all'),
            ),
            TextButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => setState(() => _selected = {}),
              child: const Text('Select none'),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            Disable(
              isEnabled: _selected.isNotEmpty,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(
                  BulkSaveSelection(
                    ids: _selected,
                    checkboxTicked: _checkboxTicked,
                  ),
                ),
                icon: Icon(widget.confirmIcon),
                label: Text(widget.confirmLabel(_selected.length)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(ThemeData theme, SaveSelectionItem item, Color? mutedColor) {
    final checked = _selected.contains(item.id);

    void toggle(bool? value) {
      if (!item.selectable) return;
      setState(() {
        if (value == true) {
          _selected.add(item.id);
        } else {
          _selected.remove(item.id);
        }
      });
    }

    final row = InkWell(
      onTap: item.selectable ? () => toggle(!checked) : null,
      child: Padding(
        padding: const .symmetric(vertical: 6),
        child: Row(
          spacing: 8,
          children: [
            Checkbox(
              value: checked,
              onChanged: item.selectable ? toggle : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  Text(
                    item.blockedReason ?? item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: item.selectable
                          ? mutedColor
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            if (item.sizeInBytes > 0)
              Padding(
                padding: const .only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.sizeInBytes.bytesAsReadable(),
                      style: theme.textTheme.labelMedium,
                    ),
                    if (item.estimatedSavingsInBytes case final savings?)
                      Text(
                        '~${savings.bytesAsReadable()} saved',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                    if (item.restoredSizeInBytes case final restored?)
                      Text(
                        '${restored.bytesAsReadable()} when restored',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    final reason = item.blockedReason;
    if (!item.selectable && reason != null) {
      return MovingTooltipWidget.text(message: reason, child: row);
    }
    return row;
  }
}
