import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/widgets/tooltip_frame.dart';

enum TooltipPosition { topLeft, topRight, bottomLeft, bottomRight }

/// A render object that positions the tooltip based on mouse position.
class _TooltipRenderBox extends RenderShiftedBox {
  Offset _mousePosition;
  double _windowEdgePadding;
  Size _offset;
  TooltipPosition _position;
  MediaQueryData _mediaQuery;

  _TooltipRenderBox({
    RenderBox? child,
    required Offset mousePosition,
    required double windowEdgePadding,
    required Size offset,
    required TooltipPosition position,
    required MediaQueryData mediaQuery,
  })  : _mousePosition = mousePosition,
        _windowEdgePadding = windowEdgePadding,
        _offset = offset,
        _position = position,
        _mediaQuery = mediaQuery,
        super(child);

  set mousePosition(Offset value) {
    if (_mousePosition != value) {
      _mousePosition = value;
      markNeedsLayout();
    }
  }

  set windowEdgePadding(double value) {
    if (_windowEdgePadding != value) {
      _windowEdgePadding = value;
      markNeedsLayout();
    }
  }

  set offset(Size value) {
    if (_offset != value) {
      _offset = value;
      markNeedsLayout();
    }
  }

  set position(TooltipPosition value) {
    if (_position != value) {
      _position = value;
      markNeedsLayout();
    }
  }

  set mediaQuery(MediaQueryData value) {
    if (_mediaQuery != value) {
      _mediaQuery = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    child?.layout(constraints.loosen(), parentUsesSize: true);
    final childSize = child?.size ?? Size.zero;
    size = constraints.biggest;

    final maxWidth = size.width;
    final maxHeight = size.height;
    final availableHeight =
        maxHeight - _mediaQuery.padding.top - _mediaQuery.padding.bottom;
    final availableWidth =
        maxWidth - _mediaQuery.padding.left - _mediaQuery.padding.right;

    final upperLimitFromTop =
        (availableHeight - _windowEdgePadding) - childSize.height;
    final upperLimitFromLeft =
        (availableWidth - _windowEdgePadding) - childSize.width;

    double top = 0;
    double left = 0;

    switch (_position) {
      case TooltipPosition.topLeft:
        top = (_mousePosition.dy - (_offset.height + childSize.height)).clamp(
          _windowEdgePadding,
          math.max(_windowEdgePadding, upperLimitFromTop),
        );
        left = (_mousePosition.dx - (_offset.width + childSize.width)).clamp(
          _windowEdgePadding,
          math.max(_windowEdgePadding, upperLimitFromLeft),
        );
        break;
      case TooltipPosition.topRight:
        top = (_mousePosition.dy - (_offset.height + childSize.height)).clamp(
          _windowEdgePadding,
          math.max(_windowEdgePadding, upperLimitFromTop),
        );
        left = (_mousePosition.dx + _offset.width).clamp(
          _windowEdgePadding,
          math.max(_windowEdgePadding, upperLimitFromLeft),
        );
        break;
      case TooltipPosition.bottomLeft:
        top = (_mousePosition.dy + _offset.height).clamp(
          _windowEdgePadding,
          math.max(_windowEdgePadding, upperLimitFromTop),
        );
        left = (_mousePosition.dx - (_offset.width + childSize.width)).clamp(
          _windowEdgePadding,
          math.max(_windowEdgePadding, upperLimitFromLeft),
        );
        break;
      case TooltipPosition.bottomRight:
        top = (_mousePosition.dy + _offset.height).clamp(
          _windowEdgePadding,
          math.max(_windowEdgePadding, upperLimitFromTop),
        );
        left = (_mousePosition.dx + _offset.width).clamp(
          _windowEdgePadding,
          math.max(_windowEdgePadding, upperLimitFromLeft),
        );
        break;
    }

    final childParentData = child?.parentData as BoxParentData?;
    if (childParentData != null) {
      childParentData.offset = Offset(left, top);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final childParentData = child!.parentData as BoxParentData;
      context.paintChild(child!, childParentData.offset + offset);
    }
  }
}

/// A widget that positions the tooltip in one layout pass.
class _TooltipLayout extends SingleChildRenderObjectWidget {
  final Offset mousePosition;
  final double windowEdgePadding;
  final Size offset;
  final TooltipPosition position;

