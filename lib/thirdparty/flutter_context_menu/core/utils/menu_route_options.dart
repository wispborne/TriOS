import 'package:flutter/widgets.dart';

class MenuRouteOptions {
  final RouteSettings? routeSettings;
  final bool? requestFocus;
  final RouteTransitionsBuilder transitionsBuilder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final bool opaque;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool maintainState;
  final bool allowSnapshotting;

  const MenuRouteOptions({
    this.routeSettings,
    this.requestFocus,
    this.transitionsBuilder = _defaultTransitionsBuilder,
    this.transitionDuration = Duration.zero,
    this.reverseTransitionDuration = Duration.zero,
    this.opaque = false,
    this.barrierDismissible = true,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.allowSnapshotting = true,
  });
}

Widget _defaultTransitionsBuilder(
    context, animation, secondaryAnimation, child) {
  return child;
}
