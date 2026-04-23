import 'package:trios/vram_estimator/selectors/folder_scan_selector.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector_config.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Registered selector ids. Keep in sync with the display dropdown order.
const List<String> registeredSelectorIds = <String>['folder-scan', 'referenced'];

/// Resolve a selector by id. Unknown ids fall back to folder-scan.
/// Requires the current `ReferencedAssetsSelectorConfig` (only consulted
/// when resolving the referenced selector).
VramAssetSelector resolveSelector(
  String id,
  ReferencedAssetsSelectorConfig referencedConfig,
) {
  switch (id) {
    case 'referenced':
      return ReferencedAssetsSelector(config: referencedConfig);
    case 'folder-scan':
    default:
      return FolderScanSelector();
  }
}

/// Display metadata for one selector, used by the toolbar dropdown.
class SelectorOption {
  final String id;
  final String displayName;
  final String description;
  const SelectorOption({
    required this.id,
    required this.displayName,
    required this.description,
  });
}

/// One dropdown option per registered selector id. Labels come from the
/// selector itself so the registry stays the single source of truth.
List<SelectorOption> allSelectorOptions() {
  return registeredSelectorIds.map((id) {
    final s = resolveSelector(
      id,
      ReferencedAssetsSelectorConfig.allEnabled,
    );
    return SelectorOption(
      id: s.id,
      displayName: s.displayName,
      description: s.description,
    );
  }).toList();
}
