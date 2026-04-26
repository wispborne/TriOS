import 'dart:io';

import 'package:trios/vram_estimator/models/graphics_lib_info.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/folder_scan_selector.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector_config.dart';

/// A file enumerated from a mod folder. Shared across selectors so the file
/// listing happens once and is handed to every selector.
class VramModFile {
  final File file;
  final String relativePath;

  VramModFile({required this.file, required this.relativePath});
}

enum AssetProvenance { referenced, unreferenced }

/// A single image file selected for VRAM accounting, together with any
/// GraphicsLib tag and (optionally, when attribution tracking is enabled)
/// the parser ids that referenced it.
class SelectedAsset {
  final VramModFile file;
  final MapType? graphicsLibType;
  final AssetProvenance provenance;

  /// Parser ids that referenced this asset. Null when attribution tracking
  /// is off (the default) — never an empty list.
  final List<String>? referencedBy;

  const SelectedAsset({
    required this.file,
    required this.graphicsLibType,
    required this.provenance,
    this.referencedBy,
  });
}

/// Context passed to selectors, bundling everything they might need so the
/// interface itself stays narrow.
class VramSelectorContext {
  final void Function(String) verboseOut;
  final void Function(String) debugOut;
  final bool Function() isCancelled;
  final bool showPerformance;

  /// GraphicsLib CSV entries parsed from the mod (if any). Populated by
  /// `GraphicsLibReferences` and shared with downstream consumers so the
  /// CSV is parsed once per mod regardless of selector.
  final List<GraphicsLibInfo> graphicsLibEntries;

  const VramSelectorContext({
    required this.verboseOut,
    required this.debugOut,
    required this.isCancelled,
    required this.showPerformance,
    required this.graphicsLibEntries,
  });
}

/// Decides which image files a mod contributes to its VRAM estimate.
///
/// Selectors are the one pluggable seam in the VRAM checker pipeline. The
/// rest of the pipeline — header reading, POT math, background dedupe,
/// GraphicsLib display-time filtering — is shared across all selectors.
abstract class VramAssetSelector {
  /// Stable key used for persistence and profiling logs.
  String get id;

  /// Human-readable label for the selector dropdown.
  String get displayName;

  /// One-line explanation of what this selector does. Shown in the
  /// explanation dialog and as a dropdown tooltip.
  String get description;

  /// Return the assets this selector wants to count, tagged with provenance.
  ///
  /// `allFiles` is a pre-enumerated list of every file in the mod folder so
  /// multiple selectors can share the listing cost.
  Future<List<SelectedAsset>> select(
    VramCheckerMod mod,
    List<VramModFile> allFiles,
    VramSelectorContext ctx,
  );

  /// Reconstruct a selector from a serializable id + config pair. Used by
  /// the multithreaded scan path to rebuild selectors inside worker
  /// isolates from primitives that survive an isolate boundary. The
  /// config object must be a `Map<String, dynamic>` (a dart_mappable
  /// `.toMap()` payload) or a `ReferencedAssetsSelectorConfig` instance.
  /// Unknown ids fall back to [FolderScanSelector] (matching the
  /// `Settings.vramEstimatorSelectorId` "unknown ids fall back to
  /// folder-scan" rule).
  static VramAssetSelector fromId(String id, Object? config) {
    switch (id) {
      case 'referenced':
        final ReferencedAssetsSelectorConfig resolved;
        if (config is ReferencedAssetsSelectorConfig) {
          resolved = config;
        } else if (config is Map<String, dynamic>) {
          resolved = ReferencedAssetsSelectorConfigMapper.fromMap(config);
        } else {
          resolved = ReferencedAssetsSelectorConfig.allEnabled;
        }
        return ReferencedAssetsSelector(config: resolved);
      case 'folder-scan':
      default:
        return FolderScanSelector();
    }
  }
}
