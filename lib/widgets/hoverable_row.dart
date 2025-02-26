import 'package:flutter/material.dart';
import 'package:trios/widgets/hoverable_widget.dart';

class HoverableRow extends StatefulWidget {
  final List<Widget> children;
  final Color? hoverColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment? mainAxisAlignment;
  final MainAxisSize? mainAxisSize;
  final CrossAxisAlignment? crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection? verticalDirection;
  final double? spacing;
  final VoidCallback? onTap; // Optional click handler

  const HoverableRow({
    super.key,
    required this.children,
    this.hoverColor,
    this.borderRadius,
    this.padding,
    this.mainAxisAlignment,
    this.mainAxisSize,
    this.crossAxisAlignment,
    this.textDirection,
    this.verticalDirection,
    this.spacing,
    this.onTap, // Add onTap parameter
  });

  @override
  State<HoverableRow> createState() => _HoverableRowState();
}

class _HoverableRowState extends State<HoverableRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (PointerEvent event) {
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (PointerEvent event) {
        setState(() {
          _isHovering = false;
        });
      },
      cursor:
          widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.translucent,
        child: Container(
          decoration: BoxDecoration(
            color:
                _isHovering
                    ? widget.hoverColor ?? Colors.black.withOpacity(0.2)
                    : Colors.transparent,
            borderRadius: widget.borderRadius,
          ),
          padding: widget.padding,
          child: Row(
            mainAxisAlignment:
                widget.mainAxisAlignment ?? MainAxisAlignment.start,
            mainAxisSize: widget.mainAxisSize ?? MainAxisSize.max,
            crossAxisAlignment:
                widget.crossAxisAlignment ?? CrossAxisAlignment.center,
            textDirection: widget.textDirection,
            verticalDirection:
                widget.verticalDirection ?? VerticalDirection.down,
            spacing: widget.spacing ?? 0.0,
            children:
                widget.children.map((child) {
                  return HoverData(isHovering: _isHovering, child: child);
                }).toList(),
          ),
        ),
      ),
    );
  }
}
