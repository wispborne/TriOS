import 'package:flutter/material.dart';

class HoverableWidget extends StatefulWidget {
  final Widget Function(BuildContext context, bool isHovering) builder;
  final VoidCallback? onTap;

  const HoverableWidget({
    super.key,
    required this.builder,
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
        onTap: widget.onTap,
        behavior: HitTestBehavior.translucent,
        child: widget.builder(context, _isHovering),
      ),
    );
  }
}
