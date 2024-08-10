import 'package:flutter/material.dart';

class TextLinkButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final TextStyle? style;
  final bool autofocus;
  final FocusNode? focusNode;
  final Clip clipBehavior;
  final Color? hoverColor;

  const TextLinkButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.style,
    this.autofocus = false,
    this.focusNode,
    this.clipBehavior = Clip.none,
    this.hoverColor,
  });

  @override
  State<TextLinkButton> createState() => _TextLinkButtonState();
}

class _TextLinkButtonState extends State<TextLinkButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style?.copyWith(
          color: _isHovered
              ? (widget.style?.color ?? Theme.of(context).colorScheme.primary)
              : widget.onPressed != null
                  ? widget.style?.color ?? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
          decoration: TextDecoration.combine([
            widget.style?.decoration ?? TextDecoration.none,
            TextDecoration.underline,
          ]),
        ) ??
        TextStyle(
          color: _isHovered
              ? Theme.of(context).colorScheme.primary
              : widget.onPressed != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
          decoration: TextDecoration.underline,
        );

    return GestureDetector(
      onTap: widget.onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.hoverColor ??
                    Theme.of(context)
                        .colorScheme
                        .surfaceContainerLowest
                        .withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: effectiveStyle,
            child: Text(widget.text),
          ),
        ),
      ),
    );
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }
}
