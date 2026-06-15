import 'dart:io';

import 'package:trios/models/result.dart';
import 'package:trios/utils/logging.dart';

import 'process_detector.dart';

/// Detects Starsector using `ps aux` on macOS/Linux.
///
/// Checks process command lines for the executable name.
class UnixProcessDetector extends ProcessDetector {
  @override
  String get name => 'ps aux';

  @override
  Future<Result?> isStarsectorRunning(List<String> executableNames) async {
    try {
      final processResult = await Process.run('ps', ['aux']);
      final output = processResult.stdout.toString().toLowerCase();

      for (final identifier in executableNames) {
        // Check for e.g. `starsector.app` but not `starsector.app/`
        final lowerIdentifier = identifier.toLowerCase();
        if (output.contains(lowerIdentifier) &&
            !output.contains("$lowerIdentifier/")) {
          Fimber.v(
            () => "Checked if game is running using ps aux. Is game running? true",
          );
          return Result.unmitigatedSuccess();
        }
      }

      return Result.unmitigatedFailure(
        [Exception("Game not found using `ps aux` method.")],
      );
    } catch (e) {
      // Don't spam logs — this runs frequently.
      return null;
    }
  }
}
