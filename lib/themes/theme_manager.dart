import 'dart:convert';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../utils/logging.dart';

part 'theme_manager.mapper.dart';

Color? getStateColorForDependencyText(
    ModDependencySatisfiedState dependencyState) {
  return switch (dependencyState) {
    Satisfied _ => null,
    Missing _ => ThemeManager.vanillaErrorColor,
    Disabled _ => ThemeManager
        .vanillaWarningColor, // Disabled means it's present, so we can just enable it.
    VersionInvalid _ => ThemeManager.vanillaErrorColor,
    VersionWarning _ => ThemeManager.vanillaWarningColor,
  };
}

@MappableClass(
    generateMethods: GenerateMethods.copy |
        GenerateMethods.equals |
        GenerateMethods.stringify)
class ThemeState with ThemeStateMappable {
  final ThemeData themeData;
  final Map<String, TriOSTheme> availableThemes;
  final TriOSTheme currentTheme;

  ThemeState(this.themeData, this.availableThemes, this.currentTheme);
}

class ThemeManager extends AsyncNotifier<ThemeState> {
  static const double cornerRadius = 8;
  static const Color vanillaErrorColor = Color.fromARGB(255, 252, 99, 0);
  static const Color vanillaWarningColor = Color.fromARGB(255, 253, 212, 24);
  static const String orbitron = "Orbitron";
  static const iconOpacity = 0.3;
  static const iconButtonOpacity = 0.8;

  static const bool _isMaterial3 = true;
  static final boxShadow = BoxShadow(
    color: Colors.black.withOpacity(0.5),
    spreadRadius: 4,
    blurRadius: 7,
    offset: const Offset(0, 3), // changes position of shadow
  );

  late Map<String, TriOSTheme> allThemes;
  late TriOSTheme _currentTheme;

  @override
  Future<ThemeState> build() async {
    await _loadThemes();

    try {
      _currentTheme = allThemes.getOrElse(
          ref.watch(appSettings.select((s) => s.themeKey ?? "")),
          () => allThemes.values.first);
    } catch (e, st) {
      Fimber.w("Error loading theme from shared preferences.",
          ex: e, stacktrace: st);
      _currentTheme = allThemes.values.first;
    }

    final themeData = convertToThemeData(_currentTheme);
    return ThemeState(themeData, allThemes, _currentTheme);
  }

  Future<void> _loadThemes() async {
    allThemes = {
      "StarsectorTriOSTheme": StarsectorTriOSTheme(),
      "HalloweenTriOSTheme": HalloweenTriOSTheme(),
      "XmasTriOSTheme": XmasTriOSTheme(),
    };

    try {
      final themesJsonString =
          await rootBundle.loadString("assets/SMOL_Themes.json");
      final themesJson = jsonDecode(themesJsonString) as Map<String, dynamic>;
      final themesMap = themesJson["themes"] as Map<String, dynamic>;

      for (var themeEntry in themesMap.entries) {
        try {
          final themeData = themeEntry.value as Map<String, dynamic>;
          allThemes[themeEntry.key] = TriOSTheme.fromHexCodes(
            isDark: themeData["isDark"] ?? true,
            primary: themeData["primary"],
            primaryVariant: themeData["primaryVariant"],
            secondary: themeData["secondary"],
            secondaryVariant: themeData["secondaryVariant"],
            background: themeData["background"],
            surface: themeData["surface"],
            error: themeData["error"],
            onPrimary: themeData["onPrimary"],
            onSecondary: themeData["onSecondary"],
            onSurface: themeData["onSurface"],
            onError: themeData["onError"],
            hyperlink: themeData["hyperlink"],
          );
        } catch (e, st) {
          Fimber.e("Error loading theme: ${themeEntry.key}",
              ex: e, stacktrace: st);
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

    final themeKey =
        allThemes.entries.firstWhere((entry) => entry.value == theme).key;
    ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(themeKey: themeKey));

    Fimber.i("Changed theme: $themeKey.");
  }

  ThemeData convertToThemeData(TriOSTheme theme) {
    return theme.isDark
        ? _getDarkTheme(theme, _isMaterial3)
        : _getLightTheme(theme, _isMaterial3);
  }

  ThemeData _getDarkTheme(TriOSTheme swatch, bool material3) {
    final seedColor = swatch.primary;

    var darkThemeBase = ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor, brightness: Brightness.dark),
      useMaterial3: material3,
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
    );
  }

