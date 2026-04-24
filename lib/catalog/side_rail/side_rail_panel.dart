import 'package:flutter/material.dart';

/// Declarative description of a panel that lives behind a rail tab.
///
/// Passed to [SideRail] as a config list. Adding new panels does not
/// require changes to the rail widget itself.
class SideRailPanel {
  /// Stable identifier used for toggling and persistence.
  final String id;

  /// Label shown on the rail tab.
  final String label;

  /// Icon shown on the rail tab, above the rotated label.
  final IconData icon;

  /// Builder for the expanded panel content.
  final WidgetBuilder builder;

  const SideRailPanel({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
  });
}
