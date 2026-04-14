import 'package:trios/models/result.dart';

/// Strategy interface for detecting whether Starsector is running.
///
/// Returns [Result] if conclusive, `null` if inconclusive (try next detector).
abstract class ProcessDetector {
  String get name;

  Future<Result?> isStarsectorRunning(List<String> executableNames);
}
