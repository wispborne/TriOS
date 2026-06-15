import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:toastification/toastification.dart';

/// Shared countdown-to-dismiss logic for download toasts.
///
/// Subclasses call [tryStartCountdown] when conditions are met (e.g. install
/// complete). The mixin handles the dismiss timer, a 60 fps ticker for the
/// progress-bar animation, and pause/resume on hover.
mixin ToastCountdownMixin<T extends StatefulWidget> on State<T> {
  Timer? _autoDismissTimer;
  Timer? _countdownTicker;
  final Stopwatch countdownStopwatch = Stopwatch();
  bool _countdownStarted = false;

  /// The toastification item to dismiss when the countdown expires.
  ToastificationItem get toastItem;

  /// Total auto-dismiss duration in milliseconds.
  int get toastDurationMillis;

  /// Whether the mouse is currently hovering (pauses countdown).
  bool get isHovering;

  bool get countdownStarted => _countdownStarted;

  /// Call from listeners when conditions to auto-dismiss may have changed.
  /// [isReadyToAutoDismiss] should return `true` when the toast is ready to
  /// begin its countdown (e.g. download + install finished).
  void tryStartCountdown({required bool isReadyToAutoDismiss}) {
    if (_countdownStarted || isHovering || !isReadyToAutoDismiss) return;

    _countdownStarted = true;
    countdownStopwatch.start();
    _autoDismissTimer = Timer(
      Duration(milliseconds: toastDurationMillis),
      () {
        if (mounted) toastification.dismiss(toastItem);
      },
    );
    _countdownTicker = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  void pauseCountdown() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    countdownStopwatch.stop();
    _countdownTicker?.cancel();
    _countdownTicker = null;
  }

  void resumeCountdown() {
    if (!_countdownStarted) return;
    final remaining =
        toastDurationMillis - countdownStopwatch.elapsedMilliseconds;
    if (remaining <= 0) {
      toastification.dismiss(toastItem);
      return;
    }
    countdownStopwatch.start();
    _autoDismissTimer = Timer(
      Duration(milliseconds: remaining),
      () {
        if (mounted) toastification.dismiss(toastItem);
      },
    );
    _countdownTicker = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  void disposeCountdown() {
    _autoDismissTimer?.cancel();
    _countdownTicker?.cancel();
  }
}
