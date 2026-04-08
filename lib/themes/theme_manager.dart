import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/themes/semantic_colors.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';

import '../utils/logging.dart';

part 'theme_manager.mapper.dart';

@MappableClass(
  generateMethods:
      GenerateMethods.copy | GenerateMethods.equals | GenerateMethods.stringify,
)
class ThemeState with ThemeStateMappable {
  final ThemeData themeData;
  final Map<String, TriOSTheme> availableThemes;
  final TriOSTheme currentTheme;

  ThemeState(this.themeData, this.availableThemes, this.currentTheme);
}

class ThemeManager extends AsyncNotifier<ThemeState> {
  static const iconOpacity = 0.3;
  static const iconButtonOpacity = 0.8;

  late Map<String, TriOSTheme> allThemes;
  late TriOSTheme _currentTheme;

  @override
  Future<ThemeState> build() async {
    await _loadThemes();

    try {
      _currentTheme = allThemes.getOrElse(
        ref.watch(appSettings.select((s) => s.themeKey ?? "")),
        () => allThemes.values.first,
      );
    } catch (e, st) {
      Fimber.w(
        "Error loading theme from shared preferences.",
        ex: e,
        stacktrace: st,
      );
      _currentTheme = allThemes.values.first;
    }

    final themeData = convertToThemeData(_currentTheme);
    return ThemeState(themeData, allThemes, _currentTheme);
  }

  Future<void> _loadThemes() async {
    allThemes = {"StarsectorTriOSTheme": StarsectorTriOSTheme()};

    try {
      final themesJsonString = await rootBundle.loadString(
        "assets/themes.json",
      );
      final themesJson = await themesJsonString.parseJsonToMapAsync();
      final themesMap = themesJson["themes"] as Map<String, dynamic>;

      for (var themeEntry in themesMap.entries) {
        try {
          final themeData = themeEntry.value as Map<String, dynamic>;
          allThemes[themeEntry.key] = TriOSTheme.fromHexCodes(
            id: themeEntry.key,
            displayName: themeData["displayName"] as String? ?? themeEntry.key,
            isDark: themeData["isDark"] ?? true,
            primary: themeData["primary"],
            secondary: themeData["secondary"],
            surface: themeData["surface"],
            surfaceContainer: themeData["surfaceContainer"],
            error: themeData["error"],
            onPrimary: themeData["onPrimary"],
            onSecondary: themeData["onSecondary"],
            onSurface: themeData["onSurface"],
            onError: themeData["onError"],
            fontFamily: themeData["fontFamily"],
            rainbowAccent: themeData["rainbowAccent"] ?? false,
            successSeed: themeData["successSeed"],
            warningSeed: themeData["warningSeed"],
            infoSeed: themeData["infoSeed"],
            neutralSeed: themeData["neutralSeed"],
          );
        } catch (e, st) {
          Fimber.e(
            "Error loading theme: ${themeEntry.key}",
            ex: e,
            stacktrace: st,
          );
        }
      }

      Fimber.i("Loaded themes: ${allThemes.keys}");
    } catch (e, st) {
      Fimber.e("Error loading themes from assets.", ex: e, stacktrace: st);
    }
  }

  Future<void> switchThemes(TriOSTheme theme) async {
    _currentTheme = theme;
    state = AsyncData(ThemeState(convertToThemeData(theme), allThemes, theme));

    ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(themeKey: theme.id));

