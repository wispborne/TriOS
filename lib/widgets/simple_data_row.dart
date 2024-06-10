import 'package:flutter/material.dart';

class SimpleDataRow extends StatelessWidget {
  final String label;
  final String value;

  const SimpleDataRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.labelLarge,
        children: [
          TextSpan(
              text: label, style: const TextStyle(fontWeight: FontWeight.w100)),
          TextSpan(
              text: value,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
