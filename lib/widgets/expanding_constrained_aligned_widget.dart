import 'package:flutter/material.dart';

/// A convenience widget for rows/toolbars:
/// - Expands to take available space (like Flexible).
/// - Constrains its child's width between [minWidth] and [maxWidth].
/// - Aligns the child within that slot using [alignment].
///
/// Typical use:
///   FlexibleConstrainedSlot(
///     minWidth: 200,
///     maxWidth: 350,
///     alignment: Alignment.centerRight,
///     child: buildSearchBox(),
///   )
class ExpandingConstrainedAlignedWidget extends StatelessWidget {
  const ExpandingConstrainedAlignedWidget({
    super.key,
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.alignment = Alignment.centerLeft,
    this.flex = 1,
    required this.child,
  });

  final double minWidth;
  final double maxWidth;
  final Alignment alignment;
  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
