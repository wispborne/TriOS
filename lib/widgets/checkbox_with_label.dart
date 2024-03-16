import 'package:flutter/material.dart';
import 'package:trios/trios/trios_theme.dart';

class CheckboxWithLabel extends StatelessWidget {
  final String? label;
  final Widget? labelWidget;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final TextStyle? labelStyle;
  final double padding;
  final bool expand;

  const CheckboxWithLabel(
      {super.key,
      this.label,
      this.labelWidget,
      required this.value,
      required this.onChanged,
      this.labelStyle,
      this.padding = 8,
      this.expand = false})
      : assert(label != null || labelWidget != null);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(!value);
      },
      borderRadius: BorderRadius.circular(TriOSTheme.cornerRadius),
      child: Padding(
        padding: const EdgeInsets.only(right: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            IgnorePointer(
                child: Checkbox(
                    checkColor: Theme.of(context).colorScheme.primary, // Hides the check
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: value,
                    onChanged: onChanged)),
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(left: padding, bottom: 2),
                child: label != null ? Text(label!, style: labelStyle) : labelWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
