import 'package:material_ui/material_ui.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// A compact outlined text field with a label, matching the Settings page.
///
/// [errorText] comes from the caller so validation stays with whatever owns
/// the value.
class LabeledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;

  /// Shown under the field. Non-null marks the field as having a problem.
  final String? errorText;

  /// Tooltip on the field, for anything the label can't say.
  final String? tooltip;

  /// Caps typed length. The counter is hidden; the cap is a guard, not a
  /// progress bar.
  final int? maxLength;

  final int minLines;
  final int maxLines;
  final bool enabled;
  final bool autofocus;
  final double? width;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;

  const LabeledTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.tooltip,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.width,
    this.onChanged,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget field = TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      style: theme.textTheme.labelLarge,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        isDense: true,
        labelText: label,
        hintText: hint,
        errorText: errorText,
        counterText: '',
        hintStyle: theme.textTheme.labelLarge,
        labelStyle: theme.textTheme.labelLarge,
      ),
    );

    if (tooltip != null) {
      field = MovingTooltipWidget.text(message: tooltip!, child: field);
    }

    return width == null ? field : SizedBox(width: width, child: field);
  }
}
