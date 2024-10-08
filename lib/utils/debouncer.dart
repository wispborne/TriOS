import 'dart:async';

import 'package:flutter/foundation.dart';

class Debouncer {
  final int milliseconds;
  final int initialDelayMs;
  Timer? _timer;
  bool _hasRun = false;
  bool _initialDelayActive = true;
  int _runCallCount =
      0; // Count the number of times run() is called during the debounce

  // This ValueNotifier will notify listeners when the cooldown state changes
  final ValueNotifier<bool> isCoolingDown = ValueNotifier<bool>(false);

  Debouncer({required this.milliseconds, required this.initialDelayMs}) {
    // Start a timer for the initial delay
    if (initialDelayMs > 0) {
      Timer(Duration(milliseconds: initialDelayMs), () {
        _initialDelayActive = false;
      });
    } else {
      _initialDelayActive = false;
    }
  }

  void run(VoidCallback action) {
    // If the initial delay is active, run immediately without debouncing
    if (_initialDelayActive) {
      action();
      return;
    }

    // If this is the first time, run immediately without debouncing
    if (!_hasRun) {
      action();
      _hasRun = true;
      _runCallCount = 1; // First run call
    } else {
      _runCallCount++; // Increment call count for subsequent calls

      if (_timer != null && _timer!.isActive) {
        // If the timer is active, meaning debounce is happening, set cooldown state
        if (_runCallCount == 2) {
          isCoolingDown.value = true; // Only set cooldown after second run call
        }
        // Cancel the previous timer and reset it
        _timer!.cancel();
      }

      // Set the new timer for the debounce period
      _timer = Timer(Duration(milliseconds: milliseconds), () {
        action();
        _runCallCount = 0; // Reset the run call count
        isCoolingDown.value =
            false; // Cooldown ends when the action is executed
      });
    }
  }

  void dispose() {
    _timer?.cancel();
    isCoolingDown
        .dispose(); // Dispose the notifier when the debouncer is disposed
  }
}
