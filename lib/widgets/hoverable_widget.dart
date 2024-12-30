import 'package:flutter/material.dart';

class HoverableWidget extends StatefulWidget {
  final Widget child;
  final Color? hoverColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Function()? onTapDown;
  final Function()? onTap;

  const HoverableWidget({
    super.key,
    required this.child,
    this.hoverColor,
    this.borderRadius,
    this.padding,
    this.onTapDown,
    this.onTap,
  });

  @override
  State<HoverableWidget> createState() => _HoverableWidgetState();
}

class _HoverableWidgetState extends State<HoverableWidget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
      },
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: () {
          if (widget.onTap != null) widget.onTap!();
        },
        onTapDown: (event) {
          if (widget.onTapDown != null) widget.onTapDown!();
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          decoration: BoxDecoration(
            color: _isHovering
                ? widget.hoverColor ?? Colors.black.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: widget.borderRadius,
          ),
          padding: widget.padding,
          child: HoverData(
            isHovering: _isHovering,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class HoverData extends InheritedWidget {
  final bool isHovering;

  const HoverData({
    super.key,
    required super.child,
    required this.isHovering,
  });

  static HoverData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HoverData>();
  }

  @override
  bool updateShouldNotify(HoverData oldWidget) {
    return oldWidget.isHovering != isHovering;
  }
}
