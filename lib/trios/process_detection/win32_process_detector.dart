import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:trios/models/result.dart';
import 'package:trios/utils/logging.dart';
import 'package:win32/win32.dart';

import 'process_detector.dart';

/// Detects Starsector by enumerating running processes via Win32 APIs.
///
/// Uses [EnumProcesses] to get all PIDs, then [OpenProcess] +
/// [QueryFullProcessImageName] to get each process's full exe path.
///
/// Two-tier logic:
/// 1. If a process's exe path starts with [gameJreDir] → conclusive true.
/// 2. If no `java.exe` processes exist → conclusive false.
/// 3. If `java.exe` exists but doesn't match → null (inconclusive).
///
/// Windows only. Zero subprocess spawning.
class Win32ProcessDetector extends ProcessDetector {
  final Directory gameJreDir;
  late final String _jreDirNormalized = _resolveJreDir();

  Win32ProcessDetector(this.gameJreDir);

  String _resolveJreDir() {
    final resolved = gameJreDir.existsSync()
        ? gameJreDir.resolveSymbolicLinksSync()
        : gameJreDir.path;
    return resolved.toLowerCase().replaceAll('/', '\\');
  }

  @override
  String get name => 'Win32';

  @override
  Future<Result?> isStarsectorRunning(List<String> executableNames) async {
    if (!Platform.isWindows) return null;

    try {
      return _enumerate();
    } catch (e, st) {
      Fimber.w('Win32 process detection failed', ex: e, stacktrace: st);
      return null;
    }
  }

  Result? _enumerate() {
    // Allocate buffer for up to 4096 PIDs.
    const maxPids = 4096;
    final pids = calloc<Uint32>(maxPids);
    final bytesReturned = calloc<Uint32>();

    try {
      final success = EnumProcesses(
        pids,
        maxPids * sizeOf<Uint32>(),
        bytesReturned,
      );
      if (success == 0) return null;

      final pidCount = bytesReturned.value ~/ sizeOf<Uint32>();
      var foundJavaExe = false;

      for (var i = 0; i < pidCount; i++) {
        final pid = pids[i];
        if (pid == 0) continue;

        final exePath = _getProcessExePath(pid);
        if (exePath == null) continue;

        final exePathLower = exePath.toLowerCase();
        final exeName = exePathLower.split('\\').last;

        if (exeName != 'java.exe' && exeName != 'starsector.exe') continue;

        foundJavaExe = true;

        // Check if this java.exe is under the game's JRE directory.
        if (exePathLower.startsWith(_jreDirNormalized)) {
          Fimber.v(
            () => 'Win32: Starsector detected via JRE path match (PID $pid)',
          );
          return Result.unmitigatedSuccess();
        }
      }

      if (!foundJavaExe) {
        Fimber.v(() => 'Win32: No java.exe processes found');
        return Result.unmitigatedFailure([]);
      }

      // java.exe found but no path match — inconclusive.
      Fimber.v(
        () =>
            'Win32: java.exe found but no JRE path match, deferring to next detector',
      );
      return null;
    } finally {
      calloc.free(pids);
      calloc.free(bytesReturned);
    }
  }

  /// Returns the full exe path for [pid], or null if the process can't be queried.
  String? _getProcessExePath(int pid) {
    final hProcess = OpenProcess(
      PROCESS_QUERY_LIMITED_INFORMATION,
      0, // bInheritHandle = false
      pid,
    );
    if (hProcess == 0) return null;

    final exeNameBuffer = wsalloc(MAX_PATH);
    final size = calloc<Uint32>()..value = MAX_PATH;

    try {
      final result = QueryFullProcessImageName(
        hProcess,
        0,
        exeNameBuffer,
        size,
      );
      if (result == 0) return null;
      return exeNameBuffer.toDartString();
    } finally {
      CloseHandle(hProcess);
      free(exeNameBuffer);
      calloc.free(size);
    }
  }
}
