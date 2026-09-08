import 'package:material_ui/material_ui.dart';

class SimpleDataRow extends StatelessWidget {
  final String label;
  final String value;

  const SimpleDataRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        style: Theme.of(context).textTheme.labelMedium,
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w100),
          ),
          TextSpan(
            text: value,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
