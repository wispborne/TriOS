import 'package:material_ui/material_ui.dart';
import 'package:trios/widgets/filter_engine/filter_group.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persist_button.dart';
import 'package:trios/widgets/filter_engine/filter_scope.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';

/// Two-handle slider for a [RangeFilterGroup], e.g. "deployment points
/// between 10 and 30".
///
/// The track is one notch per number that exists in the data, all the same
/// width — it isn't to scale. Ship hull runs from 30 to ten million, so a
/// to-scale track would bunch every real warship into its first sliver.
///
/// When the group allows it, the top handle at the far right reads as "and
/// above" so nothing falls off the end.
class RangeFilterWidget<T> extends StatefulWidget {
  final RangeFilterGroup<T> group;
  final FilterScope scope;
  final VoidCallback onChanged;

  const RangeFilterWidget({
    super.key,
    required this.group,
    required this.scope,
    required this.onChanged,
  });

  @override
  State<RangeFilterWidget<T>> createState() => _RangeFilterWidgetState<T>();
}

class _RangeFilterWidgetState<T> extends State<RangeFilterWidget<T>> {
  /// Handle positions (as stop numbers, not values) while the user drags.
  /// Cleared on release, when the group's own values take over again.
  RangeValues? _dragging;

  String _format(num value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  /// The selected range as text, e.g. "10–40", "20+" or "Any".
  String get _rangeLabel {
    final group = widget.group;
    final suffix = group.suffix == null ? '' : ' ${group.suffix}';
    if (!group.isActive) return 'Any';
    final atTop = group.curMax >= group.max;
    if (atTop && group.allowGreater) {
      return '${_format(group.curMin)}+$suffix';
    }
    return '${_format(group.curMin)}–${_format(group.curMax)}$suffix';
  }

  /// The value a handle sits on, given its position on the track.
  num _valueAt(double position) {
    final stops = widget.group.stops;
    if (stops.isEmpty) return widget.group.min;
    return stops[position.round().clamp(0, stops.length - 1)];
  }

  // Positions are whole numbers, so the handles step from one real value to
  // the next as you drag.
  void _onChanged(RangeValues positions) {
    setState(
      () => _dragging = RangeValues(
        positions.start.roundToDouble(),
        positions.end.roundToDouble(),
      ),
    );
  }

  void _onChangeEnd(RangeValues positions) {
    widget.group.setRange(_valueAt(positions.start), _valueAt(positions.end));
    setState(() => _dragging = null);
    widget.onChanged();
  }

  void _reset() {
    widget.group.clear();
    setState(() => _dragging = null);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = widget.group;

    // Nothing to slide over — no data, or every item has the same value.
    if (!group.hasData || group.stops.length < 2) {
      return const SizedBox.shrink();
    }

    // Handle positions are notch numbers, not the values themselves.
    final positions =
        _dragging ??
        RangeValues(
          group.stopIndexFor(group.curMin).toDouble(),
          group.stopIndexFor(group.curMax).toDouble(),
        );

    return Card(
      margin: const .symmetric(horizontal: 4, vertical: 1),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const .symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Expanded with no Spacer after it, so the name gets all the
                // room the range text and buttons don't need.
                Expanded(
                  child: Padding(
                    padding: const .only(left: 8, right: 4, top: 2, bottom: 2),
                    child: TextTriOS(
                      group.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Text(
                  _dragging == null
                      ? _rangeLabel
                      : '${_format(_valueAt(positions.start))}–'
                            '${_format(_valueAt(positions.end))}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: group.isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: group.isActive ? FontWeight.bold : null,
                  ),
                ),
                if (group.isActive)
                  MovingTooltipWidget.text(
                    message: 'Reset this range',
                    child: IconButton(
                      onPressed: _reset,
                      icon: const Icon(Icons.close, size: 16),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(24, 28),
                        maximumSize: const Size(24, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                FilterGridPersistButton(
                  scope: widget.scope,
                  filterGroupId: group.id,
                  currentSelections: () => group.serialize(),
                ),
              ],
            ),
            // The slider hands the handle you grab keyboard focus and then
            // rings it until something else takes the focus away. Nothing
            // does, and the handles can't be moved by keyboard anyway, so
            // keep them out of the focus tree.
            ExcludeFocus(
              child: RangeSlider(
                // Without this the slider is as tall as its invisible touch
                // area (48), which is more than twice the handle.
                padding: const .symmetric(horizontal: 4, vertical: 2),
                min: 0,
                max: (group.stops.length - 1).toDouble(),
                values: positions,
                onChanged: _onChanged,
                onChangeEnd: _onChangeEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
