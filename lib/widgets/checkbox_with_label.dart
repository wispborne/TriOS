import 'package:flutter/material.dart';
import 'package:trios/trios/trios_theme.dart';

class CheckboxWithLabel extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final TextStyle? labelStyle;

  const CheckboxWithLabel(
      {super.key, required this.label, required this.value, required this.onChanged, this.labelStyle});

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
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Checkbox(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, value: value, onChanged: onChanged),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 2),
              child: Text(label, style: labelStyle),
            ),
          ],
        ),
      ),
    );
  }
}
