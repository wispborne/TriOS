import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/filter_engine/filter_scope.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Small lock-icon toggle placed in a filter group's header. When locked, the
/// group's selections are persisted across app sessions via
/// [FilterGroupPersistence].
class FilterGridPersistButton extends ConsumerWidget {
  final FilterScope scope;
  final String filterGroupId;
  final Map<String, Object?> Function() currentSelections;

  const FilterGridPersistButton({
    super.key,
    required this.scope,
    required this.filterGroupId,
    required this.currentSelections,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persistence = ref.read(filterGroupPersistenceProvider);
    final key = FilterGroupPersistence.keyFor(scope, filterGroupId);
    final persisted = ref.watch(
      appSettings.select((s) => s.persistedFilterGroups[key]),
    );
    final isLocked = persisted != null;
    final theme = Theme.of(context);

    return MovingTooltipWidget.text(
      message: isLocked ? 'Filter group is being saved' : 'Filter group is not being saved',
      child: IconButton(
        onPressed: () {
          if (isLocked) {
            persistence.clear(scope, filterGroupId);
          } else {
            persistence.write(scope, filterGroupId, currentSelections());
          }
        },
        icon: Icon(
          Icons.save,
          size: 12,
          color: isLocked
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withAlpha(100),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          // Small on purpose: this sits in a 300-wide filter panel header
          // where the group's name needs the room.
          minimumSize: const Size(24, 28),
          maximumSize: const Size(24, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
