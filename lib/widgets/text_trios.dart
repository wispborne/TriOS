import 'package:flutter/material.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Shows a tooltip if the text is too long to fit in the available space.
class TextTriOs extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maxLines;
  final TextOverflow overflow;

  const TextTriOs(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: style ?? DefaultTextStyle.of(context).style,
          ),
          maxLines: maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        return isOverflowing
            ? MovingTooltipWidget.text(message: text, child: textWidget)
            : textWidget;
      },
    );
  }
}