  const _TooltipLayout({
    super.key,
    required Widget child,
    required this.mousePosition,
    required this.windowEdgePadding,
    required this.offset,
    required this.position,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TooltipRenderBox(
      child: child is! RenderBox ? null : child as RenderBox,
      mousePosition: mousePosition,
      windowEdgePadding: windowEdgePadding,
      offset: offset,
      position: position,
      mediaQuery: MediaQuery.of(context),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _TooltipRenderBox renderObject,
  ) {
    renderObject
      ..mousePosition = mousePosition
      ..windowEdgePadding = windowEdgePadding
      ..offset = offset
      ..position = position
      ..mediaQuery = MediaQuery.of(context);
  }
}

class MovingTooltipWidget extends StatefulWidget {
  final Widget child;
  final Widget tooltipWidget;
  final double windowEdgePadding;
  final Size offset;
  final TooltipPosition position;

  const MovingTooltipWidget({
    super.key,
    required this.child,
    required this.tooltipWidget,
    this.windowEdgePadding = 10.0,
    this.offset = const Size(5, 5),
    this.position = TooltipPosition.bottomRight,
  });

  static Widget text({
    Key? key,
    required String message,
    required Widget child,
    TextStyle? textStyle,
    double windowEdgePadding = 10.0,
    Size offset = const Size(5, 5),
    TooltipPosition position = TooltipPosition.bottomRight,
  }) {
    return message.isNotNullOrBlank
        ? Builder(
            builder: (context) {
              return MovingTooltipWidget(
                key: key,
                tooltipWidget: TooltipFrame(
                  child: Text(
                    message,
                    style: textStyle ?? Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                windowEdgePadding: windowEdgePadding,
                offset: offset,
                position: position,
                child: child,
              );
            },
          )
        : child;
  }

  static Widget framed({
    Key? key,
    required Widget tooltipWidget,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    double windowEdgePadding = 10.0,
    Size offset = const Size(5, 5),
    TooltipPosition position = TooltipPosition.bottomRight,
  }) {
    return Builder(
      builder: (context) {
        return MovingTooltipWidget(
          key: key,
          tooltipWidget: TooltipFrame(padding: padding, child: tooltipWidget),
          windowEdgePadding: windowEdgePadding,
          offset: offset,
          position: position,
          child: child,
        );
      },
    );
  }

  @override
  State<MovingTooltipWidget> createState() => _MovingTooltipWidgetState();
}

class _MovingTooltipWidgetState extends State<MovingTooltipWidget> {
  OverlayEntry? _overlayEntry;
  late final int _depth;
  bool _blockTooltip = false; // Prevents parent tooltip from activating
  _MovingTooltipWidgetState? _parentState; // Cache parent reference

  Offset? _latestGlobalMousePosition;

  @override
  void initState() {
    super.initState();
    _parentState = context.findAncestorStateOfType<_MovingTooltipWidgetState>();
    _depth = (_parentState?._depth ?? 0) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        if (!_blockTooltip) _showTooltip(event.position);
      },
      onHover: (event) => _updateTooltipPosition(event.position),
      onExit: (_) => _hideTooltip(),
      child: widget.child,
    );
  }

  void _showTooltip(Offset globalPosition) {
    _hideTooltip();
    if (_blockTooltip) return;

    _latestGlobalMousePosition = globalPosition;
    _parentState?._setTooltipBlock(true); // Disable parent tooltip

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          _TooltipLayout(
            mousePosition: _latestGlobalMousePosition!,
            windowEdgePadding: widget.windowEdgePadding,
            offset: widget.offset,
            position: widget.position,
            child: IgnorePointer(child: widget.tooltipWidget),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateTooltipPosition(Offset globalPosition) {
    if (_overlayEntry != null && _blockTooltip) {
      _hideTooltip();
      return;
    } else if (_overlayEntry == null && !_blockTooltip) {
      _showTooltip(globalPosition);
      return;
    }

    _latestGlobalMousePosition = globalPosition;
    _overlayEntry?.markNeedsBuild();
  }

  void _hideTooltip() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _parentState?._setTooltipBlock(false); // Re-enable parent's tooltip
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  // Set the flag to disable this widget's tooltip
  void _setTooltipBlock(bool block) {
    setState(() {
      _blockTooltip = block;
    });
  }
}
