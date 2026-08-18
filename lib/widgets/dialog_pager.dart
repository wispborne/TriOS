import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Pages a details dialog through a list of items without closing it.
///
/// Holds the current position in [items], steps on arrow keys, and hands
/// [itemBuilder] a Previous/Next button pair to place wherever the dialog
/// wants it (the details dialogs put it top-right, next to Close). Moving is a
/// rebuild inside the open dialog, not a new route, so the grid behind the
/// dialog keeps its scroll position.
class DialogPager<T> extends StatefulWidget {
  /// The items to page through, in display order. Must not be empty.
  final List<T> items;

  final int startIndex;

  /// Builds the dialog's contents for [item]. [pagerControls] is the
  /// Previous/Next button pair, for the dialog to place in its own layout.
  final Widget Function(BuildContext context, T item, Widget pagerControls)
  itemBuilder;

  const DialogPager({
    super.key,
    required this.items,
    required this.startIndex,
    required this.itemBuilder,
  });

  @override
  State<DialogPager<T>> createState() => _DialogPagerState<T>();
}

class _DialogPagerState<T> extends State<DialogPager<T>> {
  late int _index = widget.startIndex.clamp(0, widget.items.length - 1);

  void _step(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.items.length) return;
    setState(() => _index = next);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    // KeyRepeatEvent counts too, so holding the key keeps stepping.
    if (event is KeyUpEvent) return KeyEventResult.ignored;

    // Key events climb from the focused widget up through its ancestors, and
    // the text-editing arrow-key shortcuts live at the app root — above this
    // Focus. So when the user is in a text field or selected text, step aside
    // or we'd steal the arrow keys before those shortcuts see them.
    final inEditableText =
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorStateOfType<EditableTextState>() !=
        null;
    if (inEditableText) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      _step(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown) {
      _step(1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildControls() {
    if (widget.items.length < 2) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MovingTooltipWidget.text(
          message: 'Previous (Left arrow)',
          child: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _index > 0 ? () => _step(-1) : null,
          ),
        ),
        MovingTooltipWidget.text(
          message: 'Next (Right arrow)',
          child: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _index < widget.items.length - 1
                ? () => _step(1)
                : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      // The new key on each move gives the body fresh state, so its scroll
      // view starts at the top.
      child: KeyedSubtree(
        key: ValueKey(_index),
        child: widget.itemBuilder(
          context,
          widget.items[_index],
          _buildControls(),
        ),
      ),
    );
  }
}