  ThemeData _getLightTheme(TriOSTheme swatch, bool material3) {
    final seedColor = swatch.primary;

    var lightThemeBase = ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor, brightness: Brightness.light),
      useMaterial3: material3,
    );

    var customTheme = _customizeTheme(
      lightThemeBase,
      swatch.copyWith(),
    );
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
        color:
            customTheme.colorScheme.onSurfaceVariant.withOpacity(iconOpacity),
      ),
      tabBarTheme: customTheme.tabBarTheme.copyWith(
        labelColor: customTheme.colorScheme.onSurface,
        unselectedLabelColor: customTheme.colorScheme.onSurfaceVariant,
      ),
      snackBarTheme: const SnackBarThemeData(),
    );
  }

  ThemeData _customizeTheme(ThemeData themeBase, TriOSTheme swatch) {
    // Choose font here
    final textTheme = GoogleFonts.robotoTextTheme(themeBase.textTheme);

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
        error: vanillaErrorColor,
        errorContainer: vanillaErrorColor.lighter(5),
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
          iconColor:
              themeBase.colorScheme.onSurface.withValues(alpha: iconButtonOpacity),
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
    );
  }

  // Expose methods or properties as needed
  Map<String, TriOSTheme> get availableThemes => allThemes;

  TriOSTheme get currentTheme => _currentTheme;

  bool get isMaterial3 => _isMaterial3;
}

extension PaletteGeneratorExt on PaletteGenerator? {
  /// Usage:
  /// ```dart
  /// Theme(
  ///   data: palette.createPaletteTheme(context),
  ///   child: yourChild,
  /// )
  /// ```
  ThemeData createPaletteTheme(BuildContext context) {
    PaletteGenerator? palette = this;

    if (palette == null || palette.colors.isEmpty) {
      return Theme.of(context);
    }

    Color primaryColor =
        palette.dominantColor?.color ?? Theme.of(context).colorScheme.primary;
    Color surfaceColor = palette.darkVibrantColor?.color ??
        palette.darkMutedColor?.color ??
        Theme.of(context).colorScheme.surface;
    Color onSurfaceColor = palette.lightVibrantColor?.color ??
        palette.lightMutedColor?.color ??
        Theme.of(context).colorScheme.onSurface;
    Color backgroundColor = palette.darkMutedColor?.color ??
        palette.darkVibrantColor?.color ??
        Theme.of(context).colorScheme.surface;
    // Color buttonBackgroundColor =
    //     palette.darkVibrantColor?.color ?? Colors.white;
    // Color buttonTextColor =
    //     palette.darkVibrantColor?.bodyTextColor ?? Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: primaryColor,
        onPrimary: palette.darkVibrantColor?.bodyTextColor ??
            palette.darkMutedColor?.bodyTextColor ??
            Colors.white,
        secondary: Colors.blue,
        onSecondary: palette.darkVibrantColor?.bodyTextColor ??
            palette.darkMutedColor?.bodyTextColor ??
            Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        background: backgroundColor,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: onSurfaceColor),
        displayMedium: TextStyle(color: onSurfaceColor),
        displaySmall: TextStyle(color: onSurfaceColor),
        headlineLarge: TextStyle(color: onSurfaceColor),
        headlineMedium: TextStyle(color: onSurfaceColor),
        headlineSmall: TextStyle(color: onSurfaceColor),
        titleLarge: TextStyle(color: onSurfaceColor),
        titleMedium: TextStyle(color: onSurfaceColor),
        titleSmall: TextStyle(color: onSurfaceColor),
        bodyLarge: TextStyle(color: onSurfaceColor),
        bodyMedium: TextStyle(color: onSurfaceColor),
        bodySmall: TextStyle(color: onSurfaceColor),
        labelLarge: TextStyle(color: onSurfaceColor),
        labelMedium: TextStyle(color: onSurfaceColor),
        labelSmall: TextStyle(color: onSurfaceColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: onSurfaceColor.lighter(20), // Button text color
          side: BorderSide(color: onSurfaceColor), // Button outline
        ),
      ),
      iconTheme: IconThemeData(
        color: onSurfaceColor.withOpacity(0.8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(
          color: onSurfaceColor,
        ),
        titleTextStyle: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: onSurfaceColor),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        shadowColor: Colors.black45,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(color: onSurfaceColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2.0),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onSurfaceColor,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
          color: onSurfaceColor, linearTrackColor: backgroundColor),
    );
  }
}

