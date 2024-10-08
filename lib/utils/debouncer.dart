import 'dart:async';
import 'dart:ui';

class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;
  bool _hasRun = false; // This flag ensures the first call is not delayed

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    // If this is the first time, run immediately without debouncing
    if (!_hasRun) {
      action();
      _hasRun = true;
    } else {
      if (_timer != null) {
        _timer!.cancel();
      }
      _timer = Timer(Duration(milliseconds: milliseconds), action);
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
