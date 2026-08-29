import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/tooltip_frame.dart';

/// Dark background color used for image/blueprint preview tooltip cards.
const kDarkTooltipBackground = Color.from(
  red: 0.05,
  green: 0.05,
  blue: 0.05,
  alpha: 1,
);

/// Widest and tallest an image preview in a tooltip is shown and decoded.
const _maxTooltipImageSize = 512.0;

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
  }) : _mousePosition = mousePosition,
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

    if (left.isNaN) left = _windowEdgePadding;
    if (top.isNaN) top = _windowEdgePadding;

    final childParentData = child?.parentData as BoxParentData?;
    if (childParentData != null) {
      childParentData.offset = Offset(left, top);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final childParentData = child!.parentData as BoxParentData;
      final resolved = childParentData.offset + offset;
      if (resolved.dx.isNaN || resolved.dy.isNaN) return;
      context.paintChild(child!, resolved);
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

enum TooltipWarningLevel { none, warning, error }

/// Keeps tooltips hidden while a list is scrolling.
///
/// Scrolling slides cards under a mouse that hasn't moved, and Flutter reports
/// that the same way it reports the mouse moving onto a card. Without this,
/// every card that passes under the cursor pops its tooltip open over the list.
class _ScrollingHidesTooltips {
  /// How long after the last scroll before tooltips are allowed again. A mouse
  /// wheel sends a start, an update and an end for every single click, so the
  /// end of a scroll can't be used - only a gap with no scrolling at all.
  static const _quietPeriod = Duration(milliseconds: 200);

  /// Tooltips that are on screen right now, so scrolling can close them.
  static final Set<_MovingTooltipWidgetState> _showing = {};

  /// Tooltips the mouse is currently inside. Used to bring the tooltip back
  /// once scrolling stops, so the mouse doesn't have to be moved to wake it.
  static final Set<_MovingTooltipWidgetState> _hovered = {};

  static Timer? _quietTimer;

  /// True while a list is scrolling, and for [_quietPeriod] afterwards.
  static bool isScrolling = false;

  static void noteScrolled() {
    isScrolling = true;
    _quietTimer?.cancel();
    _quietTimer = Timer(_quietPeriod, _onScrollingStopped);

    for (final tooltip in _showing.toList()) {
      tooltip._hideTooltip();
    }
  }

  static void _onScrollingStopped() {
    _quietTimer = null;
    isScrolling = false;

    // Whatever the mouse is sitting on now gets its tooltip, after the usual
    // hover delay. Only the innermost one, since a tooltip inside another
    // tooltip's area hides the outer one anyway.
    _MovingTooltipWidgetState? innermost;
    for (final tooltip in _hovered) {
      if (innermost == null || tooltip._depth > innermost._depth) {
        innermost = tooltip;
      }
    }

    final mousePosition = innermost?._latestGlobalMousePosition;
    if (mousePosition != null) {
      innermost!._scheduleShowTooltip(mousePosition);
    }
  }

  /// Clears the shared state so one test can't affect the next.
  @visibleForTesting
  static void reset() {
    _quietTimer?.cancel();
    _quietTimer = null;
    isScrolling = false;
    _showing.clear();
    _hovered.clear();
  }
}

/// Hides tooltips while anything inside [child] is scrolling.
///
/// TriOS wraps the whole app in one of these, so every list gets this
/// behaviour. See [_ScrollingHidesTooltips] for why it's needed.
class HideTooltipsWhileScrolling extends StatelessWidget {
  final Widget child;

  const HideTooltipsWhileScrolling({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _ScrollingHidesTooltips.noteScrolled();
        return false;
      },
      child: child,
    );
  }
}

/// Clears the shared scroll state used to hide tooltips. Call between tests.
@visibleForTesting
void resetTooltipScrollStateForTest() => _ScrollingHidesTooltips.reset();

class MovingTooltipWidget extends StatefulWidget {
  final Widget child;
  final Widget? tooltipWidget;

  /// Builder variant of [tooltipWidget]. When provided, the tooltip widget is
  /// only constructed on hover, not during the parent's build. Use this for
  /// expensive tooltip content to avoid paying the cost on every parent
  /// rebuild (e.g. while scrolling lists).
  final WidgetBuilder? tooltipWidgetBuilder;
  final double windowEdgePadding;
  final Size offset;
  final TooltipPosition position;

  /// Delay between the mouse entering [child] and the tooltip being shown.
  /// When null, defaults to [defaultBuilderShowDelay] if [tooltipWidgetBuilder]
  /// is set (so expensive tooltip content isn't built for every row the mouse
  /// sweeps across), and no delay otherwise. Pass [Duration.zero] to opt out.
  final Duration? showDelay;

