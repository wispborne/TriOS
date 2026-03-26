import 'dart:io';

import 'package:trios/trios/constants.dart';
import 'package:trios/trios/deep_link/deep_link_parser.dart';

/// Handles single-instance detection for deep link forwarding.
///
/// Uses the existing `running.lock` file (created by main.dart for crash
/// detection) to detect if another instance of TriOS is already running.
///
/// If another instance is running and we have a deep link URI, writes it
/// to `pending_deeplink` file and returns `true` (caller should exit).
class SingleInstanceManager {
  /// Checks if this is a secondary instance launched with a deep link URI.
  ///
  /// If another instance is running (running.lock exists) and [args] contains
  /// a `starsector-mod://` URI, writes the URI to the pending_deeplink file
  /// and returns `true`. The caller should then `exit(0)`.
  ///
  /// Must be called AFTER [Constants.configDataFolderPath] is set but BEFORE
  /// the running.lock file is written for this session.
  static bool forwardDeepLinkIfSecondary(List<String> args) {
    final deepLinkUri = _extractDeepLinkFromArgs(args);
    if (deepLinkUri == null) return false;

    final lockFile = File(
      '${Constants.configDataFolderPath.path}/running.lock',
    );

    if (!lockFile.existsSync()) return false;

    // Another instance is running. Forward the URI via file.
    try {
      final pendingFile = File(
        '${Constants.configDataFolderPath.path}/pending_deeplink',
      );
      pendingFile.writeAsStringSync(deepLinkUri);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Extracts a `starsector-mod://` URI from command-line args, if present.
  static String? _extractDeepLinkFromArgs(List<String> args) {
    for (final arg in args) {
      if (arg.startsWith('$deepLinkScheme://')) {
        return arg;
      }
    }
    return null;
  }

  /// Extracts a deep link URI from args (public, for cold-start use in main).
  static String? extractDeepLinkFromArgs(List<String> args) =>
      _extractDeepLinkFromArgs(args);
}
