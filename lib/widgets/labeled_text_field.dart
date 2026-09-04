import 'package:material_ui/material_ui.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Compact outlined text field with a label.
class LabeledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;

  /// Validation message shown below the field.
  final String? errorText;

  final String? tooltip;

  /// Maximum input length. The counter is hidden.
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
