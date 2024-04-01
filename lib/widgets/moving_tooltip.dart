import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

class MovingTooltipWidget extends StatefulWidget {
  final Widget child;
  final Widget tooltipWidget;

  const MovingTooltipWidget({super.key, required this.child, required this.tooltipWidget});

  @override
  State<MovingTooltipWidget> createState() => _MovingTooltipWidgetState();
}

class _MovingTooltipWidgetState extends State<MovingTooltipWidget> {
  OverlayEntry? _overlayEntry;
  Size? _windowSize;

  @override
  void initState() {
    super.initState();
    _getWindowSize();
  }

  Future<void> _getWindowSize() async {
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
          final bool isLeft = position.dx < (_windowSize?.width ?? double.infinity) / 2;
          final bool isTop = position.dy < (_windowSize?.height ?? double.infinity) / 2;
          return Stack(
            children: [
              // Not the ideal way of doing it but a simple shortcut that works as long as the panel is small.
              if (isLeft && isTop)
                Positioned(
                  top: position.dy.clamp(0, (_windowSize?.height ?? double.infinity)),
                  left: position.dx.clamp(0, (_windowSize?.width ?? double.infinity)),
                  child: widget.tooltipWidget,
                )
              else if (!isLeft && isTop)
                Positioned(
                  top: position.dy.clamp(0, (_windowSize?.height ?? double.infinity)),
                  right: (_windowSize?.width ?? double.infinity) - position.dx,
                  child: widget.tooltipWidget,
                )
              else if (isLeft && !isTop)
                Positioned(
                  bottom: (_windowSize?.height ?? double.infinity) - position.dy,
                  left: position.dx.clamp(0, (_windowSize?.width ?? double.infinity)),
                  child: widget.tooltipWidget,
                )
              else if (!isLeft && !isTop)
                Positioned(
                  bottom: (_windowSize?.height ?? double.infinity) - position.dy,
                  right: (_windowSize?.width ?? double.infinity) - position.dx,
                  child: widget.tooltipWidget,
                ),
            ],
          );
        },
      );
    });

    Overlay.of(context).insert(_overlayEntry!);
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
