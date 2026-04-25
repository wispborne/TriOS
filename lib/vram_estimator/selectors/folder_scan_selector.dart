import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/references/graphicslib_references.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Selector that preserves the original VRAM estimator behavior: every
/// image file in the mod folder counts, except those whose relative path
/// contains one of [unusedIndicators]. GraphicsLib map tagging is applied
/// to the selected files.
///
/// Every asset is emitted with [AssetProvenance.referenced] — this selector
/// has no concept of an unreferenced bucket.
class FolderScanSelector extends VramAssetSelector {
  /// Substrings in a file's relative path that mark it as intentionally
  /// unused by the mod author. Matches the prior [VramChecker.UNUSED_INDICATOR].
  static const List<String> unusedIndicators = [
    "CURRENTLY_UNUSED",
    "DO_NOT_USE",
  ];

  @override
  String get id => 'folder-scan';

  @override
  String get displayName => 'Scan All';

  @override
  String get description =>
      'Counts every image in mod folders, even unused ones.';

  @override
  Future<List<SelectedAsset>> select(
    VramCheckerMod mod,
    List<VramModFile> allFiles,
    VramSelectorContext ctx,
  ) async {
    final result = <SelectedAsset>[];
    for (final file in allFiles) {
      if (ctx.isCancelled()) break;
      if (!_isImage(file)) continue;
      if (unusedIndicators.any((s) => file.relativePath.contains(s))) continue;

      final mapType = GraphicsLibReferences.mapTypeFor(
        mod,
        file,
        ctx.graphicsLibEntries,
      );
      result.add(
        SelectedAsset(
          file: file,
          graphicsLibType: mapType,
          provenance: AssetProvenance.referenced,
        ),
      );
    }
    return result;
  }

  static bool _isImage(VramModFile file) {
    final ext = file.file.path.toLowerCase();
    return ext.endsWith('.png') ||
        ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp');
  }
}
