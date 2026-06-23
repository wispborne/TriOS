import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/sector_map/finder/finder_catalog.dart';
import 'package:trios/sector_map/finder/finder_criteria.dart';
import 'package:trios/sector_map/models/sector.dart';
import 'package:trios/sector_map/sector_map_controller.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// The finder's knob panel: presets, resource floors+weights, hard toggles,
/// landmark proximity, soft preferences, and the modded-condition escape hatch.
class FinderPanel extends ConsumerWidget {
  final Sector sector;

  const FinderPanel({super.key, required this.sector});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final criteria = ref.watch(
      sectorMapControllerProvider.select((s) => s.criteria),
    );
    final controller = ref.read(sectorMapControllerProvider.notifier);
    void update(FinderCriteria c) => controller.setCriteria(c);

    final landmarkTypesPresent =
        sector.landmarks.map((l) => l.typeId).toSet();
    final otherIds = otherConditionIds(sector);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(theme, 'Presets'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in kFinderPresets)
              OutlinedButton(
                onPressed: () => update(preset.criteria),
                child: Text(preset.name),
              ),
            MovingTooltipWidget.text(
              message: 'Clear all knobs',
              child: TextButton.icon(
                onPressed: () => update(const FinderCriteria()),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Reset'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _sectionHeader(theme, 'Resources'),
        Text(
          'Floor is a hard cutoff; weight ranks how much you care.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        for (final family in kResourceFamilies)
          _ResourceRow(
            family: family,
            criterion:
                criteria.resources[family.id] ?? const ResourceCriterion(),
            onChanged: (rc) {
              final next = Map<String, ResourceCriterion>.from(
                criteria.resources,
              )..[family.id] = rc;
              update(criteria.copyWith(resources: next));
            },
          ),

        const SizedBox(height: 16),
        _sectionHeader(theme, 'Must have'),
        CheckboxWithLabel(
          label: 'Habitable world',
          value: criteria.mustBeHabitable,
          onChanged: (v) =>
              update(criteria.copyWith(mustBeHabitable: v ?? false)),
        ),
        CheckboxWithLabel(
          label: 'Gas giant (for volatiles / fuel)',
          value: criteria.mustHaveGasGiant,
          onChanged: (v) =>
              update(criteria.copyWith(mustHaveGasGiant: v ?? false)),
        ),
        MovingTooltipWidget.text(
          message: 'Skip systems that already have a faction colony',
          child: CheckboxWithLabel(
            label: 'Unclaimed only (no existing colony)',
            value: criteria.excludeColonized,
            onChanged: (v) =>
                update(criteria.copyWith(excludeColonized: v ?? false)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            spacing: 12,
            children: [
              const Expanded(child: Text('Min. stable locations')),
              DropdownButton<int>(
                value: criteria.minStableLocations,
                onChanged: (v) =>
                    update(criteria.copyWith(minStableLocations: v ?? 0)),
                items: [
                  for (var i = 0; i <= 4; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(i == 0 ? 'Any' : '$i+'),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _sectionHeader(theme, 'Near a landmark'),
        for (final entry in kLandmarkLabels.entries)
          CheckboxWithLabel(
            label: landmarkTypesPresent.contains(entry.key)
                ? entry.value
                : '${entry.value} (none in this save)',
            value: criteria.landmarkNearby[entry.key] ?? false,
            onChanged: landmarkTypesPresent.contains(entry.key)
                ? (v) {
                    final next = Map<String, bool>.from(criteria.landmarkNearby)
                      ..[entry.key] = v ?? false;
                    update(criteria.copyWith(landmarkNearby: next));
                  }
                : (_) {},
          ),
        if (criteria.requiredLandmarks.isNotEmpty)
          _LabeledSlider(
            label: 'Within',
            valueLabel: '${criteria.nearbyRangeLy.round()} LY',
            value: criteria.nearbyRangeLy,
            min: 2,
            max: 30,
            divisions: 28,
            onChanged: (v) => update(criteria.copyWith(nearbyRangeLy: v)),
          ),

        const SizedBox(height: 16),
        _sectionHeader(theme, 'Preferences'),
        _LabeledSlider(
          label: 'Prefer low hazard',
          valueLabel: _weightLabel(criteria.lowHazardWeight),
          value: criteria.lowHazardWeight,
          min: 0,
          max: 1,
          onChanged: (v) => update(criteria.copyWith(lowHazardWeight: v)),
        ),
        _LabeledSlider(
          label: 'Prefer close to core',
          valueLabel: _weightLabel(criteria.closeToCoreWeight),
          value: criteria.closeToCoreWeight,
          min: 0,
          max: 1,
          onChanged: (v) => update(criteria.copyWith(closeToCoreWeight: v)),
        ),

        if (otherIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Other conditions (${otherIds.length})',
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(
              'Uncurated / modded conditions in this save',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            children: [
              for (final id in otherIds)
                CheckboxWithLabel(
                  label: id,
                  value: criteria.otherConditionToggles[id] ?? false,
                  onChanged: (v) {
                    final next = Map<String, bool>.from(
                      criteria.otherConditionToggles,
                    )..[id] = v ?? false;
                    update(criteria.copyWith(otherConditionToggles: next));
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: theme.textTheme.titleSmall),
  );
}

String _weightLabel(double w) => w <= 0 ? 'off' : '${(w * 100).round()}%';

class _ResourceRow extends StatelessWidget {
  final ResourceFamily family;
  final ResourceCriterion criterion;
  final ValueChanged<ResourceCriterion> onChanged;

  const _ResourceRow({
    required this.family,
    required this.criterion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        spacing: 8,
        children: [
          SizedBox(width: 80, child: Text(family.label)),
          // Min-tier floor (hard).
          MovingTooltipWidget.text(
            message: 'Hard cutoff: at least this tier on some planet',
            child: DropdownButton<int?>(
              value: criterion.minTier,
              hint: const Text('Any'),
              onChanged: (v) => onChanged(
                ResourceCriterion(minTier: v, weight: criterion.weight),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any')),
                for (var t = 1; t <= family.maxTier; t++)
                  DropdownMenuItem(
                    value: t,
                    child: Text(family.tierLabels[t - 1]),
                  ),
              ],
            ),
          ),
          // Weight (soft).
          Expanded(
            child: MovingTooltipWidget.text(
              message: 'Weight: ${_weightLabel(criterion.weight)}',
              child: Slider(
                value: criterion.weight,
                onChanged: (v) => onChanged(
                  ResourceCriterion(minTier: criterion.minTier, weight: v),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _LabeledSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      spacing: 8,
      children: [
        SizedBox(width: 140, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            valueLabel,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
