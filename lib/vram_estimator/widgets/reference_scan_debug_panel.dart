import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector_config.dart';
import 'package:trios/vram_estimator/selectors/vram_selector_id.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';

/// Collapsible panel surfacing the VRAM estimator's debug toggles. The
/// multithreaded-scan toggle is selector-independent and renders for any
/// active selector; the reference-source toggles only render when the
/// active selector is `ReferencedAssetsSelector`.
class ReferenceScanDebugPanel extends ConsumerWidget {
  const ReferenceScanDebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettings);
    final isReferencedSelector =
        settings.vramEstimatorSelectorId == VramSelectorId.referenced;
    final config = settings.referencedAssetsSelectorConfig;

    return Card(
      child: TriOSExpansionTile(
        title: const Text('VRAM scan debug'),
        leading: const Icon(Icons.tune),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MovingTooltipWidget.text(
                  message:
                      'Run the per-mod scan loop across an isolate pool. '
                      'Faster on large mod lists, but uses more CPU and '
                      'multiplies the per-isolate file-handle limit by the '
                      'pool size. Takes effect on the next scan.',
                  child: SwitchListTile(
                    title: const Text('Multithreaded scanning'),
                    subtitle: const Text(
                      'Faster scans, higher CPU and file-handle pressure',
                    ),
                    value: settings.vramEstimatorMultithreaded,
                    onChanged: (val) => ref
                        .read(appSettings.notifier)
                        .update(
                          (s) => s.copyWith(vramEstimatorMultithreaded: val),
                        ),
                  ),
                ),
                if (isReferencedSelector) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Enabled reference sources',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final parser in registeredReferenceParsers)
                        MovingTooltipWidget.text(
                          message: parser.description,
                          child: FilterChip(
                            label: Text(parser.displayName),
                            selected: config.enabledParserIds.contains(
                              parser.id,
                            ),
                            onSelected: (val) =>
                                _toggleParser(ref, config, parser.id, val),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MovingTooltipWidget.text(
                    message:
                        'Hide unreferenced bucket — compare directly to '
                        'folder-scan totals.',
                    child: SwitchListTile(
                      title: const Text('Suppress unreferenced bucket'),
                      value: config.suppressUnreferenced,
                      onChanged: (val) => _updateConfig(
                        ref,
                        config.copyWith(suppressUnreferenced: val),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleParser(
    WidgetRef ref,
    ReferencedAssetsSelectorConfig config,
    String id,
    bool enabled,
  ) {
    final newIds = Set<String>.from(config.enabledParserIds);
    if (enabled) {
      newIds.add(id);
    } else {
      newIds.remove(id);
    }
    _updateConfig(ref, config.copyWith(enabledParserIds: newIds));
  }

  void _updateConfig(WidgetRef ref, ReferencedAssetsSelectorConfig newConfig) {
    ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(referencedAssetsSelectorConfig: newConfig));
    // Notify the VRAM manager so it swaps / rescans.
    ref
        .read(AppState.vramEstimatorProvider.notifier)
        .onSelectorOrConfigChanged();
  }
}
