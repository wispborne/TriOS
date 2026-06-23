import 'package:flutter/material.dart';
import 'package:trios/sector_map/models/sector.dart';

/// Side panel shown when a system is selected. Lists the system's faction
/// markets (the pie breakdown) and basic facts.
class SystemDetailPanel extends StatelessWidget {
  final SectorSystem system;
  final String? constellationName;
  final Color Function(String factionId) colorFor;
  final String Function(String factionId) nameFor;
  final VoidCallback onClose;
  final VoidCallback onCenter;

  const SystemDetailPanel({
    super.key,
    required this.system,
    required this.constellationName,
    required this.colorFor,
    required this.nameFor,
    required this.onClose,
    required this.onCenter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 4,
      child: SizedBox(
        width: 280,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (system.starColorValue != null)
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: system.starColorValue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      system.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Close',
                    onPressed: onClose,
                  ),
                ],
              ),
              Text(
                [?constellationName, system.type].join(' • '),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: 16),
              Text(
                system.isInhabited
                    ? 'Markets (${system.markets.length})'
                    : 'No markets',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (!system.isInhabited)
                Text(
                  'This system is uninhabited.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: muted,
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      for (final m in system.markets)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: colorFor(m.factionId),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.name.isEmpty
                                          ? nameFor(m.factionId)
                                          : m.name,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      '${nameFor(m.factionId)} • size ${m.size}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Row(
                children: [
                  Text(
                    '(${system.x.toStringAsFixed(0)}, '
                    '${system.y.toStringAsFixed(0)})',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text('Center'),
                    onPressed: onCenter,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
