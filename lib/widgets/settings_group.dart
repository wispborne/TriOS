import 'package:flutter/material.dart';


class SettingsGroup extends StatelessWidget {
  final String name;
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    required this.name,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: Theme
                    .of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(),
              ),
              Expanded(
                child: Divider(
                  indent: 8,
                  color: theme.colorScheme.onSurface.withOpacity(0.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