extension ColorSchemeExt on ThemeData {
  lowContrastCardTheme() {
    return copyWith(
      cardTheme: cardTheme.copyWith(
        color: colorScheme.surface.lighter(8),
      ),
    );
  }
}

// Utility function to create a MaterialColor from a given color
MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[.05];
  final Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });
  return MaterialColor(color.value, swatch);
}

extension GameCompatibilityExt on GameCompatibility {
  Color? getGameCompatibilityColor() {
    switch (this) {
      case GameCompatibility.incompatible:
        return ThemeManager.vanillaErrorColor;
      case GameCompatibility.warning:
        return ThemeManager.vanillaWarningColor;
      case _:
        return null;
    }
  }
}

extension ModDependencySatisfiedStateExt on ModDependencySatisfiedState {
  Color? getDependencySatisfiedColor() {
    return switch (this) {
      Satisfied _ => Colors.green,
      Disabled _ => ThemeManager.vanillaWarningColor.withAlpha(200),
      VersionWarning _ => ThemeManager.vanillaWarningColor.withAlpha(200),
      _ => ThemeManager.vanillaErrorColor,
    };
  }
}

enum SnackBarType {
  info,
  warn,
  error,
}

showSnackBar({
  required BuildContext context,
  required Widget content,
  bool? clearPreviousSnackBars = true,
  SnackBarType? type,
  Color? backgroundColor,
  double? elevation,
  EdgeInsetsGeometry? margin,
  EdgeInsetsGeometry? padding,
  double? width,
  ShapeBorder? shape,
  HitTestBehavior? hitTestBehavior,
  SnackBarBehavior? behavior,
  SnackBarAction? action,
  double? actionOverflowThreshold,
  bool? showCloseIcon,
  Color? closeIconColor,
  Duration duration = const Duration(milliseconds: 4000),
  Animation<double>? animation,
  void Function()? onVisible,
  DismissDirection? dismissDirection,
  Clip clipBehavior = Clip.hardEdge,
}) {
  if (clearPreviousSnackBars == true) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: type != null
        ? DefaultTextStyle.merge(
            child: content,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold))
        : content,
    backgroundColor: switch (type) {
      SnackBarType.info => Colors.blue,
      SnackBarType.warn => ThemeManager.vanillaWarningColor,
      SnackBarType.error => ThemeManager.vanillaErrorColor,
      null => Theme.of(context).snackBarTheme.backgroundColor
    },
    elevation: elevation,
    margin: margin,
    padding: padding,
    width: width,
    shape: shape,
    hitTestBehavior: hitTestBehavior,
    behavior: behavior,
    action: action,
    actionOverflowThreshold: actionOverflowThreshold,
    showCloseIcon: showCloseIcon,
    closeIconColor: closeIconColor,
    duration: duration,
    animation: animation,
    onVisible: onVisible,
    dismissDirection: dismissDirection,
    clipBehavior: clipBehavior,
  ));
}

// class Swatch {
//   Color primary;
//   Color secondary;
//   Color tertiary;
//   Color background;
//   Color card;
//
//   Swatch(this.primary, this.secondary, this.tertiary, this.background, this.card);
// }

class StarsectorTriOSTheme extends TriOSTheme {
  StarsectorTriOSTheme()
      : super(
          isDark: true,
          primary: const Color.fromRGBO(73, 252, 255, 1),
          secondary: const Color.fromRGBO(59, 203, 232, 1),
          // tertiary: const Color.fromRGBO(0, 255, 255, 1),
          surface: const Color.fromRGBO(14, 22, 43, 1),
          surfaceContainer: const Color.fromRGBO(32, 41, 65, 1.0),
        );
}

class HalloweenTriOSTheme extends TriOSTheme {
  HalloweenTriOSTheme()
      : super(
          isDark: true,
          primary: HexColor("#FF0000"),
          secondary: HexColor("#FF4D00").lighter(10),
          // tertiary: HexColor("#FF4D00").lighter(20),
          surface: HexColor("#272121"),
          surfaceContainer: HexColor("#272121").lighter(3),
        );
}

class XmasTriOSTheme extends TriOSTheme {
  XmasTriOSTheme()
      : super(
          isDark: true,
          primary: HexColor("#f23942").darker(10),
          secondary: HexColor("#70BA7F").lighter(10),
          // tertiary:  HexColor("#b47c4b").lighter(30),
          surface: const Color.fromRGBO(26, 46, 31, 1.0).darker(5),
          surfaceContainer: HexColor("#171e13").lighter(8),
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