    Fimber.i("Changed theme: ${theme.id}.");
  }

  static ThemeData convertToThemeData(TriOSTheme theme) {
    return theme.isDark ? _getDarkTheme(theme) : _getLightTheme(theme);
  }

  static TriOSThemeExtension _buildExtension(
    TriOSTheme swatch,
    Brightness brightness,
  ) {
    final semantic = generateAllSemanticColors(
      brightness: brightness,
      successSeed: swatch.successSeed,
      warningSeed: swatch.warningSeed,
      infoSeed: swatch.infoSeed,
      neutralSeed: swatch.neutralSeed,
      strategy: semanticColorStrategy,
    );
    return TriOSThemeExtension(
      rainbowAccent: swatch.rainbowAccent,
      success: semantic.success.base,
      onSuccess: semantic.success.onBase,
      successContainer: semantic.success.container,
      onSuccessContainer: semantic.success.onContainer,
      warning: semantic.warning.base,
      onWarning: semantic.warning.onBase,
      warningContainer: semantic.warning.container,
      onWarningContainer: semantic.warning.onContainer,
      info: semantic.info.base,
      onInfo: semantic.info.onBase,
      infoContainer: semantic.info.container,
      onInfoContainer: semantic.info.onContainer,
      neutral: semantic.neutral.base,
      onNeutral: semantic.neutral.onBase,
      neutralContainer: semantic.neutral.container,
      onNeutralContainer: semantic.neutral.onContainer,
    );
  }

  static ThemeData _getDarkTheme(TriOSTheme swatch) {
    final seedColor = swatch.primary;

    var darkThemeBase = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    final customTheme = _customizeTheme(darkThemeBase, swatch);
    return customTheme.copyWith(
      colorScheme: customTheme.colorScheme.copyWith(
        surfaceContainerLowest: swatch.surfaceContainer?.darker(15),
        surfaceContainerLow: swatch.surfaceContainer?.darker(5),
        surfaceContainer: swatch.surfaceContainer?.lighter(5),
        surfaceContainerHigh: swatch.surfaceContainer?.lighter(10),
        surfaceContainerHighest: swatch.surface,
      ),
      iconTheme: customTheme.iconTheme.copyWith(
        color: customTheme.colorScheme.onSurfaceVariant,
      ),
      extensions: [_buildExtension(swatch, Brightness.dark)],
    );
  }

  static ThemeData _getLightTheme(TriOSTheme swatch) {
    final seedColor = swatch.primary;

    var lightThemeBase = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    var customTheme = _customizeTheme(lightThemeBase, swatch.copyWith());
    return customTheme.copyWith(
      colorScheme: customTheme.colorScheme.copyWith(
        primary: swatch.primary,
        secondary: swatch.secondary,
        surfaceContainerLowest: swatch.surfaceContainer?.darker(15),
        surfaceContainerLow: swatch.surfaceContainer?.darker(5),
        surfaceContainer: swatch.surfaceContainer?.lighter(5),
        surfaceContainerHigh: swatch.surfaceContainer?.lighter(10),
        surfaceContainerHighest: swatch.surface,
      ),
      textTheme: customTheme.textTheme.copyWith(
        bodyMedium: customTheme.textTheme.bodyMedium?.copyWith(fontSize: 16),
      ),
      iconTheme: customTheme.iconTheme.copyWith(
        color: customTheme.colorScheme.onSurface.withOpacity(0.7),
      ),
      tabBarTheme: customTheme.tabBarTheme.copyWith(
        labelColor: customTheme.colorScheme.onSurface,
        unselectedLabelColor: customTheme.colorScheme.onSurfaceVariant,
      ),
      snackBarTheme: const SnackBarThemeData(),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: swatch.primary.mix(swatch.surfaceContainer!, 0.2)!,
          ),
        ),
      ),
      extensions: [_buildExtension(swatch, Brightness.light)],
    );
  }

  static ThemeData _customizeTheme(ThemeData themeBase, TriOSTheme swatch) {
    // Choose font here
    final textTheme = swatch.fontFamily != null
        ? themeBase.textTheme.apply(fontFamily: swatch.fontFamily)
        : GoogleFonts.robotoTextTheme(themeBase.textTheme);

    final onSurfaceVariant = swatch.surface == null
        ? swatch.onSurface
        : swatch.onSurface?.mix(swatch.surface!, 0.5)!;
    final primaryVariant = swatch.primary.mix(swatch.surfaceContainer!, 0.7)!;

    return themeBase.copyWith(
      colorScheme: themeBase.colorScheme.copyWith(
        primary: swatch.primary,
        secondary: swatch.secondary,
        onSurface: swatch.onSurface,
        onSurfaceVariant: onSurfaceVariant,
        onPrimary: swatch.onPrimary,
        onSecondary: swatch.onSecondary,
        surface: swatch.surface,
        error: TriOSThemeConstants.vanillaErrorColor,
        errorContainer: TriOSThemeConstants.vanillaErrorColor.darker(5),
        onErrorContainer: swatch.onSurface,
      ),
      scaffoldBackgroundColor: swatch.surfaceContainer,
      dialogBackgroundColor: swatch.surfaceContainer,
      cardColor: swatch.surfaceContainer,
      cardTheme: themeBase.cardTheme.copyWith(
        color: swatch.surfaceContainer,
        elevation: 4,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: themeBase.appBarTheme.copyWith(
        backgroundColor: swatch.surfaceContainer,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primaryVariant),
          iconColor: themeBase.colorScheme.onSurface.withValues(
            alpha: iconButtonOpacity,
          ),
          foregroundColor: themeBase.colorScheme.onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeBase.colorScheme.surfaceContainer,
        ),
      ),
      floatingActionButtonTheme: themeBase.floatingActionButtonTheme.copyWith(
        backgroundColor: swatch.primary,
        foregroundColor: themeBase.colorScheme.surface,
      ),
      checkboxTheme: themeBase.checkboxTheme.copyWith(
        checkColor: WidgetStateProperty.all(Colors.transparent),
      ),
      textTheme: textTheme.copyWith(
        bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 16),
      ),
      sliderTheme: themeBase.sliderTheme.copyWith(
        year2023: false,
        thumbSize: WidgetStateProperty.all(Size(4, 20)),
        tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 0),
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        year2023: false,
        stopIndicatorColor: Colors.transparent,
        trackGap: 0,
      ),
    );
  }

  // Expose methods or properties as needed
  Map<String, TriOSTheme> get availableThemes => allThemes;

  TriOSTheme get currentTheme => _currentTheme;
}

