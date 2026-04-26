import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/folder_scan_selector.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector_config.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

void main() {
  group('VramAssetSelector.fromId', () {
    test('folder-scan id returns FolderScanSelector', () {
      final s = VramAssetSelector.fromId('folder-scan', null);
      expect(s, isA<FolderScanSelector>());
      expect(s.id, equals('folder-scan'));
    });

    test('referenced id with typed config returns ReferencedAssetsSelector', () {
      const cfg = ReferencedAssetsSelectorConfig.allEnabled;
      final s = VramAssetSelector.fromId('referenced', cfg);
      expect(s, isA<ReferencedAssetsSelector>());
      expect(s.id, equals('referenced'));
      expect((s as ReferencedAssetsSelector).config, same(cfg));
    });

    test(
      'referenced id with map config rehydrates ReferencedAssetsSelector',
      () {
        final map = ReferencedAssetsSelectorConfig.allEnabled.toMap();
        final s = VramAssetSelector.fromId('referenced', map);
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
      final s = VramAssetSelector.fromId('referenced', null);
      expect(s, isA<ReferencedAssetsSelector>());
      expect(
        (s as ReferencedAssetsSelector).config.enabledParserIds,
        equals(ReferencedAssetsSelectorConfig.allEnabled.enabledParserIds),
      );
    });

    test('unknown id falls back to FolderScanSelector', () {
      final s = VramAssetSelector.fromId('not-a-real-selector', null);
      expect(s, isA<FolderScanSelector>());
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
}
