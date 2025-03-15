import 'package:flutter/material.dart';

/// A customizable widget that displays a [Radio] button with
/// an associated label, and clips the highlight/splash as needed.
class TriOSRadioTile<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget title;
  final bool dense;
  final double splashRadius;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double spacing;

  const TriOSRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    this.onChanged,
    this.dense = false,
    this.splashRadius = 0.0,
    this.spacing = 8,
    this.borderRadius,
    this.padding,
  });

  bool get _isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: borderRadius,
      type: MaterialType.transparency,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(value),
        borderRadius: borderRadius,
        child: Padding(
          // If dense is true, reduce padding to keep things tight.
          padding:
              padding ??
              (dense
                  ? const EdgeInsets.symmetric(vertical: 4, horizontal: 8)
                  : const EdgeInsets.symmetric(vertical: 8, horizontal: 16)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: spacing,
            children: [
              Radio<T>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                splashRadius: splashRadius,
                materialTapTargetSize:
                    dense
                        ? MaterialTapTargetSize.shrinkWrap
                        : MaterialTapTargetSize.padded,
              ),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.labelLarge,
                  child: title,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
