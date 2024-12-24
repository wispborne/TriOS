import 'package:flutter/material.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/measureable_widget.dart';
import 'package:trios/widgets/tooltip_frame.dart';

enum TooltipPosition { topLeft, topRight, bottomLeft, bottomRight }

/// Manages which tooltip (by nesting depth) is currently allowed to display.
class _TooltipVisibilityManager {
  int _activeDepth = -1;
  GlobalKey? _activeKey;

  /// Returns whether the given depth is allowed to show now.
  bool canShow(int depth) => depth >= _activeDepth;

  /// Registers this tooltip as visible at the given depth.
  void registerShowing(int depth, GlobalKey key) {
    if (depth >= _activeDepth) {
      _activeDepth = depth;
      _activeKey = key;
    }
  }

  /// Unregisters the tooltip if it was the active one.
  void unregister(int depth, GlobalKey key) {
    if (_activeKey == key) {
      _activeDepth = -1;
      _activeKey = null;
    }
  }
}

final _TooltipVisibilityManager _tooltipManager = _TooltipVisibilityManager();

class MovingTooltipWidget extends StatefulWidget {
  final Widget child;
  final Widget tooltipWidget;

  /// The minimum padding from the edge of the window to the tooltip.
  final double windowEdgePadding;

  /// The offset from the mouse position to the tooltip.
  final Size offset;

  /// The position of the tooltip relative to the mouse cursor.
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
        ? Builder(builder: (context) {
            return MovingTooltipWidget(
              key: key,
              tooltipWidget: TooltipFrame(
                  child: Text(
                message,
                style: textStyle ?? Theme.of(context).textTheme.bodySmall,
              )),
              windowEdgePadding: windowEdgePadding,
              offset: offset,
              position: position,
              child: child,
            );
          })
        : child;
  }

  static Widget framed({
    Key? key,
    required Widget tooltipWidget,
    required Widget child,
    double windowEdgePadding = 10.0,
    Size offset = const Size(5, 5),
    TooltipPosition position = TooltipPosition.bottomRight,
  }) {
    return Builder(builder: (context) {
      return MovingTooltipWidget(
        key: key,
        tooltipWidget: TooltipFrame(child: tooltipWidget),
        windowEdgePadding: windowEdgePadding,
        offset: offset,
        position: position,
        child: child,
      );
    });
  }

  @override
  State<MovingTooltipWidget> createState() => _MovingTooltipWidgetState();
}

class _MovingTooltipWidgetState extends State<MovingTooltipWidget> {
  OverlayEntry? _overlayEntry;
  Size? _tooltipWidgetSize;
  late final int _depth;
  final GlobalKey _thisKey = GlobalKey();

  /// Determines the nesting depth of this tooltip relative to any ancestor
  @override
  void initState() {
    super.initState();
    final parentState =
        context.findAncestorStateOfType<_MovingTooltipWidgetState>();
    _depth = (parentState?._depth ?? 0) + 1;
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

  /// Shows the tooltip if permitted by the global manager
  void _showTooltip(Offset mousePosition) {
    _hideTooltip(); // Ensure no previous tooltip lingers
    if (!_tooltipManager.canShow(_depth)) return;

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
              if (mounted) setState(() {});
            });
          }

          double top = 0;
          double left = 0;

          switch (widget.position) {
            case TooltipPosition.topLeft:
              top = (mousePosition.dy -
                      (widget.offset.height +
                          (_tooltipWidgetSize?.height ?? 0)))
                  .clamp(
                      widget.windowEdgePadding.coerceAtMost(upperLimitFromTop),
                      upperLimitFromTop);
              left = (mousePosition.dx -
                      (widget.offset.width + (_tooltipWidgetSize?.width ?? 0)))
                  .clamp(
                      widget.windowEdgePadding.coerceAtMost(upperLimitFromLeft),
                      upperLimitFromLeft);
              break;
            case TooltipPosition.topRight:
              top = (mousePosition.dy -
                      (widget.offset.height +
                          (_tooltipWidgetSize?.height ?? 0)))
                  .clamp(
                      widget.windowEdgePadding.coerceAtMost(upperLimitFromTop),
                      upperLimitFromTop);
              left = (mousePosition.dx + widget.offset.width).clamp(
                  widget.windowEdgePadding.coerceAtMost(upperLimitFromLeft),
                  upperLimitFromLeft);
              break;
            case TooltipPosition.bottomLeft:
              top = (mousePosition.dy + widget.offset.height).clamp(
                  widget.windowEdgePadding.coerceAtMost(upperLimitFromTop),
                  upperLimitFromTop);
              left = (mousePosition.dx -
                      (widget.offset.width + (_tooltipWidgetSize?.width ?? 0)))
                  .clamp(
                      widget.windowEdgePadding.coerceAtMost(upperLimitFromLeft),
                      upperLimitFromLeft);
              break;
            case TooltipPosition.bottomRight:
              top = (mousePosition.dy + widget.offset.height).clamp(
                  widget.windowEdgePadding.coerceAtMost(upperLimitFromTop),
                  upperLimitFromTop);
              left = (mousePosition.dx + widget.offset.width).clamp(
                  widget.windowEdgePadding.coerceAtMost(upperLimitFromLeft),
                  upperLimitFromLeft);
              break;
          }

          return Stack(
            children: [
              Positioned(
                top: _tooltipWidgetSize == null ? -1000 : top,
                left: left,
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

    _tooltipManager.registerShowing(_depth, _thisKey);
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    // Ensure the tooltip is hidden when the widget is disposed
    // This prevents the tooltip from becoming "stuck" on screen.
    _hideTooltip();
    super.dispose();
  }

  /// Requests a rebuild so the tooltip's position can track the mouse
  void _updateTooltipPosition(Offset mousePosition) {
    _overlayEntry?.markNeedsBuild();
    _showTooltip(mousePosition);
  }

  /// Hides the tooltip and unregisters it with the manager
  void _hideTooltip() {
    if (_overlayEntry != null) {
      _tooltipManager.unregister(_depth, _thisKey);
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
}
