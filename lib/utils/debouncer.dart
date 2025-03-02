import 'dart:async';

/// A reusable class for debouncing async calls.
///
/// Each time [debounce] is called, any existing timer is canceled and reset,
/// ensuring that the wrapped [operation] only runs after [duration] has passed
/// without new calls.
///
/// **Usage example:**
/// ```dart
/// final debouncer = Debouncer(duration: const Duration(milliseconds: 500));
///
/// // An example async operation:
/// Future<String> fetchData() async {
///   // Simulate a network or heavy operation
///   await Future.delayed(const Duration(seconds: 1));
///   return "Data Loaded";
/// }
///
/// // Called frequently (e.g., user typing or rapid button presses)
/// void onUserAction() async {
///   // If onUserAction is called multiple times in quick succession,
///   // only the last call (within the debounce window) will execute fetchData.
///   final result = await debouncer.debounce(() => fetchData());
///   print(result); // "Data Loaded"
/// }
/// ```
///
/// This helps prevent repeated expensive operations, such as multiple
/// HTTP calls within a short timeframe.
class Debouncer {
  final Duration duration;
  Timer? _timer;
  bool _hasRunOnce = false;

  Debouncer({this.duration = const Duration(milliseconds: 500)});

  /// Debounces the given [operation]. Returns a [Future] of the operation’s result.
  Future<T> debounce<T>(Future<T> Function() operation) {
    // Cancel any existing timer.
    _timer?.cancel();

    // Completer to return the future result once ready.
    final completer = Completer<T>();

    // Schedule the operation to run after [duration].
    _timer = Timer(!_hasRunOnce ? Duration.zero : duration, () async {
      _hasRunOnce = true;
      try {
        final result = await operation();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });

    return completer.future;
  }
}
