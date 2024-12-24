import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/widgets/tooltip_frame.dart';

enum TooltipPosition { topLeft, topRight, bottomLeft, bottomRight }

/// Stores references to tooltips currently visible. Enforces that only the most
/// deeply nested tooltips remain. If a deeper tooltip shows, everything shallower is hidden.
/// If you want only *one* total tooltip at once, you can also hide all same-depth tooltips.
class _TooltipRegistration {
  final GlobalKey key;
  final VoidCallback hide;

  _TooltipRegistration({required this.key, required this.hide});
}

class _TooltipVisibilityManager {
  /// Depth => List of tooltip registrations at that depth.
  final Map<int, List<_TooltipRegistration>> _tooltipsByDepth = {};

  bool get isEmpty => _tooltipsByDepth.isEmpty;

  /// Returns the maximum (deepest) depth that currently has a tooltip.
  int get _maxDepth => isEmpty ? -1 : _tooltipsByDepth.keys.reduce(math.max);

  /// Returns whether tooltips at [depth] are allowed to show.
  bool canShow(int depth) => depth >= _maxDepth;

  /// Registers a new tooltip at [depth], providing the [hideCallback] function
  /// so we can hide it later if needed.
  void registerShowing(int depth, GlobalKey key, VoidCallback hideCallback) {
    final currentMax = _maxDepth;

    // If deeper than the existing max depth, schedule a hide of all old tooltips
    if (depth > currentMax && !isEmpty) {
      // Defer the hide/clear until after the current frame/pointer event.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _hideAll();
        _tooltipsByDepth.clear();
        _tooltipsByDepth[depth] = [
          _TooltipRegistration(key: key, hide: hideCallback)
        ];
      });
      return;
    }

    // If same depth, you can optionally hide them or keep them.
    // For example, if you only want *one* tooltip at this depth, do:
    //   _hideDepth(depth);
    //   _tooltipsByDepth[depth]?.clear();

    // Then add the new one
    _tooltipsByDepth.putIfAbsent(depth, () => []);
    _tooltipsByDepth[depth]!
        .add(_TooltipRegistration(key: key, hide: hideCallback));
  }

  /// Unregisters the tooltip at [depth]. If no more remain at that depth, remove the entry.
  void unregister(int depth, GlobalKey key) {
    final regs = _tooltipsByDepth[depth];
    if (regs == null) return;
    regs.removeWhere((r) => r.key == key);
    if (regs.isEmpty) {
      _tooltipsByDepth.remove(depth);
    }
  }

  /// Force-hide every tooltip.
  void _hideAll() {
    // Copy the map so we don't modify during iteration.
    final depthList = _tooltipsByDepth.keys.toList();
    for (final depth in depthList) {
      final regs = _tooltipsByDepth[depth]?.toList() ?? [];
      for (final reg in regs) {
        reg.hide();
      }
    }
  }

  /// If you want to hide all tooltips at a specific depth.
  void _hideDepth(int depth) {
    final regs = _tooltipsByDepth[depth];
    if (regs == null) return;
    for (final reg in regs.toList()) {
      reg.hide();
    }
  }
}

final _TooltipVisibilityManager _tooltipManager = _TooltipVisibilityManager();

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
  final GlobalKey _thisKey = GlobalKey();

  /// Stores the most recent mouse position in global coordinates.
  Offset? _latestGlobalMousePosition;

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

  /// Shows the tooltip at a global pointer position if allowed by the manager.
  void showTooltipManually(Offset globalPosition) {
    _hideTooltip();
    if (!_tooltipManager.canShow(_depth)) return;

    _latestGlobalMousePosition = globalPosition;
    _overlayEntry = OverlayEntry(
      builder: (_) => _TooltipLayout(
        mousePosition: _latestGlobalMousePosition!,
        windowEdgePadding: widget.windowEdgePadding,
        offset: widget.offset,
        position: widget.position,
        child: IgnorePointer(child: widget.tooltipWidget),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _tooltipManager.registerShowing(_depth, _thisKey, _hideTooltip);
  }

  /// Shows the tooltip if permitted by the global manager.
  void _showTooltip(Offset globalPosition) {
    _hideTooltip();
    if (!_tooltipManager.canShow(_depth)) return;

    _latestGlobalMousePosition = globalPosition;
    _overlayEntry = OverlayEntry(
      builder: (_) => _TooltipLayout(
        mousePosition: _latestGlobalMousePosition!,
        windowEdgePadding: widget.windowEdgePadding,
        offset: widget.offset,
        position: widget.position,
        child: IgnorePointer(child: widget.tooltipWidget),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _tooltipManager.registerShowing(_depth, _thisKey, _hideTooltip);
  }

  /// Updates the tooltip’s position while hovering.
  void _updateTooltipPosition(Offset globalPosition) {
    _latestGlobalMousePosition = globalPosition;
    _overlayEntry?.markNeedsBuild();
  }

  /// Hides this tooltip, then tries to re-show the parent's if still hovered.
  void _hideTooltip() {
    if (_overlayEntry != null) {
      _tooltipManager.unregister(_depth, _thisKey);
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeReshowParentTooltip();
    });
  }

  /// Checks if the pointer is still inside the parent's region and, if so, re-shows the parent's tooltip.
  void _maybeReshowParentTooltip() {
    final parentState =
        context.findAncestorStateOfType<_MovingTooltipWidgetState>();
    if (parentState == null || !parentState.mounted) return;
    if (!_tooltipManager.canShow(parentState._depth)) return;

    final parentRenderBox =
        parentState.context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final parentPos = parentState._latestGlobalMousePosition;
    if (parentRenderBox == null || overlay == null || parentPos == null) return;

    final localPoint =
        parentRenderBox.globalToLocal(parentPos, ancestor: overlay);

    if (localPoint.dx >= 0 &&
        localPoint.dy >= 0 &&
        localPoint.dx <= parentRenderBox.size.width &&
        localPoint.dy <= parentRenderBox.size.height) {
      parentState.showTooltipManually(parentPos);
    }
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }
}
