import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/folder_scan_selector.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector_config.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';
import 'package:trios/vram_estimator/selectors/vram_selector_id.dart';

void main() {
  group('VramAssetSelector.fromId', () {
    test('folder-scan id returns FolderScanSelector', () {
      final s = VramAssetSelector.fromId(VramSelectorId.folderScan, null);
      expect(s, isA<FolderScanSelector>());
      expect(s.id, equals(VramSelectorId.folderScan));
    });

    test('referenced id with typed config returns ReferencedAssetsSelector', () {
      const cfg = ReferencedAssetsSelectorConfig.allEnabled;
      final s = VramAssetSelector.fromId(VramSelectorId.referenced, cfg);
      expect(s, isA<ReferencedAssetsSelector>());
      expect(s.id, equals(VramSelectorId.referenced));
      expect((s as ReferencedAssetsSelector).config, same(cfg));
    });

    test(
      'referenced id with map config rehydrates ReferencedAssetsSelector',
      () {
        final map = ReferencedAssetsSelectorConfig.allEnabled.toMap();
        final s = VramAssetSelector.fromId(VramSelectorId.referenced, map);
        expect(s, isA<ReferencedAssetsSelector>());
        final cfg = (s as ReferencedAssetsSelector).config;
        expect(
          cfg.enabledParserIds,
          equals(ReferencedAssetsSelectorConfig.allEnabled.enabledParserIds),
        );
        expect(
          cfg.suppressUnreferenced,
          equals(
            ReferencedAssetsSelectorConfig.allEnabled.suppressUnreferenced,
          ),
        );
      },
    );

    test('referenced id with null config falls back to allEnabled', () {
      final s = VramAssetSelector.fromId(VramSelectorId.referenced, null);
      expect(s, isA<ReferencedAssetsSelector>());
      expect(
        (s as ReferencedAssetsSelector).config.enabledParserIds,
        equals(ReferencedAssetsSelectorConfig.allEnabled.enabledParserIds),
      );
    });

    test('toMap/fromMap round-trips ReferencedAssetsSelectorConfig', () {
      const original = ReferencedAssetsSelectorConfig(
        enabledParserIds: {'ships', 'weapons', 'jar-strings'},
        suppressUnreferenced: true,
      );
      final map = original.toMap();
      final restored = ReferencedAssetsSelectorConfigMapper.fromMap(map);
      expect(restored.enabledParserIds, equals(original.enabledParserIds));
      expect(
        restored.suppressUnreferenced,
        equals(original.suppressUnreferenced),
      );
    });
  });

  group('VramSelectorId.fromWire', () {
    test('known wire values resolve to the matching enum value', () {
      expect(
        VramSelectorId.fromWire('folder-scan'),
        equals(VramSelectorId.folderScan),
      );
      expect(
        VramSelectorId.fromWire('referenced'),
        equals(VramSelectorId.referenced),
      );
    });

    test('unknown wire value falls back to folderScan', () {
      expect(
        VramSelectorId.fromWire('not-a-real-selector'),
        equals(VramSelectorId.folderScan),
      );
    });

    test('every enum value round-trips through wireValue/fromWire', () {
      for (final id in VramSelectorId.values) {
        expect(VramSelectorId.fromWire(id.wireValue), equals(id));
      }
    });
  });
}
