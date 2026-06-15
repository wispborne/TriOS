import 'package:dart_mappable/dart_mappable.dart';

part 'active_mod_scan.mapper.dart';

/// Live state for one mod that is currently being scanned. The notifier
/// keeps a map of these keyed by mod id so the progress panel can render
/// every parallel scan under the multithreaded path.
@MappableClass()
class ActiveModScan with ActiveModScanMappable {
  /// Display name (or fallback to mod id) — the same value the panel
  /// previously rendered as `currentlyScanningModName`.
  final String modName;

  /// Selected-asset progress counters for this mod. Both 0 between
  /// `onModStart` and the first `onFileProgress` for the mod.
  final int filesScanned;
  final int totalFiles;

  /// Mod-relative path of the asset whose completion most recently
  /// ticked [filesScanned]. Null at the start of a mod or when no file
  /// has ticked yet.
  final String? currentFilePath;

  const ActiveModScan({
    required this.modName,
    this.filesScanned = 0,
    this.totalFiles = 0,
    this.currentFilePath,
  });
}
