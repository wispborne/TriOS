import 'dart:io';

import 'package:trios/trios/constants.dart';
import 'package:trios/trios/deep_link/deep_link_parser.dart';
import 'package:trios/utils/logging.dart';

/// Outcome of [SingleInstanceManager.acquireLockOrForward].
enum LockAcquisition {
  /// No lock existed; this process created it and is the primary.
  freshStart,

  /// A lock existed but its owner was dead (crash) or unreadable; this process
  /// took it over. The previous session did not exit cleanly.
  tookOverStaleLock,

  /// A live instance already owns the lock and there was no deep link to
  /// forward; this (normal) launch proceeds as an additional instance.
  coexistingInstance,

  /// A live instance already owns the lock and a deep link was forwarded to it;
  /// the caller should `exit(0)`.
  forwardedAndShouldExit,
}

/// Single-instance + deep-link forwarding (Windows/Linux) built on `running.lock`.
///
/// The lock file contains the owning process PID, which lets a new launch tell a
/// genuinely-running instance from a stale lock left by a crash. Deep links that
/// arrive while a live instance is running are written into the
/// [pendingDeepLinkDir] (one file per link, never overwriting) for that instance
/// to pick up.
class SingleInstanceManager {
  static File get _lockFile =>
      File('${Constants.configDataFolderPath.path}/running.lock');

  /// Directory holding forwarded deep links awaiting pickup by the primary
  /// instance. One file per link so concurrent forwards never clobber each other.
  static Directory get pendingDeepLinkDir =>
      Directory('${Constants.configDataFolderPath.path}/pending_deeplinks');

  /// Acquires `running.lock` for this session, or forwards [deepLink] to a live
  /// owner. Subsumes crash detection (a stale lock ⇒ previous session crashed).
  ///
  /// Must be called AFTER [Constants.configDataFolderPath] is set.
  static LockAcquisition acquireLockOrForward({String? deepLink}) {
    final lockFile = _lockFile;
    try {
      // Atomic: succeeds only if no lock exists, so two simultaneous cold
      // launches can't both become primary.
      lockFile.createSync(exclusive: true);
      lockFile.writeAsStringSync(pid.toString());
      return LockAcquisition.freshStart;
    } on FileSystemException {
      // Lock exists: a live primary, a racing sibling, or a stale crash lock.
      final ownerPid = _readOwnerPidWithRetry(lockFile);
      final ownerAlive =
          ownerPid != null && ownerPid != pid && isProcessAlive(ownerPid);

      if (ownerAlive) {
        if (deepLink != null) {
          _writePendingDeepLink(deepLink);
          return LockAcquisition.forwardedAndShouldExit;
        }
        // Normal launch alongside a live instance — allowed (e.g. dev + release).
        return LockAcquisition.coexistingInstance;
      }

      // Stale / legacy / unreadable lock — take it over.
      try {
        lockFile.writeAsStringSync(pid.toString());
      } catch (e) {
        Fimber.w('Error taking over stale running.lock: $e');
      }
      return LockAcquisition.tookOverStaleLock;
    } catch (e) {
      Fimber.w('Error acquiring running.lock: $e');
      return LockAcquisition.freshStart;
    }
  }

  /// Whether this process owns `running.lock` (its PID is written there). Used to
  /// avoid a coexisting instance deleting the primary's lock on its own exit.
  static bool ownsLock() {
    try {
      final lockFile = _lockFile;
      if (!lockFile.existsSync()) return false;
      return int.tryParse(lockFile.readAsStringSync().trim()) == pid;
    } catch (_) {
      return false;
    }
  }

  /// Reads and deletes all pending forwarded deep-link files, returning their
  /// URIs. Safe to call repeatedly (watcher event + poll fallback).
  static List<String> drainPendingDeepLinks() {
    final dir = pendingDeepLinkDir;
    if (!dir.existsSync()) return [];
    final uris = <String>[];
    for (final entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('.deeplink')) {
        try {
          final uri = entity.readAsStringSync().trim();
          entity.deleteSync();
          if (uri.isNotEmpty) uris.add(uri);
        } catch (e) {
          Fimber.w('Error reading pending deep link ${entity.path}: $e');
        }
      }
    }
    return uris;
  }

  /// Reads the owning PID from [lockFile], retrying briefly to cover the window
  /// where a racing sibling has created the lock but not yet written its PID.
  static int? _readOwnerPidWithRetry(File lockFile) {
    for (var i = 0; i < 5; i++) {
      try {
        final parsed = int.tryParse(lockFile.readAsStringSync().trim());
        if (parsed != null) return parsed;
      } catch (_) {}
      sleep(const Duration(milliseconds: 10));
    }
    return null;
  }

  static void _writePendingDeepLink(String uri) {
    final dir = pendingDeepLinkDir;
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File(
      '${dir.path}/${pid}_${DateTime.now().microsecondsSinceEpoch}.deeplink',
    );
    file.writeAsStringSync(uri);
    Fimber.i('Forwarded deep link to running instance: $uri');
  }

  /// Read-only liveness check for [processId]. On any failure to determine,
  /// returns `false` (treat as not running) so a link is handled rather than
  /// silently swallowed.
  static bool isProcessAlive(int processId) {
    try {
      // Match the PID *and* our own executable name, so a PID recycled by an
      // unrelated process after a crash isn't mistaken for a live TriOS
      // instance (which would forward a deep link into a void).
      final exeName = _currentExecutableName();
      if (Platform.isWindows) {
        final result = Process.runSync('tasklist', [
          '/FI',
          'PID eq $processId',
          '/FI',
          'IMAGENAME eq $exeName',
          '/NH',
        ]);
        return result.stdout.toString().contains('$processId');
      } else {
        // `comm` is the process's command name; confirm the PID exists and its
        // command matches ours. Linux truncates `comm` (~15 chars), so compare
        // by prefix rather than equality.
        final result = Process.runSync('ps', [
          '-p',
          '$processId',
          '-o',
          'comm=',
        ]);
        if (result.exitCode != 0) return false;
        final commName = result.stdout.toString().trim().split('/').last;
        if (commName.isEmpty) return false;
        return exeName == commName || exeName.startsWith(commName);
      }
    } catch (_) {
      return false;
    }
  }

  /// Basename of the currently-running executable, used to confirm a PID belongs
  /// to a TriOS process rather than an unrelated one that recycled the PID.
  static String _currentExecutableName() =>
      Platform.resolvedExecutable.split(RegExp(r'[\\/]')).last;

  /// Extracts a `starsector-mod://` URI from command-line args, if present.
  static String? extractDeepLinkFromArgs(List<String> args) {
    for (final arg in args) {
      if (arg.startsWith('$deepLinkScheme://')) {
        return arg;
      }
    }
    return null;
  }
}