extension PaletteGeneratorExt on PaletteGenerator? {
  /// Extracts colors from a palette into a [TriOSTheme], which can then be
  /// passed to [ThemeManager.convertToThemeData] for full theme construction.
  ///
  /// Returns `null` if the palette is null or empty.
  ///
  /// Usage:
  /// ```dart
  /// final paletteTheme = palette.toTriOSTheme(context);
  /// if (paletteTheme != null) {
  ///   Theme(data: ThemeManager.convertToThemeData(paletteTheme), child: yourChild)
  /// }
  /// ```
  TriOSTheme? toTriOSTheme(BuildContext context) {
    final palette = this;
    if (palette == null || palette.colors.isEmpty) return null;

    final theme = Theme.of(context);

    final primary = palette.dominantColor?.color ?? theme.colorScheme.primary;
    final surface =
        palette.darkVibrantColor?.color ??
        palette.darkMutedColor?.color ??
        theme.colorScheme.surface;
    final onSurface =
        palette.lightVibrantColor?.color ??
        palette.lightMutedColor?.color ??
        theme.colorScheme.onSurface;
    final surfaceContainer =
        palette.darkMutedColor?.color ??
        palette.darkVibrantColor?.color ??
        theme.colorScheme.surfaceContainer;
    final secondary =
        palette.vibrantColor?.color ?? theme.colorScheme.secondary;

    return TriOSTheme(
      id: 'palette',
      displayName: 'Palette',
      isDark: true,
      primary: primary,
      secondary: secondary,
      surface: surface,
      surfaceContainer: surfaceContainer,
      onSurface: onSurface,
    );
  }
}

extension ColorSchemeExt on ThemeData {
  ThemeData lowContrastCardTheme() {
    return copyWith(
      cardTheme: cardTheme.copyWith(color: colorScheme.surface.lighter(8)),
    );
  }
}

// Utility function to create a MaterialColor from a given color
MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[.05];
  final Map<int, Color> swatch = {};
  final int r = color.intRed, g = color.intGreen, b = color.intBlue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (final strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

class StarsectorTriOSTheme extends TriOSTheme {
  StarsectorTriOSTheme()
    : super(
        id: 'StarsectorTriOSTheme',
        displayName: 'Starsector',
        isDark: true,
        primary: const Color.fromRGBO(73, 252, 255, 1),
        secondary: const Color.fromRGBO(59, 203, 232, 1),
        surface: const Color.fromRGBO(14, 22, 43, 1),
        surfaceContainer: const Color.fromRGBO(32, 41, 65, 1.0),
      );
}

/// For use with ColorFiltered
const ColorFilter greyscale = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);
