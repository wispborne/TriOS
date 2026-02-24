import 'package:flutter/material.dart';
import 'package:trios/widgets/checkbox_with_label.dart';

class TriOSToolbarCheckboxButton extends StatelessWidget {
  const TriOSToolbarCheckboxButton({
    super.key,
    required this.text,
    required this.value,
    required this.onChanged,
  });

  final String text;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TriOSToolbarItem(
      child: CheckboxWithLabel(
        labelWidget: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            text,
            style: theme.textTheme.labelLarge!.copyWith(fontSize: 14),
          ),
        ),
        textPadding: const EdgeInsets.only(left: 4),
        checkWrapper: (child) =>
            Padding(padding: const EdgeInsets.only(left: 4), child: child),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class TriOSToolbarItem extends StatelessWidget {
  final double? elevation;
  final Widget child;
  final bool showOutline;

  const TriOSToolbarItem({
    super.key,
    this.elevation,
    required this.child,
    this.showOutline = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 30,
      child: showOutline
          ? Card.outlined(
              elevation: elevation,
              margin: const EdgeInsets.symmetric(),
              child: DefaultTextStyle.merge(
                child: child,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            )
          : Card(
              elevation: elevation,
              margin: const EdgeInsets.symmetric(),
              child: DefaultTextStyle.merge(
                child: child,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
    );
  }
}
