import 'package:flutter/widgets.dart';

class ConditionalWrap extends StatelessWidget {
  /// Creates a widget that conditionally wraps its [child].
  const ConditionalWrap({
    super.key,
    required this.condition,
    required this.wrapper,
    this.fallback,
    required this.child,
  });

  /// Decides on which [Wrapper] to use.
  final bool condition;

  /// Wrapper to use when [condition] is true.
  final Widget Function(Widget child) wrapper;

  /// Wrapper to use when [condition] is false.
  ///
  /// If not specified, [child] is returned.
  final Widget Function(Widget child)? fallback;

  /// Widget to be conditionally wrapped.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (condition) {
      return wrapper(child);
    } else if (fallback != null) {
      return fallback!(child);
    } else {
      return child;
    }
  }
}