import 'package:material_ui/material_ui.dart';

/// A small gray label over a value, used for sizes in the save archive
/// dialogs.
class SizeStat extends StatelessWidget {
  final String label;
  final String value;

  const SizeStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.textTheme.labelSmall?.color?.withAlpha(180),
          ),
        ),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}
