import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trios/utils/extensions.dart';
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
  final GlobalKey _tooltipKey = GlobalKey();

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
          final bool isLeft =
              position.dx < (_windowSize?.width ?? double.infinity) / 2;
          final bool isTop =
              position.dy < (_windowSize?.height ?? double.infinity) / 2;
          const offset = Size(10, 10);
          const edgePadding = 10.0;

          return Stack(
            children: [
              Positioned(
                top: (position.dy + offset.height).clamp(
                    edgePadding,
                    ((_windowSize?.height.minus(edgePadding) ??
                            double.infinity)) -
                        (_tooltipWidgetSize?.height ?? 0)),
                left: (position.dx + offset.width).clamp(
                    edgePadding,
                    ((((_windowSize?.width.minus(edgePadding) ?? 0)) -
                            ((_tooltipWidgetSize?.width ?? 0))) ??
                        double.infinity)),
                child: Material(
                  key: _tooltipKey,
                  child: Builder(builder: (context) {
                    _tooltipWidgetSize ??= (_tooltipKey.currentContext
                            ?.findRenderObject() as RenderBox?)
                        ?.size;

                    return widget.tooltipWidget;
                    // testTooltipContainer(position);
                  }),
                ),
              )
            ],
          );
        },
      );
    });

    Overlay.of(context).insert(_overlayEntry!);
  }

  SizedBox testTooltipContainer(Offset position) {
    return SizedBox(
        width: 200,
        height: 100,
        child: Container(
            color: Colors.black,
            child: Text(
              "Tooltip: ${_tooltipWidgetSize?.width}, ${_tooltipWidgetSize?.height}"
              "\nCoords: ${position.dx}, ${position.dy}"
              "\nWindow: ${_windowSize?.width}, ${_windowSize?.height}",
            )));
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
