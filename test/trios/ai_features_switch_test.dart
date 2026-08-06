import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/models/ai_summary_mode.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';

/// Stands in for the real settings notifier so nothing touches the settings
/// file on disk.
class _FakeSettings extends AppSettingNotifier {
  _FakeSettings(this.initial);

  final Settings initial;

  @override
  Settings build() => initial;
}

AiSummaryMode _effectiveMode({
  required bool aiEnabled,
  required AiSummaryMode savedMode,
}) {
  final container = ProviderContainer(
    overrides: [
      appSettings.overrideWith(
        () => _FakeSettings(
          Settings(
            enableAiFeatures: aiEnabled,
            catalogAiSummaryMode: savedMode,
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container.read(effectiveCatalogAiSummaryModeProvider);
}

void main() {
  setUpAll(() {
    // The settings manager resolves its file on construction, so point it at a
    // throwaway folder rather than the user's real config.
    Constants.configDataFolderPath = Directory.systemTemp.createTempSync(
      'trios_ai_switch_test',
    );
  });

  group('the AI features switch', () {
    test('off means no AI summaries, whatever the catalog is set to', () {
      for (final saved in AiSummaryMode.values) {
        expect(
          _effectiveMode(aiEnabled: false, savedMode: saved),
          AiSummaryMode.never,
          reason: 'the master switch must win over $saved',
        );
      }
    });

    test('on means the catalog setting is used as-is', () {
      for (final saved in AiSummaryMode.values) {
        expect(_effectiveMode(aiEnabled: true, savedMode: saved), saved);
      }
    });

    test('turning the switch off and back on restores the saved level', () {
      final container = ProviderContainer(
        overrides: [
          appSettings.overrideWith(
            () => _FakeSettings(
              Settings(
                enableAiFeatures: true,
                catalogAiSummaryMode: AiSummaryMode.always,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(effectiveCatalogAiSummaryModeProvider),
        AiSummaryMode.always,
      );

      container.read(appSettings.notifier).state = container
          .read(appSettings)
          .copyWith(enableAiFeatures: false);
      expect(
        container.read(effectiveCatalogAiSummaryModeProvider),
        AiSummaryMode.never,
      );

      container.read(appSettings.notifier).state = container
          .read(appSettings)
          .copyWith(enableAiFeatures: true);
      expect(
        container.read(effectiveCatalogAiSummaryModeProvider),
        AiSummaryMode.always,
        reason: 'the saved level must survive being switched off',
      );
    });

    test('the switch is on by default', () {
      expect(Settings().enableAiFeatures, isTrue);
    });
  });
}
