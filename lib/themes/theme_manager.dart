import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/themes/theme.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../trios/app_state.dart';
import '../utils/logging.dart';

const Color vanillaErrorColor = Color.fromARGB(255, 252, 99, 0);
const Color vanillaWarningColor = Color.fromARGB(255, 253, 212, 24);

Color? getStateColorForDependencyText(ModDependencySatisfiedState dependencyState) {
  return switch (dependencyState) {
    Satisfied _ => null,
    Missing _ => vanillaErrorColor,
    Disabled _ =>
    vanillaWarningColor, // Disabled means it's present, so we can just enable it.
    VersionInvalid _ => vanillaErrorColor,
    VersionWarning _ => vanillaWarningColor,
  };
}

class ThemeManager with ChangeNotifier {
  static double cornerRadius = 8;

  static TriOSTheme _theme = StarsectorTriOSTheme();
  static bool _isMaterial3 = true;
  static const String _key = "currentThemeId";
  static const String _keyMaterial = "isMaterial";
  static final allThemes = {
    "StarsectorTriOSTheme": StarsectorTriOSTheme(),
    "HalloweenTriOSTheme": HalloweenTriOSTheme(),
    "XmasTriOSTheme": XmasTriOSTheme(),
  };

  static final boxShadow = BoxShadow(
    color: Colors.black.withOpacity(0.5),
    spreadRadius: 4,
    blurRadius: 7,
    offset:
    const Offset(0, 3), // changes position of shadow
  );

  // static final backgroundShader = FutureProvider<FragmentProgram>((ref) async {
  //   return FragmentProgram.fromAsset("assets/shaders/grain.frag");
  // });

  ThemeManager() {
    // Load themes, then load the current theme from shared prefs and switch to it.
    loadThemes().then((_) {
      if (sharedPrefs.containsKey(_key)) {
        try {
          _theme = allThemes[sharedPrefs.getString(_key)]!;
          notifyListeners();
        } catch (e, st) {
          Fimber.w("Error loading theme from shared prefs.",
              ex: e, stacktrace: st);
          _theme = allThemes.values.first;
        }
        _isMaterial3 = sharedPrefs.getBool(_keyMaterial) ?? false;
      } else {
        _theme = allThemes.values.first;
      }
    });
  }

  TriOSTheme currentTheme() {
    return _theme;
  }

  ThemeData currentThemeData() {
    return convertToThemeData(_theme);
  }

  ThemeMode currentThemeBrightness() {
    return _theme.isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool isMaterial3() {
    return _isMaterial3;
  }

  void switchThemes(BuildContext context, TriOSTheme theme) {
    _theme = theme;
    notifyListeners();
    final themeKey =
        allThemes.entries.firstWhereOrNull((it) => it.value == theme)!.key;
    Fimber.i("Changed theme: $themeKey.");
    sharedPrefs.setString(_key, themeKey);
  }

  void switchMaterial() {
    _isMaterial3 = !_isMaterial3;
    sharedPrefs.setBool(_keyMaterial, _isMaterial3);
    Fimber.i("Changed material. Material: $_isMaterial3");
    notifyListeners();
  }

  Future<void> loadThemes() async {
    final themesJsonString =
        await rootBundle.loadString("assets/SMOL_Themes.json");
    final themesJson = (jsonDecode(themesJsonString)
        as Map<String, dynamic>)["themes"] as Map<String, dynamic>;

    for (var theme in themesJson.entries) {
      try {
        allThemes[theme.key] = TriOSTheme.fromHexCodes(
          isDark: theme.value["isDark"] ?? true,
          primary: theme.value["primary"],
          primaryVariant: theme.value["primaryVariant"],
          secondary: theme.value["secondary"],
          secondaryVariant: theme.value["secondaryVariant"],
          background: theme.value["background"],
          surface: theme.value["surface"],
          error: theme.value["error"],
          onPrimary: theme.value["onPrimary"],
          onSecondary: theme.value["onSecondary"],
          onBackground: theme.value["onBackground"],
          onSurface: theme.value["onSurface"],
          onError: theme.value["onError"],
          hyperlink: theme.value["hyperlink"],
        );
      } catch (e, st) {
        Fimber.e("Error loading theme: ${theme.key}", ex: e, stacktrace: st);
      }
    }

    Fimber.i("Loaded themes: ${allThemes.keys}");
  }

  static ThemeData convertToThemeData(TriOSTheme theme) {
    return theme.isDark
        ? getDarkTheme(theme, _isMaterial3)
        : getLightTheme(theme, _isMaterial3);
  }

  static ThemeData getDarkTheme(TriOSTheme swatch, bool material3) {
    final seedColor = swatch.primary;

    var darkThemeBase = ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor, brightness: Brightness.dark),
        useMaterial3: material3);

