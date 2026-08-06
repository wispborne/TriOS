import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notify listeners whenever the notifier emits a new state object, instead of
/// comparing the old and new state with `==`.
///
/// Riverpod 2 worked this way. `Notifier` compared by identity and
/// `AsyncNotifier` did not compare at all. Riverpod 3 changed both to use `==`.
/// Our state classes are dart_mappable classes, so `==` walks the whole object
/// graph field by field. On a page holding thousands of ships or weapons a
/// single comparison took about half a second.
///
/// Add this to any notifier whose state is a dart_mappable class or otherwise
/// holds a large collection. Notifiers whose state is a plain `List`, `Map` or
/// primitive already compare cheaply and do not need it.
mixin NotifyOnNewState<StateT, ValueT> on AnyNotifier<StateT, ValueT> {
  @override
  bool updateShouldNotify(StateT previous, StateT next) =>
      !identical(previous, next);
}
