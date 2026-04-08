import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Shows a tooltip if the text is too long to fit in the available space.
///
/// Unlike a [LayoutBuilder]-based approach, this supports intrinsic
/// dimensions so it can be used inside [Row], [Column], etc.
class TextTriOS extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final TooltipWarningLevel warningLevel;

  const TextTriOS(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow = .ellipsis,
    this.warningLevel = .none,
  });

  @override
  State<TextTriOS> createState() => _TextTriOSState();
}

class _TextTriOSState extends State<TextTriOS> {
  final _textKey = GlobalKey();
  bool _isOverflowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  @override
  void didUpdateWidget(covariant TextTriOS oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.maxLines != widget.maxLines) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
    }
  }

  void _checkOverflow() {
    final renderObject = _textKey.currentContext?.findRenderObject();
    if (renderObject is RenderParagraph) {
      final didOverflow = renderObject.didExceedMaxLines;
      if (didOverflow != _isOverflowing) {
        setState(() => _isOverflowing = didOverflow);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      widget.text,
      key: _textKey,
      style: widget.style,
      textAlign: widget.textAlign,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
    );

    return _isOverflowing
        ? MovingTooltipWidget.text(
            message: widget.text,
            child: textWidget,
            warningLevel: widget.warningLevel,
          )
        : textWidget;
  }
}