  /// Default [showDelay] applied when a [tooltipWidgetBuilder] is provided.
  static const defaultBuilderShowDelay = Duration(milliseconds: 100);

  const MovingTooltipWidget({
    super.key,
    required this.child,
    this.tooltipWidget,
    this.tooltipWidgetBuilder,
    this.windowEdgePadding = 10.0,
    this.offset = const Size(5, 5),
    this.position = TooltipPosition.bottomRight,
    this.showDelay,
  }) : assert(
         (tooltipWidget == null) != (tooltipWidgetBuilder == null),
         'Exactly one of tooltipWidget or tooltipWidgetBuilder must be provided',
       );

  static Widget text({
    Key? key,
    required String? message,
    required Widget child,
    TooltipWarningLevel? warningLevel,
    TextStyle? textStyle,
    Color? backgroundColor,
    double windowEdgePadding = 10.0,
    Size offset = const Size(5, 5),
    TooltipPosition position = TooltipPosition.bottomRight,
    double? maxWidth,
  }) {
    return message.isNotNullOrBlank
        ? Builder(
            builder: (context) {
              final text = Text(
                message!,
                style: (textStyle ?? Theme.of(context).textTheme.bodySmall)
                    ?.copyWith(
                      color: switch (warningLevel) {
                        null => textStyle?.color,
                        TooltipWarningLevel.none => null,
                        TooltipWarningLevel.warning =>
                          TriOSThemeConstants.vanillaWarningColor,
                        TooltipWarningLevel.error =>
                          TriOSThemeConstants.vanillaErrorColor,
                      },
                    ),
              );
              return MovingTooltipWidget(
                key: key,
                tooltipWidget: TooltipFrame(
                  backgroundColor: backgroundColor,
                  borderColor: switch (warningLevel) {
                    null || TooltipWarningLevel.none => null,
                    TooltipWarningLevel.warning ||
                    TooltipWarningLevel.error => Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer.withOpacity(0.5),
                  },
                  child: maxWidth != null
                      ? ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: text,
                        )
                      : text,
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
    Widget? tooltipWidget,
    WidgetBuilder? tooltipWidgetBuilder,
    TooltipWarningLevel? warningLevel,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    Color? backgroundColor,
    double windowEdgePadding = 10.0,
    Size offset = const Size(5, 5),
    TooltipPosition position = TooltipPosition.bottomRight,
    Duration? showDelay,
  }) {
    if (tooltipWidget == null && tooltipWidgetBuilder == null) return child;
    return Builder(
      builder: (context) {
        Widget frame(Widget content) => TooltipFrame(
          padding: padding,
          backgroundColor: backgroundColor,
          borderColor: switch (warningLevel) {
            null || TooltipWarningLevel.none => null,
            TooltipWarningLevel.warning ||
            TooltipWarningLevel.error => Theme.of(
              context,
            ).colorScheme.onSecondaryContainer.withOpacity(0.5),
          },
          child: content,
        );
        return MovingTooltipWidget(
          key: key,
          tooltipWidget: tooltipWidget == null ? null : frame(tooltipWidget),
          tooltipWidgetBuilder: tooltipWidgetBuilder == null
              ? null
              : (ctx) => frame(tooltipWidgetBuilder(ctx)),
          windowEdgePadding: windowEdgePadding,
          offset: offset,
          position: position,
          showDelay: showDelay,
          child: child,
        );
      },
    );
  }

  static Widget starsector({
    Key? key,
    Widget? tooltipWidget,
    WidgetBuilder? tooltipWidgetBuilder,
    TooltipWarningLevel? warningLevel,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    double windowEdgePadding = 10.0,
    Size offset = const Size(5, 5),
    TooltipPosition position = TooltipPosition.bottomRight,
  }) {
    if (tooltipWidget == null && tooltipWidgetBuilder == null) return child;
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        Widget frame(Widget content) => TooltipFrame(
          padding: padding,
          borderColor: switch (warningLevel) {
            null || TooltipWarningLevel.none =>
              context.theme.colorScheme.secondary.withAlpha(150),
            TooltipWarningLevel.warning || TooltipWarningLevel.error =>
              theme.colorScheme.onSecondaryContainer.withOpacity(0.5),
          },
          backgroundColor: theme.colorScheme.surfaceContainerLowest.withAlpha(
            230,
          ),
          child: Theme(
            data: theme.copyWith(
              textTheme: theme.textTheme.copyWith(
                bodyMedium: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == .dark
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onInverseSurface,
                ),
                bodySmall: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == .dark
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onInverseSurface,
                ),
              ),
            ),
            child: content,
          ),
        );
        return MovingTooltipWidget(
          key: key,
          tooltipWidget: tooltipWidget == null ? null : frame(tooltipWidget),
          tooltipWidgetBuilder: tooltipWidgetBuilder == null
              ? null
              : (ctx) => frame(tooltipWidgetBuilder(ctx)),
          windowEdgePadding: windowEdgePadding,
          offset: offset,
          position: position,
          child: child,
        );
      },
    );
  }

  static Widget image({
    Key? key,
    double padding = 16,
    Color? backgroundColor,
    bool showPathAsLabel = true,
    required String path,
    required Widget child,
  }) {
    final file = path.toFile();
    if (!file.existsSync()) return child;
    return MovingTooltipWidget(
      tooltipWidget: Card(
        color: backgroundColor ?? kDarkTooltipBackground,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              // Capped so hovering down a long list of icons doesn't fill
              // the image cache with full-size decodes. Icons and logos are
              // well under this, so they look the same as before.
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _maxTooltipImageSize,
                  maxHeight: _maxTooltipImageSize,
                ),
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  cacheWidth: _maxTooltipImageSize.toInt(),
                ),
              ),
              if (showPathAsLabel)
                Text(file.nameWithExtension, style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  State<MovingTooltipWidget> createState() => _MovingTooltipWidgetState();
}

