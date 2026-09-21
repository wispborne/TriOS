import 'package:material_ui/material_ui.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// One tickable row in [showBulkSaveSelectionDialog].
class SaveSelectionItem {
  /// Identifies the row. The dialog hands back the ids that were ticked.
  final String id;

  final String title;
  final String subtitle;

  /// Size in bytes, shown on the right and added up at the bottom.
  final int sizeInBytes;

  /// When false the row can't be ticked, and [blockedReason] says why.
  final bool selectable;
  final String? blockedReason;

  const SaveSelectionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sizeInBytes,
    this.selectable = true,
    this.blockedReason,
  });
}

/// The "newest N" spinner at the top of the dialog.
///
/// Changing it replaces the ticks with whatever [selectionFor] returns, so it
/// is a starting point rather than a rule — every tick can still be changed by
/// hand afterwards.
class SaveSelectionCountFilter {
  /// Words either side of the number, e.g. "Keep the newest" … "saves".
  final String prefixLabel;
  final String suffixLabel;

  final int initialValue;
  final int maxValue;

  /// The ids to tick for a given number.
  final Set<String> Function(int value) selectionFor;

  /// Called when the number settles, for remembering it between openings.
  final void Function(int value)? onValueChanged;

  const SaveSelectionCountFilter({
    required this.prefixLabel,
    required this.suffixLabel,
    required this.initialValue,
    required this.maxValue,
    required this.selectionFor,
    this.onValueChanged,
  });
}

/// Asks which saves or archives to act on, and returns the ticked ids.
///
/// Returns null when the person backs out. Every row starts out exactly as
/// [initiallySelected] says, and nothing outside the returned set is ever
/// touched by the caller — the point of the dialog is that the list in front of
/// somebody is the list that gets acted on.
Future<Set<String>?> showBulkSaveSelectionDialog({
  required BuildContext context,
  required String title,
  required String explanation,
  required List<SaveSelectionItem> items,
  required Set<String> initiallySelected,
  required String Function(int count) confirmLabel,
  required IconData confirmIcon,
  SaveSelectionCountFilter? countFilter,
  String? warning,
}) => showDialog<Set<String>>(
  context: context,
  builder: (context) => _BulkSaveSelectionDialog(
    title: title,
    explanation: explanation,
    items: items,
    initiallySelected: initiallySelected,
    confirmLabel: confirmLabel,
    confirmIcon: confirmIcon,
    countFilter: countFilter,
    warning: warning,
  ),
);

class _BulkSaveSelectionDialog extends StatefulWidget {
  final String title;
  final String explanation;
  final List<SaveSelectionItem> items;
  final Set<String> initiallySelected;
  final String Function(int count) confirmLabel;
  final IconData confirmIcon;
  final SaveSelectionCountFilter? countFilter;
  final String? warning;

  const _BulkSaveSelectionDialog({
    required this.title,
    required this.explanation,
    required this.items,
    required this.initiallySelected,
    required this.confirmLabel,
    required this.confirmIcon,
    required this.countFilter,
    required this.warning,
  });

  @override
  State<_BulkSaveSelectionDialog> createState() =>
      _BulkSaveSelectionDialogState();
}

class _BulkSaveSelectionDialogState extends State<_BulkSaveSelectionDialog> {
  final _scrollController = ScrollController();
  late Set<String> _selected = _onlySelectable(widget.initiallySelected);
  late int _countValue = widget.countFilter?.initialValue ?? 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Set<String> _onlySelectable(Set<String> ids) => widget.items
      .where((item) => item.selectable && ids.contains(item.id))
      .map((item) => item.id)
      .toSet();

  void _applyCount(int value) {
    final filter = widget.countFilter;
    if (filter == null) return;
    final clamped = value.clamp(0, filter.maxValue);
    setState(() {
      _countValue = clamped;
      _selected = _onlySelectable(filter.selectionFor(clamped));
    });
    filter.onValueChanged?.call(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedItems = widget.items
        .where((item) => _selected.contains(item.id))
        .toList();
    final totalBytes = selectedItems.fold<int>(
      0,
      (total, item) => total + item.sizeInBytes,
    );
    final selectableCount = widget.items
        .where((item) => item.selectable)
        .length;

    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(widget.explanation, style: theme.textTheme.bodyMedium),
            if (widget.countFilter != null) _buildCountFilter(theme),
            const Divider(height: 8),
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
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Padding(
                          padding: const .only(right: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final item in widget.items)
                                _buildRow(theme, item),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            const Divider(height: 8),
            Row(
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
                Expanded(
                  child: Text(
                    '${_selected.length} of $selectableCount selected'
                    '${totalBytes > 0 ? ' · ${totalBytes.bytesAsReadable()}' : ''}',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            if (widget.warning != null)
              Text(
                widget.warning!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Disable(
          isEnabled: _selected.isNotEmpty,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).pop(_selected),
            icon: Icon(widget.confirmIcon),
            label: Text(widget.confirmLabel(_selected.length)),
          ),
        ),
      ],
    );
  }

  Widget _buildCountFilter(ThemeData theme) {
    final filter = widget.countFilter!;
    return Row(
      spacing: 8,
      children: [
        Text(filter.prefixLabel, style: theme.textTheme.bodyMedium),
        IconButton(
          icon: const Icon(Icons.remove),
          iconSize: 18,
          onPressed: _countValue <= 0
              ? null
              : () => _applyCount(_countValue - 1),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$_countValue',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          iconSize: 18,
          onPressed: _countValue >= filter.maxValue
              ? null
              : () => _applyCount(_countValue + 1),
        ),
        Text(filter.suffixLabel, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildRow(ThemeData theme, SaveSelectionItem item) {
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
        padding: const .symmetric(vertical: 2),
        child: Row(
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
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    item.blockedReason ?? item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: item.selectable
                          ? theme.textTheme.labelSmall?.color?.withAlpha(180)
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            if (item.sizeInBytes > 0)
              Padding(
                padding: const .only(left: 8),
                child: Text(
                  item.sizeInBytes.bytesAsReadable(),
                  style: theme.textTheme.labelMedium,
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
