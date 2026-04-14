/// Diagnostic data from the most recent process detection check.
class ProcessDetectionDiagnostics {
  /// Names of detectors that were used during the last run.
  final List<String> detectorNames;

  /// Name of the detector that matched, or null if none matched.
  final String? matchedDetectorName;

  /// Whether the game was detected as running.
  final bool wasGameRunning;

  /// How long the entire detector chain took to run.
  final Duration checkDuration;

  /// When this check completed.
  final DateTime timestamp;

  /// Time between the last two consecutive runs.
  final Duration? runInterval;

  /// Errors encountered during detection.
  final List<Exception> errors;

  const ProcessDetectionDiagnostics({
    required this.detectorNames,
    required this.matchedDetectorName,
    required this.wasGameRunning,
    required this.checkDuration,
    required this.timestamp,
    required this.runInterval,
    required this.errors,
  });
}
