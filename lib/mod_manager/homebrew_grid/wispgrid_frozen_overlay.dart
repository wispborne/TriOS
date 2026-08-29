import 'package:material_ui/material_ui.dart';

/// Draws the frozen columns a second time, held at the left edge of the grid's
/// visible area while everything else scrolls sideways.
///
/// This lives inside the grid's horizontal scroll view, so it cancels the
/// scroll by shifting itself right by the same amount. While the grid is
/// scrolled all the way left the real columns are already in the right place,
/// so nothing is drawn.
///
/// Must be a direct child of a [Stack] that spans the full grid width.
class WispGridFrozenOverlay extends StatelessWidget {
  /// The grid's horizontal scroll controller.
  final ScrollController horizontalScrollController;

  /// How wide the frozen block is, measured from the grid's left edge to
  /// where the first unfrozen column starts.
  final double width;

  /// How wide [child] wants to be laid out. Row content fits inside [width];
  /// group headers are laid out at the full grid width and clipped.
  final double? contentWidth;

  final Widget child;

  const WispGridFrozenOverlay({
    super.key,
    required this.horizontalScrollController,
    required this.width,
    required this.child,
    this.contentWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: width,
      child: AnimatedBuilder(
        animation: horizontalScrollController,
        builder: (context, _) {
          final offset = horizontalScrollController.hasClients
              ? horizontalScrollController.offset
              : 0.0;
          if (offset <= 0) return const SizedBox.shrink();

          return Transform.translate(
            offset: Offset(offset, 0),
            child: Container(
              decoration: BoxDecoration(
                // Opaque, or the scrolled-past columns show through.
                color: theme.colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: contentWidth ?? width,
                  maxWidth: contentWidth ?? width,
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
