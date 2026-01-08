import 'package:flutter/material.dart';

class ModeSwitcher<T> extends StatelessWidget {
  final T selected;
  final Map<T, String> modes;
  final Map<T, Widget>? modeIcons;
  final ValueChanged<T> onChanged;
  final bool hideSelectedIcon;
  final bool isCompact;

  const ModeSwitcher({
    super.key,
    required this.selected,
    required this.modes,
    this.modeIcons,
    required this.onChanged,
    this.hideSelectedIcon = true,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return SegmentedButton<T>(
      showSelectedIcon: !hideSelectedIcon,
      selected: {selected},
      onSelectionChanged: (Set<T> newSelection) {
        onChanged(newSelection.first);
      },
      segments: modes.entries.map((entry) {
        final isSelected = entry.key == selected;
        return ButtonSegment<T>(
          value: entry.key,
          icon: modeIcons?[entry.key],
          label: Text(
            entry.value,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
      style: ButtonStyle(
        visualDensity: isCompact
            ? VisualDensity.compact
            : VisualDensity.standard,
        tapTargetSize: isCompact ? MaterialTapTargetSize.shrinkWrap : null,

        backgroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),

        foregroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(context).colorScheme.onPrimary;
          }
          return Theme.of(context).colorScheme.onSurface;
        }),

        overlayColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.hovered)) {
            return primaryColor.withOpacity(0.1);
          }
          return null;
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: Theme.of(context).colorScheme.primaryContainer),
        ),
      ),
    );
  }
}
