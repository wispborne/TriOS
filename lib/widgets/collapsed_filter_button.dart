import 'package:flutter/material.dart';
import 'package:trios/widgets/filter_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Small collapsed filter sidebar icon with active filter count badge.
class CollapsedFilterButton extends StatelessWidget {
  final VoidCallback onTap;
  final int activeFilterCount;

  const CollapsedFilterButton({
    super.key,
    required this.onTap,
    required this.activeFilterCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: .zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: MovingTooltipWidget.text(
            message: "Show filters",
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list, size: 16),
                Positioned(
                  top: -12,
                  right: -16,
                  child: ActiveFilterCountPill(
                    count: activeFilterCount,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
