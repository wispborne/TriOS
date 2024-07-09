import 'package:flutter/material.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/widgets/conditional_wrap.dart';

class CheckboxWithLabel extends StatelessWidget {
  final String? label;
  final Widget? labelWidget;
  final Widget? prefixWidget;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final TextStyle? labelStyle;
  final EdgeInsets textPadding;
  final bool expand;
  final Widget Function(Widget)? checkWrapper;
  final bool flipCheckboxAndLabel;

  const CheckboxWithLabel({
    super.key,
    this.label,
    this.labelWidget,
    this.prefixWidget,
    required this.value,
    required this.onChanged,
    this.checkWrapper,
    this.labelStyle,
    this.textPadding = const EdgeInsets.only(left: 8, bottom: 2),
    this.expand = false,
    this.flipCheckboxAndLabel = false,
  }) : assert(label != null || labelWidget != null);

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[
      prefixWidget == null ? Container() : prefixWidget!,
      ConditionalWrap(
        condition: checkWrapper != null,
        wrapper: (child) => checkWrapper!(child),
        child: IgnorePointer(
          child: Checkbox(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: value,
              onChanged: onChanged),
        ),
      ),
      Flexible(
        child: Padding(
          padding: textPadding,
          child: label != null ? Text(label!, style: labelStyle) : labelWidget,
        ),
      ),
    ];

    return InkWell(
      onTap: () {
        onChanged(!value);
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
