import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/widgets/background_effects/background_effect.dart';
import 'package:trios/widgets/glitter_background.dart';

class _RadarSettings extends AppSettingNotifier {
  @override
  Settings build() => Settings(
    themeModifiers: const ThemeModifiers(
      enableGlitter: true,
      backgroundStyle: BackgroundStyle.radar,
    ),
  );
}

void main() {
  late Directory configDirectory;

  setUpAll(() {
    configDirectory = Directory.systemTemp.createTempSync(
      'trios_glitter_background_test',
    );
    Constants.configDataFolderPath = configDirectory;
  });

  tearDownAll(() => configDirectory.deleteSync(recursive: true));

  testWidgets('radar paint time advances while the app is active', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettings.overrideWith(_RadarSettings.new)],
        child: const MaterialApp(
          home: SizedBox.expand(
            child: GlitterBackground(child: SizedBox.expand()),
          ),
        ),
      ),
    );

    BackgroundPaintContext paintContext() {
      final customPaint = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .firstWhere((widget) => widget.painter != null);
      final painter = customPaint.painter! as dynamic;
      return painter.context as BackgroundPaintContext;
    }

    final firstTime = paintContext().elapsedSeconds;

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(paintContext().elapsedSeconds, greaterThan(firstTime));
  });
}
