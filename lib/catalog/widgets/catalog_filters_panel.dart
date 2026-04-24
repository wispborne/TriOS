import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/mod_browser_page_controller.dart';
import 'package:trios/catalog/models/scraped_mod.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_widget.dart';

/// Side-mounted filter panel for the Catalog page, rendering the controller's
/// filter groups via the shared [FilterGroupRenderer].
class CatalogFiltersPanel extends ConsumerWidget {
  final List<ScrapedMod> items;

  const CatalogFiltersPanel({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(catalogPageControllerProvider.notifier);
    // Watch state so the panel rebuilds when active-count or selections change.
    ref.watch(catalogPageControllerProvider);

    return FiltersPanel(
      width: 220,
      onHide: controller.toggleShowFilters,
      activeFilterCount: controller.activeFilterCount,
      showClearAll: controller.filterGroups.any((g) => g.isActive),
      onClearAll: controller.clearAllFilters,
      filterWidgets: [
        for (final g in controller.filterGroups)
          FilterGroupRenderer<ScrapedMod>(
            group: g,
            scope: controller.scope,
            items: items,
            onChanged: () => controller.onGroupChanged(g.id),
          ),
      ],
    );
  }
}