class _MovingTooltipWidgetState extends State<MovingTooltipWidget> {
  OverlayEntry? _overlayEntry;
  Widget? _builtTooltip;
  Timer? _showDelayTimer;
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

  Duration get _showDelay =>
      widget.showDelay ??
      (widget.tooltipWidgetBuilder != null
          ? MovingTooltipWidget.defaultBuilderShowDelay
          : Duration.zero);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        _ScrollingHidesTooltips._hovered.add(this);
        if (!_blockTooltip) _scheduleShowTooltip(event.position);
      },
      onHover: (event) => _updateTooltipPosition(event.position),
      onExit: (_) {
        _ScrollingHidesTooltips._hovered.remove(this);
        _hideTooltip();
      },
      child: widget.child,
    );
  }

  /// Shows the tooltip after [_showDelay], or immediately if there is none.
  /// If a delayed show is already pending, only the mouse position updates.
  void _scheduleShowTooltip(Offset globalPosition) {
    _latestGlobalMousePosition = globalPosition;
    if (_blockTooltip || _ScrollingHidesTooltips.isScrolling) return;

    final delay = _showDelay;
    if (delay == Duration.zero) {
      _showTooltip();
      return;
    }
    if (_showDelayTimer?.isActive ?? false) return;
    _showDelayTimer = Timer(delay, () {
      if (mounted && !_blockTooltip && !_ScrollingHidesTooltips.isScrolling) {
        _showTooltip();
      }
    });
  }

  void _showTooltip() {
    _hideTooltip();
    if (_blockTooltip || _ScrollingHidesTooltips.isScrolling) return;

    _parentState?._setTooltipBlock(true); // Disable parent tooltip

    _builtTooltip =
        widget.tooltipWidget ?? widget.tooltipWidgetBuilder!(context);

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          _TooltipLayout(
            mousePosition: _latestGlobalMousePosition!,
            windowEdgePadding: widget.windowEdgePadding,
            offset: widget.offset,
            position: widget.position,
            child: IgnorePointer(child: _builtTooltip!),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _ScrollingHidesTooltips._showing.add(this);
  }

  void _updateTooltipPosition(Offset globalPosition) {
    if (_overlayEntry != null && _blockTooltip) {
      _hideTooltip();
      return;
    } else if (_overlayEntry == null && !_blockTooltip) {
      _scheduleShowTooltip(globalPosition);
      return;
    }

    _latestGlobalMousePosition = globalPosition;
    _overlayEntry?.markNeedsBuild();
  }

  void _hideTooltip() {
    _showDelayTimer?.cancel();
    _showDelayTimer = null;
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _builtTooltip = null;
      _ScrollingHidesTooltips._showing.remove(this);
    }
    _parentState?._setTooltipBlock(false); // Re-enable parent's tooltip
  }

  @override
  void dispose() {
    _ScrollingHidesTooltips._hovered.remove(this);
    _hideTooltip();
    super.dispose();
  }

  // Set the flag to disable this widget's tooltip
  void _setTooltipBlock(bool block) {
    // Ensure the widget is still mounted before scheduling the callback
    if (!mounted) return;

    // Schedule the setState call to run after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Double-check if the widget is still mounted when the callback executes,
      // as it might have been disposed in the meantime.
      if (!mounted) return;
      setState(() {
        _blockTooltip = block;
      });
    });
  }
}
