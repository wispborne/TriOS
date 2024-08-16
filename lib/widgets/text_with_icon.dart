import 'package:flutter/material.dart';

class TextWithIcon extends StatelessWidget {
  final String text;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle? style;
  final TextOverflow? overflow;
  final int? maxLines;
  final EdgeInsetsGeometry? leadingPadding;
  final EdgeInsetsGeometry? trailingPadding;

  const TextWithIcon({
    Key? key,
    required this.text,
    this.leading,
    this.trailing,
    this.style,
    this.overflow,
    this.maxLines,
    this.leadingPadding = const EdgeInsets.only(right: 8.0),
    this.trailingPadding = const EdgeInsets.only(left: 8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null)
          Padding(
            padding: leadingPadding!,
            child: leading,
          ),
        Flexible(
          child: Text(
            text,
            style: style,
            overflow: overflow,
            maxLines: maxLines,
          ),
        ),
        if (trailing != null)
          Padding(
            padding: trailingPadding!,
            child: trailing,
          ),
      ],
    );
  }
}
