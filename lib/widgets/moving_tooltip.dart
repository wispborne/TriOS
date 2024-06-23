import 'package:flutter/material.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/measureable_widget.dart';

import '../utils/logging.dart';

class MovingTooltipWidget extends StatefulWidget {
  final Widget child;
  final Widget tooltipWidget;

  /// The minimum padding from the edge of the window to the tooltip.
  final double windowEdgePadding;

  /// The offset from the mouse position to the tooltip.
  final Size offset;

  const MovingTooltipWidget(
      {super.key,
      required this.child,
      required this.tooltipWidget,
      this.windowEdgePadding = 10.0,
      this.offset = const Size(10, 10)});

  @override
  State<MovingTooltipWidget> createState() => _MovingTooltipWidgetState();
}

class _MovingTooltipWidgetState extends State<MovingTooltipWidget> {
  OverlayEntry? _overlayEntry;
  Size? _tooltipWidgetSize;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => _showTooltip(event.position),
      onHover: (event) => _updateTooltipPosition(event.position),
      onExit: (_) => _hideTooltip(),
      child: widget.child,
    );
  }

  void _showTooltip(Offset mousePosition) {
    _hideTooltip(); // Ensure no previous tooltip lingers

    _overlayEntry = OverlayEntry(builder: (context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final mediaQuery = MediaQuery.of(context);
          final availableHeight = mediaQuery.size.height -
              mediaQuery.padding.top -
              mediaQuery.padding.bottom;
          final availableWidth = mediaQuery.size.width -
              mediaQuery.padding.left -
              mediaQuery.padding.right;

          final upperLimitFromTop =
              (availableHeight - widget.windowEdgePadding) -
                  (_tooltipWidgetSize?.height ?? 0);
          final upperLimitFromLeft =
              (availableWidth - widget.windowEdgePadding) -
                  (_tooltipWidgetSize?.width ?? 0);

          // If we don't have the tooltip size yet, schedule an immediate rebuild.
          // The first build will capture the size, and the second will position the tooltip correctly.
          if (_tooltipWidgetSize == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {});
              }
            });
          }

          return Stack(
            children: [
              Positioned(
                top: _tooltipWidgetSize == null
                    ? -1000
                    : (mousePosition.dy + widget.offset.height).clamp(
                        widget.windowEdgePadding
                            .coerceAtMost(upperLimitFromTop),
                        upperLimitFromTop),
                left: (mousePosition.dx + widget.offset.width).clamp(
                    widget.windowEdgePadding.coerceAtMost(upperLimitFromLeft),
                    upperLimitFromLeft),
                child: Builder(
                  builder: (context) {
                    return MeasurableWidget(
                      child: IgnorePointer(child: widget.tooltipWidget),
                      onSized: (size) {
                        _tooltipWidgetSize = size;
                      },
                      onResized: (size) {
                        _tooltipWidgetSize = size;
                        _updateTooltipPosition(mousePosition);
                      },
                    );
                  },
                ),
              )
            ],
          );
        },
      );
    });

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    // Ensure the tooltip is hidden when the widget is disposed
    // This prevents the tooltip from becoming "stuck" on screen.
    _hideTooltip();
    super.dispose();
  }

  void _updateTooltipPosition(Offset mousePosition) {
    _overlayEntry?.markNeedsBuild();
    _showTooltip(mousePosition);
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