    return customizeTheme(darkThemeBase, swatch).copyWith();
  }

  static ThemeData getLightTheme(TriOSTheme swatch, bool material3) {
    final seedColor = swatch.primary;

    var lightThemeBase = ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor, brightness: Brightness.light),
      useMaterial3: material3,
    );

    return customizeTheme(
      lightThemeBase,
      swatch.copyWith(
          background: lightThemeBase.colorScheme.onInverseSurface,
          onSurface: lightThemeBase
              .colorScheme.onInverseSurface), // originally `..card = `
    ).copyWith(
        colorScheme: lightThemeBase.colorScheme.copyWith(
          primary: swatch.primary,
          secondary: swatch.secondary,
          // tertiary: swatch.tertiary,
        ),
        textTheme: lightThemeBase.textTheme.copyWith(
            bodyMedium:
                lightThemeBase.textTheme.bodyMedium?.copyWith(fontSize: 16)),
        iconTheme: lightThemeBase.iconTheme.copyWith(
          color: lightThemeBase.colorScheme.onSurface,
        ),
        tabBarTheme: lightThemeBase.tabBarTheme.copyWith(
          labelColor: lightThemeBase.colorScheme.onSurface,
          unselectedLabelColor: lightThemeBase.colorScheme.onSurface,
        ),
        snackBarTheme: const SnackBarThemeData());
  }

  static ThemeData customizeTheme(ThemeData themeBase, TriOSTheme swatch) {
    // Choose font here
    final textTheme = GoogleFonts.ibmPlexSansTextTheme(themeBase.textTheme);

    return themeBase.copyWith(
      colorScheme: themeBase.colorScheme.copyWith(
        primary: swatch.primary,
        secondary: swatch.secondary,
        onSurface: swatch.onBackground,
        onSurfaceVariant: swatch.onSurface,
        onPrimary: swatch.onPrimary,
        surface: swatch.surface,
        surfaceContainerHighest: swatch.background,
        // tertiary: swatch.tertiary,
      ),
      scaffoldBackgroundColor: swatch.background,
      dialogBackgroundColor: swatch.background,
      cardColor: swatch.surface,
      // cardColor: swatch.card,
      cardTheme: themeBase.cardTheme.copyWith(
        color: swatch.surface,
        // color: swatch.card,
        elevation: 4,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: themeBase.appBarTheme.copyWith(
        backgroundColor: swatch.surface,
        // backgroundColor: swatch.card,
      ),
      floatingActionButtonTheme: themeBase.floatingActionButtonTheme.copyWith(
        backgroundColor: swatch.primary,
        foregroundColor: themeBase.colorScheme.surface,
      ),
      checkboxTheme: themeBase.checkboxTheme
          .copyWith(checkColor: WidgetStateProperty.all(Colors.transparent)),
      textTheme: textTheme.copyWith(
        bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 16),
      ),
    );
  }
}

extension GameCompatibilityExt on GameCompatibility {
  Color? getGameCompatibilityColor() {
    switch (this) {
      case GameCompatibility.incompatible:
        return vanillaErrorColor;
      case GameCompatibility.warning:
        return vanillaWarningColor;
      case _:
        return null;
    }
  }
}

extension ModDependencySatisfiedStateExt on ModDependencySatisfiedState {
  Color? getDependencySatisfiedColor() {
    return switch (this) {
      Satisfied _ => Colors.green,
      Disabled _ => vanillaWarningColor.withAlpha(200),
      VersionWarning _ => vanillaWarningColor.withAlpha(200),
      _ => vanillaErrorColor,
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
      SnackBarType.warn => vanillaWarningColor,
      SnackBarType.error => vanillaErrorColor,
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
          background: const Color.fromRGBO(14, 22, 43, 1),
          surface: const Color.fromRGBO(32, 41, 65, 1.0),
        );
}

class HalloweenTriOSTheme extends TriOSTheme {
  HalloweenTriOSTheme()
      : super(
          isDark: true,
          primary: HexColor("#FF0000"),
          secondary: HexColor("#FF4D00").lighter(10),
          // tertiary: HexColor("#FF4D00").lighter(20),
          background: HexColor("#272121"),
          surface: HexColor("#272121").lighter(3),
        );
}

class XmasTriOSTheme extends TriOSTheme {
  XmasTriOSTheme()
      : super(
          isDark: true,
          primary: HexColor("#f23942").darker(10),
          secondary: HexColor("#70BA7F").lighter(10),
          // tertiary:  HexColor("#b47c4b").lighter(30),
          background: const Color.fromRGBO(26, 46, 31, 1.0).darker(5),
          surface: HexColor("#171e13").lighter(8),
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
