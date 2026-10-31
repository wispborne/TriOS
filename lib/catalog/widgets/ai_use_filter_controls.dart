import 'package:material_ui/material_ui.dart';
import 'package:trios/catalog/ai_use_filter.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/trios_radio_tile.dart';

/// The Catalog's AI use filter. Reads only what the author said, not
/// AI-written text, so it stays when AI features are off.
class AiUseFilterGroup extends CustomFilterGroup<CatalogMod> {
  @override
  final String id;

  @override
  final String name;

  AiUseFilterSettings settings = const AiUseFilterSettings();

  AiUseFilterGroup({required this.id, required this.name});

  @override
  bool get isActive => isOn(settings);

  @override
  bool matches(CatalogMod item) => keepsForAi(item.aiUse, settings);

  @override
  Map<String, Object?> serialize() => settings.toMap();

  @override
  void restore(Map<String, Object?> selections) =>
      settings = AiUseFilterSettings.fromMap(selections);

  @override
  void clear() => settings = const AiUseFilterSettings();

  @override
  Widget buildBody(BuildContext context, VoidCallback onChanged) =>
      AiUseFilterControls(
        settings: settings,
        onChanged: (next) {
          settings = next;
          onChanged();
        },
      );
}

/// The body of the Catalog's AI use filter group: the presets, and for
/// Custom, the mode, the parts, the level and the optional switch.
class AiUseFilterControls extends StatelessWidget {
  final AiUseFilterSettings settings;
  final ValueChanged<AiUseFilterSettings> onChanged;

  const AiUseFilterControls({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  static const _tilePadding = EdgeInsets.symmetric(vertical: 2, horizontal: 4);

  Widget _radio<T>({
    required T value,
    required T groupValue,
    required String label,
    String? tooltip,
    required ValueChanged<T> onPicked,
  }) {
    final tile = TriOSRadioTile<T>(
      value: value,
      groupValue: groupValue,
      dense: true,
      padding: _tilePadding,
      title: Text(label),
      onChanged: (picked) {
        if (picked != null) onPicked(picked);
      },
    );
    return MovingTooltipWidget.text(message: tooltip, child: tile);
  }

  void _setParts(Set<String> parts) =>
      onChanged(settings.copyWith(parts: parts));

  Widget _groupParts(ThemeData theme, AiUseGroup group) {
    final keys = [for (final area in group.areas) area.key];
    final checkedCount = keys.where(settings.parts.contains).length;

    Widget areaBox(AiUseArea area) => CheckboxWithLabel(
      label: area.label,
      labelStyle: theme.textTheme.labelLarge,
      value: settings.parts.contains(area.key),
      onChanged: (checked) => _setParts(
        checked == true
            ? {...settings.parts, area.key}
            : ({...settings.parts}..remove(area.key)),
      ),
    );

    if (keys.length == 1) return areaBox(group.areas.single);

    return Column(
      crossAxisAlignment: .start,
      children: [
        CheckboxWithLabel(
          label: group.label,
          labelStyle: theme.textTheme.labelLarge,
          tristate: true,
          value: checkedCount == keys.length
              ? true
              : checkedCount == 0
              ? false
              : null,
          // A full group clears. Anything else checks the whole group.
          onChanged: (_) => _setParts(
            checkedCount == keys.length
                ? ({...settings.parts}..removeAll(keys))
                : {...settings.parts, ...keys},
          ),
        ),
        Padding(
          padding: const .only(left: 24),
          child: Column(
            crossAxisAlignment: .start,
            children: [for (final area in group.areas) areaBox(area)],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = settings.preset == AiUsePreset.custom;

    return Column(
      crossAxisAlignment: .start,
      children: [
        for (final preset in AiUsePreset.values)
          _radio<AiUsePreset>(
            value: preset,
            groupValue: settings.preset,
            label: preset.label,
            tooltip: preset.tooltip,
            onPicked: (picked) => onChanged(withPreset(settings, picked)),
          ),
        if (isCustom)
          Padding(
            padding: const .only(left: 16, top: 4),
            child: Column(
              crossAxisAlignment: .start,
              spacing: 4,
              children: [
                Column(
                  crossAxisAlignment: .start,
                  children: [
                    for (final mode in [AiUseMode.hide, AiUseMode.only])
                      _radio<AiUseMode>(
                        value: mode,
                        groupValue: settings.mode,
                        label: mode.label,
                        onPicked: (picked) =>
                            onChanged(settings.copyWith(mode: picked)),
                      ),
                  ],
                ),
                for (final group in aiUseGroups) _groupParts(theme, group),
                Padding(
                  padding: const .only(left: 4, top: 4),
                  child: Text(
                    '...if AI did...',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Column(
                  crossAxisAlignment: .start,
                  children: [
                    for (final level in AiUseLevel.values)
                      _radio<AiUseLevel>(
                        value: level,
                        groupValue: settings.level,
                        label: level.label,
                        onPicked: (picked) =>
                            onChanged(settings.copyWith(level: picked)),
                      ),
                  ],
                ),
                CheckboxWithLabel(
                  label: 'Ignore if AI content is optional',
                  labelStyle: theme.textTheme.labelLarge,
                  value: settings.skipOptional,
                  onChanged: (checked) => onChanged(
                    settings.copyWith(skipOptional: checked == true),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
