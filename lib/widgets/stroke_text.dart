import 'package:flutter/material.dart';

class StrokeText extends StatelessWidget {
  final String text;
  final double strokeWidth;
  final Color textColor;
  final Color strokeColor;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final TextScaler? textScaler;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool borderOnTop;

  const StrokeText(
    this.text, {
    super.key,
    this.strokeWidth = 1,
    this.strokeColor = Colors.black,
    this.textColor = Colors.white,
    this.style,
    this.textAlign,
    this.textDirection,
    this.textScaler,
    this.overflow,
    this.maxLines,
    this.borderOnTop = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: !borderOnTop
          ? [
              Text(
                text,
                style: TextStyle(color: textColor).merge(style),
                textDirection: textDirection,
                textScaler: textScaler,
                overflow: overflow,
                maxLines: maxLines,
              ),
              Text(
                text,
                style: TextStyle(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = strokeWidth
                    ..isAntiAlias = true
                    ..color = strokeColor,
                ).merge(style),
                textAlign: textAlign,
                textDirection: textDirection,
                textScaler: textScaler,
                overflow: overflow,
                maxLines: maxLines,
              ),
            ]
          : [
              Text(
                text,
                style: TextStyle(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = strokeWidth
                    ..isAntiAlias = true
                    ..color = strokeColor,
                ).merge(style),
                textAlign: textAlign,
                textDirection: textDirection,
                textScaler: textScaler,
                overflow: overflow,
                maxLines: maxLines,
              ),
              Text(
                text,
                style: TextStyle(color: textColor).merge(style),
                textDirection: textDirection,
                textScaler: textScaler,
                overflow: overflow,
                maxLines: maxLines,
              ),
            ],
    );
  }
}
