import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

final minRamInVmparamsRegex = RegExp(
  r"(?<=xms).*?(?=\s)",
  caseSensitive: false,
);
final maxRamInVmparamsRegex = RegExp(
  r"(?<=xmx).*?(?=\s)",
  caseSensitive: false,
);
const mbPerGb = 1024;

/// Extensions to scan for when looking for vmparams-type files.
const _vmparamsExtensions = {'.txt', '.sh', '.bat', '.vmparams', ''};

/// Max directory depth to scan from the game root.
const _maxScanDepth = 2;

/// Parses the RAM amount (in MB) from a vmparams file's content.
String? getRamAmountFromVmparamsInMb(String vmparamsContent) {
  var ramMatch = maxRamInVmparamsRegex.stringMatch(vmparamsContent);
  if (ramMatch == null) return null;

  var amountWithLowercaseChar = ramMatch.toLowerCase();
  final replace = RegExp(r"[^\d]");
  final valueAsDouble = double.tryParse(
    amountWithLowercaseChar.replaceAll(replace, ""),
  );
  if (valueAsDouble == null) return null;

  return amountWithLowercaseChar.endsWith("g")
      ? (valueAsDouble * mbPerGb).toStringAsFixed(0)
      : valueAsDouble.toStringAsFixed(0);
}

/// Replaces Xms and Xmx values in vmparams content with the new RAM amount.
String replaceRamInVmparams(String vmparamsContent, double ramInMb) {
  final newRamStr = "${ramInMb.toStringAsFixed(0)}m";
  return vmparamsContent
      .replaceAll(maxRamInVmparamsRegex, newRamStr)
      .replaceAll(minRamInVmparamsRegex, newRamStr);
}

/// Scans the game directory (depth ≤ 2) for text files containing Xmx/Xms patterns.
Future<List<File>> scanForVmparamsFiles(Directory gameDir) async {
  final results = <File>[];

  try {
    await _scanDirectory(gameDir, gameDir, 0, results);
  } catch (e) {
    Fimber.w("Error scanning for vmparams files", ex: e);
  }

  return results;
}

Future<void> _scanDirectory(
  Directory root,
  Directory dir,
  int depth,
  List<File> results,
) async {
  if (depth > _maxScanDepth) return;
  if (!dir.existsSync()) return;

  try {
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        // Files with no extension (like 'vmparams') have ext == ''
        if (_vmparamsExtensions.contains(ext)) {
          try {
            final content = await entity.readAsString();
            if (maxRamInVmparamsRegex.hasMatch(content)) {
              results.add(entity);
            }
          } catch (_) {
            // Skip files that can't be read as text
          }
        }
      } else if (entity is Directory && depth < _maxScanDepth) {
        // Skip common directories that won't contain vmparams files
        final name = p.basename(entity.path);
        if (name == '.git' || name == 'mods' || name == 'saves') continue;
        await _scanDirectory(root, entity, depth + 1, results);
      }
    }
  } catch (e) {
    Fimber.w("Error scanning directory: ${dir.path}", ex: e);
  }
}

/// Returns the platform-default vmparams file relative path.
String get _platformDefaultVmparamsPath => switch (defaultTargetPlatform) {
  TargetPlatform.windows => "vmparams",
  TargetPlatform.linux => "starsector.sh",
  TargetPlatform.macOS => "Contents/MacOS/starsector_mac.sh",
  _ => "vmparams",
};

/// Provider for [VmparamsManagerState].
final vmparamsManagerProvider =
    AsyncNotifierProvider<VmparamsManager, VmparamsManagerState>(
      VmparamsManager.new,
    );

/// Provider for just the current RAM amount.
final currentRamAmountInMb = Provider<String?>((ref) {
  return ref.watch(vmparamsManagerProvider).value?.currentRamAmountInMb;
});

class VmparamsManagerState {
  final List<File> detectedVmparamsFiles;
  final List<File> selectedVmparamsFiles;
  final String? currentRamAmountInMb;
  final bool hasMultipleFilesWithDifferentRam;

  /// Map from file to its RAM amount (for display in UI).
  final Map<File, String?> fileRamAmounts;

  VmparamsManagerState({
    required this.detectedVmparamsFiles,
    required this.selectedVmparamsFiles,
    this.currentRamAmountInMb,
    this.hasMultipleFilesWithDifferentRam = false,
    this.fileRamAmounts = const {},
  });
}

class VmparamsManager extends AsyncNotifier<VmparamsManagerState> {
  @override
  Future<VmparamsManagerState> build() async {
    final gamePath = ref.watch(AppState.gameFolder).value;
    if (gamePath == null) {
      return VmparamsManagerState(
        detectedVmparamsFiles: [],
        selectedVmparamsFiles: [],
      );
    }

    final gameDir = gamePath.toDirectory();
    final detectedFiles = await scanForVmparamsFiles(gameDir);

    // Get persisted file paths from settings.
    final persistedPaths = ref.watch(
      appSettings.select((s) => s.vmparamsFilePaths),
    );

    List<File> selectedFiles;
    if (persistedPaths.isEmpty) {
      // Auto-detect: use platform default + any detected files.
      final defaultFile = gameDir.resolve(_platformDefaultVmparamsPath).toFile();
      if (defaultFile.existsSync()) {
        selectedFiles = [defaultFile];
        // Also include any other detected files (e.g. Miko files).
        for (final f in detectedFiles) {
          if (f.absolute.path != defaultFile.absolute.path) {
            selectedFiles.add(f);
          }
        }
      } else {
        selectedFiles = detectedFiles;
      }
    } else {
      // Resolve persisted relative paths.
      selectedFiles = persistedPaths
          .map((p) => gameDir.resolve(p).toFile())
          .where((f) => f.existsSync())
          .toList();
    }

    // Read RAM from all selected files.
    final fileRamAmounts = <File, String?>{};
    for (final file in [...detectedFiles, ...selectedFiles]) {
      if (!fileRamAmounts.containsKey(file)) {
        try {
          final content = file.readAsStringSync();
          fileRamAmounts[file] = getRamAmountFromVmparamsInMb(content);
        } catch (_) {
          fileRamAmounts[file] = null;
        }
      }
    }

    final selectedRamValues = selectedFiles
        .map((f) => fileRamAmounts[f])
        .nonNulls
        .toSet();

    return VmparamsManagerState(
      detectedVmparamsFiles: detectedFiles,
      selectedVmparamsFiles: selectedFiles,
      currentRamAmountInMb: selectedRamValues.firstOrNull,
      hasMultipleFilesWithDifferentRam: selectedRamValues.length > 1,
      fileRamAmounts: fileRamAmounts,
    );
  }

  /// Change the amount of RAM allocated to the game in all selected vmparams files.
  Future<void> changeRamAmount(double ramInMb) async {
    final selectedFiles = state.value?.selectedVmparamsFiles ?? [];

    for (final file in selectedFiles) {
      try {
        final content = file.readAsStringSync();
        final updated = replaceRamInVmparams(content, ramInMb);
        await file.writeAsString(updated);
      } catch (e) {
        Fimber.w("Error writing RAM to ${file.path}", ex: e);
      }
    }

    ref.invalidateSelf();
  }

  /// Persist the user's selected vmparams files to settings.
  Future<void> setSelectedFiles(List<String> relativePaths) async {
    await ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(vmparamsFilePaths: relativePaths));
    ref.invalidateSelf();
  }
}
