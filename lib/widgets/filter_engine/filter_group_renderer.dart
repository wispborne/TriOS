import 'package:flutter/material.dart';
import 'package:trios/widgets/filter_engine/filter_group.dart';
import 'package:trios/widgets/filter_engine/filter_scope.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persist_button.dart';
import 'package:trios/widgets/filter_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/trios_dropdown_menu.dart';

/// Dispatches a [FilterGroup] to its type-specific UI.
///
/// Page controllers iterate their scope's groups and wrap each in this widget.
class FilterGroupRenderer<T> extends StatelessWidget {
  final FilterGroup<T> group;
  final FilterScope scope;
  final List<T> items;
  final VoidCallback onChanged;

  const FilterGroupRenderer({
    super.key,
    required this.group,
    required this.scope,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final g = group;
    if (g is ChipFilterGroup<T>) {
      return GridFilterWidget<T>(
        filter: g,
        items: items,
        filterStates: g.filterStates,
        scope: scope,
        onSelectionChanged: (states) {
          g.setSelections(states);
          onChanged();
        },
      );
    }
    if (g is BoolFilterGroup<T>) {
      return _BoolRow<T>(group: g, onChanged: onChanged);
    }
    if (g is EnumFilterGroup<T, dynamic>) {
      return _EnumRow<T>(group: g, onChanged: onChanged);
    }
    if (g is CompositeFilterGroup<T>) {
      return _CompositeCard<T>(group: g, scope: scope, onChanged: onChanged);
    }
    return const SizedBox.shrink();
  }
}

class _BoolRow<T> extends StatelessWidget {
  final BoolFilterGroup<T> group;
  final VoidCallback onChanged;

  const _BoolRow({required this.group, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tile = CheckboxListTile(
      title: Text(group.name),
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      value: group.value,
      onChanged: (v) {
        group.value = v ?? group.defaultValue;
        onChanged();
      },
    );
    if (group.tooltip != null) {
      return MovingTooltipWidget.text(message: group.tooltip!, child: tile);
    }
    return tile;
  }
}

class _EnumRow<T> extends StatelessWidget {
  final EnumFilterGroup<T, dynamic> group;
  final VoidCallback onChanged;

  const _EnumRow({required this.group, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <DropdownMenuEntry<Object>>[];
    for (final opt in group.optionValues) {
      final label = group.labelFor(opt) ?? (opt as Enum).name;
      final tip = group.tooltipFor(opt);
      final icon = group.iconFor(opt);
      entries.add(
        DropdownMenuEntry<Object>(
          value: opt,
          label: label,
          labelWidget: tip == null
              ? Text(label)
              : MovingTooltipWidget.text(message: tip, child: Text(label)),
          leadingIcon: icon is IconData ? Icon(icon, size: 20) : null,
        ),
      );
    }
    final dropdown = TriOSDropdownMenu<Object>(
      initialSelection: group.selectedAsObject,
      onSelected: (v) {
        if (v == null) return;
        group.setFromObject(v);
        onChanged();
      },
      highlightOutlineColor: group.isActive ? theme.colorScheme.primary : null,
      dropdownMenuEntries: entries,
    );
    if (group.tooltip != null) {
      return MovingTooltipWidget.text(message: group.tooltip!, child: dropdown);
    }
    return dropdown;
  }
}

class _CompositeCard<T> extends StatelessWidget {
  final CompositeFilterGroup<T> group;
  final FilterScope scope;
  final VoidCallback onChanged;

  const _CompositeCard({
    required this.group,
    required this.scope,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    group.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const Spacer(),
                FilterGridPersistButton(
                  scope: scope,
                  filterGroupId: group.id,
                  currentSelections: () => group.serialize(),
                ),
              ],
            ),
            for (final f in group.fields)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _renderField(context, f),
              ),
          ],
        ),
      ),
    );
  }

  Widget _renderField(BuildContext context, FilterField<T> field) {
    final theme = Theme.of(context);
    if (field is BoolField<T>) {
      final tile = CheckboxListTile(
        title: Text(field.label),
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.only(left: 8),
        value: field.value,
        onChanged: (v) {
          field.value = v ?? field.defaultValue;
          onChanged();
        },
      );
      if (field.tooltip != null) {
        return MovingTooltipWidget.text(message: field.tooltip!, child: tile);
      }
      return tile;
    }
    if (field is StringChoiceField<T>) {
      final entries = <DropdownMenuEntry<String?>>[
        DropdownMenuEntry<String?>(
          value: null,
          label: field.labelFor(null),
        ),
        for (final opt in field.options)
          DropdownMenuEntry<String?>(value: opt, label: field.labelFor(opt)),
      ];
      final dropdown = TriOSDropdownMenu<String?>(
        initialSelection: field.selected,
        onSelected: (v) {
          field.setSelected(v);
          onChanged();
        },
        highlightOutlineColor: field.isActive
            ? theme.colorScheme.primary
            : null,
        dropdownMenuEntries: entries,
      );
      if (field.tooltip != null) {
        return MovingTooltipWidget.text(
          message: field.tooltip!,
          child: dropdown,
        );
      }
      return dropdown;
    }
    if (field is EnumField<T, dynamic>) {
      final entries = <DropdownMenuEntry<Object>>[];
      for (final opt in field.optionValues) {
        final label = field.labelFor(opt) ?? (opt as Enum).name;
        final tip = field.tooltipFor(opt);
        final icon = field.iconFor(opt);
        entries.add(
          DropdownMenuEntry<Object>(
            value: opt,
            label: label,
            labelWidget: tip == null
                ? Text(label)
                : MovingTooltipWidget.text(message: tip, child: Text(label)),
            leadingIcon: icon is IconData ? Icon(icon, size: 20) : null,
          ),
        );
      }
      final dropdown = TriOSDropdownMenu<Object>(
        initialSelection: field.selectedAsObject,
        onSelected: (v) {
          if (v == null) return;
          field.setFromObject(v);
          onChanged();
        },
        highlightOutlineColor: field.isActive
            ? theme.colorScheme.primary
            : null,
        dropdownMenuEntries: entries,
      );
      if (field.tooltip != null) {
        return MovingTooltipWidget.text(
          message: field.tooltip!,
          child: dropdown,
        );
      }
      return dropdown;
    }
    return const SizedBox.shrink();
  }
}
