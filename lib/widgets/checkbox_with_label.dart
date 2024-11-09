import 'package:flutter/material.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/widgets/conditional_wrap.dart';

class CheckboxWithLabel extends StatelessWidget {
  final String? label;
  final Widget? labelWidget;
  final Widget? prefixWidget;
  final bool? value;
  final bool tristate;
  final ValueChanged<bool?> onChanged;
  final TextStyle? labelStyle;
  final EdgeInsets textPadding;
  final bool expand;
  final Widget Function(Widget)? checkWrapper;
  final bool flipCheckboxAndLabel;
  final double checkboxScale;

  const CheckboxWithLabel({
    super.key,
    this.label,
    this.labelWidget,
    this.prefixWidget,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.checkWrapper,
    this.labelStyle,
    this.textPadding = const EdgeInsets.only(left: 8, bottom: 2),
    this.expand = false,
    this.flipCheckboxAndLabel = false,
    this.checkboxScale = 1.0,
  }) : assert(label != null || labelWidget != null);

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[
      prefixWidget == null ? Container() : prefixWidget!,
      ConditionalWrap(
        condition: checkWrapper != null,
        wrapper: (child) => checkWrapper!(child),
        child: IgnorePointer(
          child: Transform.scale(
            scale: checkboxScale,
            child: Checkbox(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: value,
              tristate: tristate,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
      Flexible(
        child: Padding(
          padding: textPadding,
          child: label != null
              ? Text(label!, style: labelStyle, textAlign: TextAlign.center)
              : labelWidget,
        ),
      ),
    ];

    return InkWell(
      onTap: () {
        switch (value) {
          case true:
            onChanged(false);
            break;
          case false:
            onChanged(null);
            break;
          case null:
            onChanged(true);
            break;
        }
      },
      borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
      child: Padding(
        padding: const EdgeInsets.only(right: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: flipCheckboxAndLabel ? widgets.reversed.toList() : widgets,
        ),
      ),
    );
  }
}
