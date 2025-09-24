import 'package:flutter/material.dart';

/// A themed, generic dropdown menu used across TriOS.
/// Mirrors the compact toolbar style used in the app (dense, rounded, no filter/search).
class TriOSDropdownMenu<T> extends StatelessWidget {
  final T? initialSelection;
  final ValueChanged<T?>? onSelected;
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;

  // Optional overrides
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final TextStyle? textStyle;
  final bool enabled;

  const TriOSDropdownMenu({
    super.key,
    required this.dropdownMenuEntries,
    this.initialSelection,
    this.onSelected,
    this.height = 30,
    this.borderRadius = 10,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.textStyle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownMenu<T>(
      enabled: enabled,
      initialSelection: initialSelection,
      onSelected: onSelected,
      enableFilter: false,
      enableSearch: false,
      requestFocusOnTap: false,
      textStyle: textStyle ?? theme.textTheme.labelLarge,
      trailingIcon: Transform.translate(
        offset: const Offset(3, -6),
        child: const Icon(Icons.arrow_drop_down),
      ),
      selectedTrailingIcon: Transform.translate(
        offset: const Offset(3, -6),
        child: const Icon(Icons.arrow_drop_up),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: contentPadding,
        constraints: BoxConstraints.tight(Size.fromHeight(height)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
      dropdownMenuEntries: dropdownMenuEntries
          .map(
            (e) => DropdownMenuEntry<T>(
              value: e.value,
              label: e.label,
              labelWidget: e.labelWidget,
              leadingIcon: e.leadingIcon,
              // Keep per-entry text style aligned with the menu style by default
              style:
                  e.style ??
                  ButtonStyle(
                    textStyle: WidgetStatePropertyAll(
                      textStyle ?? theme.textTheme.labelLarge,
                    ),
                  ),
            ),
          )
          .toList(),
    );
  }
}
