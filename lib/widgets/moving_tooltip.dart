import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/measureable_widget.dart';
import 'package:window_size/window_size.dart';

class MovingTooltipWidget extends StatefulWidget {
  final Widget child;
  final Widget tooltipWidget;

  const MovingTooltipWidget(
      {super.key, required this.child, required this.tooltipWidget});

  @override
  State<MovingTooltipWidget> createState() => _MovingTooltipWidgetState();
}

class _MovingTooltipWidgetState extends State<MovingTooltipWidget> {
  OverlayEntry? _overlayEntry;
  Size? _windowSize;
  Size? _tooltipWidgetSize;

  @override
  void initState() {
    super.initState();
    _getWindowSize();
  }

  Future<void> _getWindowSize() async {
    if (!mounted) return;
    final windowInfo = await getWindowInfo();
    setState(() {
      _windowSize = windowInfo.frame.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => _showTooltip(event.position),
      onHover: (event) => _updateTooltipPosition(event.position),
      onExit: (_) => _hideTooltip(),
      child: widget.child,
    );
  }

  void _showTooltip(Offset position) {
    _hideTooltip(); // Ensure no previous tooltip lingers

    _overlayEntry = OverlayEntry(builder: (context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          const offset = Size(10, 10);
          const edgePadding = 20.0;

          final upperLimitFromTop =
              ((_windowSize?.height.minus(edgePadding) ?? double.infinity)) -
                  (_tooltipWidgetSize?.height ?? 0);

          final upperLimitFromLeft =
              ((((_windowSize?.width.minus(edgePadding) ?? 0)) -
                  ((_tooltipWidgetSize?.width ?? 0))));

          // If we don't have the tooltip size yet, schedule an immediate rebuild.
          // The first build will capture the size, and the second will position the tooltip correctly.
          if (_tooltipWidgetSize == null) {
            // schedule next frame
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
                    : (position.dy + offset.height).clamp(
                        edgePadding.coerceAtMost(upperLimitFromTop),
                        upperLimitFromTop),
                left: (position.dx + offset.width).clamp(
                    edgePadding.coerceAtMost(upperLimitFromLeft),
                    upperLimitFromLeft),
                child: Builder(builder: (context) {
                  return MeasurableWidget(
                    child: IgnorePointer(child: widget.tooltipWidget),
                    onSized: (size) {
                      _tooltipWidgetSize = size;
                    },
                  );
                  // testTooltipContainer(position);
                }),
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

  void _updateTooltipPosition(Offset position) {
    _overlayEntry?.markNeedsBuild();
    _showTooltip(position);
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
